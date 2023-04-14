// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LowLevelETHTransfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelETHTransfer.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {Arrays} from "./libraries/Arrays.sol";

import "./interfaces/IRaffle.sol";

/**
 * @title Raffle
 * @notice This contract allows anyone to permissionlessly host raffles on LooksRare.
 * @author LooksRare protocol team (👀,💎)
 */
contract Raffle is
    IRaffle,
    LowLevelETHTransfer,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    VRFConsumerBaseV2,
    OwnableTwoSteps
{
    using Arrays for uint256[];

    /**
     * @notice The minimum lifespan of a raffle.
     */
    uint256 public constant MINIMUM_LIFESPAN = 86_400 seconds;

    /**
     * @notice 100% in basis points.
     */
    uint256 public constant ONE_HUNDRED_PERCENT_BP = 10_000;

    /**
     * @notice The number of raffles created.
     */
    uint256 public rafflesCount;

    /**
     * @notice The raffles created.
     * @dev The key is the raffle ID.
     */
    mapping(uint256 => Raffle) public raffles;

    /**
     * @notice The participants stats of the raffles.
     * @dev The key is the raffle ID and the nested key is the participant address.
     */
    mapping(uint256 => mapping(address => ParticipantStats)) public rafflesParticipantsStats;

    /**
     * @notice According to Chainlink, realistically the maximum number of random words is 125.
     */
    uint256 public constant MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE = 110;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 public immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 public immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface public immutable VRF_COORDINATOR;

    /**
     * @notice The randomness requests.
     * @dev The key is the request ID returned by Chainlink.
     */
    mapping(uint256 => RandomnessRequest) public randomnessRequests;

    /**
     * @notice The callback gas limit per random word returned by Chainlink.
     */
    uint32 public callbackGasLimitPerRandomWord = 20_000;

    /**
     * @notice The maximum protocol fee in basis points, which is 25%.
     */
    uint256 public constant MAXIMUM_PROTOCOL_FEE_BP = 2_500;

    /**
     * @notice The protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The protocol fee in basis points.
     */
    uint256 public protocolFeeBp;

    /**
     * @notice The claimable fees of the protocol fee recipient.
     * @dev The key is the currency address.
     */
    mapping(address => uint256) public protocolFeeRecipientClaimableFees;

    /**
     * @notice The number of pricing options per raffle.
     */
    uint256 public constant PRICING_OPTIONS_PER_RAFFLE = 5;

    /**
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _owner The owner of the contract
     * @param _protocolFeeRecipient The recipient of the protocol fees
     * @param _protocolFeeBp The protocol fee in basis points
     */
    constructor(
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _owner,
        address _protocolFeeRecipient,
        uint256 _protocolFeeBp
    ) VRFConsumerBaseV2(_vrfCoordinator) OwnableTwoSteps(_owner) {
        _setProtocolFeeBp(_protocolFeeBp);
        _setProtocolFeeRecipient(_protocolFeeRecipient);

        KEY_HASH = _keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        SUBSCRIPTION_ID = _subscriptionId;
    }

    /**
     * @inheritdoc IRaffle
     */
    function createRaffle(
        uint40 cutoffTime,
        uint64 minimumEntries,
        uint64 maximumEntries,
        uint64 maximumEntriesPerParticipant,
        uint256 prizeValue,
        uint16 minimumProfitBp,
        address feeTokenAddress,
        Prize[] memory prizes,
        Pricing[PRICING_OPTIONS_PER_RAFFLE] calldata pricings
    ) external returns (uint256 raffleId) {
        if (maximumEntriesPerParticipant > maximumEntries) {
            revert InvalidMaximumEntriesPerParticipant();
        }

        if (minimumEntries >= maximumEntries) {
            revert InvalidEntriesRange();
        }

        if (block.timestamp + MINIMUM_LIFESPAN > cutoffTime) {
            revert InvalidCutoffTime();
        }

        if (uint256(minimumProfitBp) > ONE_HUNDRED_PERCENT_BP) {
            revert InvalidMinimumProfitBp();
        }

        if (feeTokenAddress != address(0)) {
            if (feeTokenAddress.code.length == 0) {
                revert InvalidFeeToken();
            }
        }

        uint256 prizesCount = prizes.length;
        uint256 cumulativeWinnersCount;
        for (uint256 i; i < prizesCount; ) {
            Prize memory prize = prizes[i];
            _validatePrize(prize);

            cumulativeWinnersCount += prize.winnersCount;
            if (cumulativeWinnersCount > minimumEntries) {
                revert InvalidWinnersCount();
            }
            prize.cumulativeWinnersCount = cumulativeWinnersCount;

            unchecked {
                ++i;
            }
        }

        if (cumulativeWinnersCount > MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE) {
            revert InvalidWinnersCount();
        }

        _validatePricings(pricings);

        raffleId = rafflesCount;

        raffles[raffleId].owner = msg.sender;
        raffles[raffleId].status = RaffleStatus.Created;
        raffles[raffleId].cutoffTime = cutoffTime;
        raffles[raffleId].minimumEntries = minimumEntries;
        raffles[raffleId].maximumEntries = maximumEntries;
        raffles[raffleId].maximumEntriesPerParticipant = maximumEntriesPerParticipant;
        raffles[raffleId].prizeValue = prizeValue;
        raffles[raffleId].minimumProfitBp = minimumProfitBp;
        raffles[raffleId].feeTokenAddress = feeTokenAddress;
        for (uint256 i; i < prizesCount; ) {
            raffles[raffleId].prizes.push(prizes[i]);
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < PRICING_OPTIONS_PER_RAFFLE; ) {
            raffles[raffleId].pricings[i] = pricings[i];
            unchecked {
                ++i;
            }
        }

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Created);

        rafflesCount = raffleId + 1;
    }

    /**
     * @inheritdoc IRaffle
     */
    function depositPrizes(uint256 raffleId) external payable {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.status != RaffleStatus.Created) {
            revert InvalidStatus();
        }

        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint256 expectedEthValue;
        for (uint256 i; i < prizesCount; ) {
            Prize storage prize = prizes[i];
            TokenType prizeType = prize.prizeType;
            if (prizeType == TokenType.ERC721) {
                _executeERC721TransferFrom(prize.prizeAddress, msg.sender, address(this), prize.prizeId);
            } else if (prizeType == TokenType.ERC1155) {
                _executeERC1155SafeTransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeId,
                    prize.prizeAmount * prize.winnersCount
                );
            } else if (prizeType == TokenType.ETH) {
                expectedEthValue += (prize.prizeAmount * prize.winnersCount);
            } else if (prizeType == TokenType.ERC20) {
                _executeERC20TransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeAmount * prize.winnersCount
                );
            }
            unchecked {
                ++i;
            }
        }

        if (expectedEthValue > msg.value) {
            revert InsufficientNativeTokensSupplied();
        }

        raffle.status = RaffleStatus.Open;
        emit RaffleStatusUpdated(raffleId, RaffleStatus.Open);
    }

    /**
     * @inheritdoc IRaffle
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable {
        uint80 entriesCount = uint80(entries.length);
        uint256 expectedEthValue;
        for (uint256 i; i < entriesCount; ) {
            EntryCalldata calldata entry = entries[i];

            if (entry.pricingIndex >= PRICING_OPTIONS_PER_RAFFLE) {
                revert InvalidIndex();
            }

            Raffle storage raffle = raffles[entry.raffleId];
            RaffleStatus status = raffle.status;

            if (status != RaffleStatus.Open) {
                if (status != RaffleStatus.ReadyToBeDrawn) {
                    revert InvalidStatus();
                }
            }

            if (block.timestamp >= raffle.cutoffTime) {
                revert CutoffTimeReached();
            }

            Pricing memory pricing = raffle.pricings[entry.pricingIndex];

            uint80 newEntriesCount = rafflesParticipantsStats[entry.raffleId][msg.sender].entriesCount +
                pricing.entriesCount;
            if (newEntriesCount > raffle.maximumEntriesPerParticipant) {
                revert MaximumEntriesPerParticipantReached();
            }

            if (raffle.feeTokenAddress == address(0)) {
                expectedEthValue += pricing.price;
            } else {
                _executeERC20TransferFrom(raffle.feeTokenAddress, msg.sender, address(this), pricing.price);
            }

            uint80 currentEntryIndex;
            uint256 raffleEntriesCount = raffle.entries.length;
            if (raffleEntriesCount == 0) {
                currentEntryIndex = pricing.entriesCount - 1;
            } else {
                currentEntryIndex = raffle.entries[raffleEntriesCount - 1].currentEntryIndex + pricing.entriesCount;
            }

            if (currentEntryIndex >= raffle.maximumEntries) {
                revert MaximumEntriesReached();
            }

            raffle.entries.push(Entry({currentEntryIndex: currentEntryIndex, participant: msg.sender}));
            raffle.claimableFees += pricing.price;

            rafflesParticipantsStats[entry.raffleId][msg.sender].amountPaid += pricing.price;
            rafflesParticipantsStats[entry.raffleId][msg.sender].entriesCount = newEntriesCount;

            emit EntrySold(entry.raffleId, msg.sender, pricing.entriesCount, pricing.price);

            if (currentEntryIndex >= raffle.minimumEntries - 1) {
                if (
                    raffle.claimableFees >
                    (raffle.prizeValue * (ONE_HUNDRED_PERCENT_BP + uint256(raffle.minimumProfitBp))) /
                        ONE_HUNDRED_PERCENT_BP
                ) {
                    if (status == RaffleStatus.Open) {
                        raffle.status = RaffleStatus.ReadyToBeDrawn;
                        emit RaffleStatusUpdated(entry.raffleId, RaffleStatus.ReadyToBeDrawn);
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        // TODO: Should we refund if msg.value > expectedEthValue?
        if (expectedEthValue > msg.value) {
            revert InsufficientNativeTokensSupplied();
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function drawWinners(uint256 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.status != RaffleStatus.ReadyToBeDrawn) {
            revert InvalidStatus();
        }

        uint16 requestConfirmations = 3;
        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint32 winnersCount = uint32(prizes[prizesCount - 1].cumulativeWinnersCount);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            requestConfirmations,
            callbackGasLimitPerRandomWord * winnersCount,
            winnersCount
        );

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].raffleId = raffleId;

        raffle.status = RaffleStatus.Drawing;
        emit RaffleStatusUpdated(raffleId, RaffleStatus.Drawing);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (randomnessRequests[_requestId].exists) {
            uint256 winnersCount = _randomWords.length;
            uint256 raffleId = randomnessRequests[_requestId].raffleId;
            Raffle storage raffle = raffles[raffleId];

            randomnessRequests[_requestId].randomWords = _randomWords;
            Winner[] memory winners = new Winner[](winnersCount);

            uint80 entriesCount = uint80(raffle.entries.length);
            uint80 currentEntryIndex = raffle.entries[entriesCount - 1].currentEntryIndex;

            uint256[] memory winningEntriesBitmap = new uint256[]((currentEntryIndex >> 8) + 1);

            for (uint256 i; i < winnersCount; ) {
                uint256 randomWord = _randomWords[i];
                uint256 winningEntry = randomWord % (currentEntryIndex + 1);
                (winningEntry, winningEntriesBitmap) = _incrementWinningEntryUntilThereIsNotADuplicate(
                    currentEntryIndex,
                    winningEntry,
                    winningEntriesBitmap
                );

                uint256[] memory currentEntryIndexArray = new uint256[](entriesCount);
                for (uint256 j; j < entriesCount; ) {
                    currentEntryIndexArray[j] = raffle.entries[j].currentEntryIndex;
                    unchecked {
                        ++j;
                    }
                }
                uint256 winnerIndex = currentEntryIndexArray.findUpperBound(winningEntry);

                uint256 prizesCount = raffle.prizes.length;
                uint256[] memory cumulativeWinnersCountArray = new uint256[](prizesCount);
                for (uint256 j; j < prizesCount; ) {
                    cumulativeWinnersCountArray[j] = raffle.prizes[j].cumulativeWinnersCount;
                    unchecked {
                        ++j;
                    }
                }
                uint8 prizeIndex = uint8(cumulativeWinnersCountArray.findUpperBound(i + 1));

                winners[i].participant = raffle.entries[winnerIndex].participant;
                winners[i].entryIndex = uint80(winningEntry);
                winners[i].prizeIndex = prizeIndex;

                unchecked {
                    ++i;
                }
            }

            raffle.status = RaffleStatus.Drawn;
            for (uint256 i; i < winnersCount; ) {
                raffle.winners.push(winners[i]);
                unchecked {
                    ++i;
                }
            }

            emit RaffleStatusUpdated(raffleId, RaffleStatus.Drawn);
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimPrize(uint256 raffleId, uint256 winnerIndex) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.status != RaffleStatus.Drawn) {
            revert InvalidStatus();
        }

        Winner[] storage winners = raffle.winners;
        if (winnerIndex >= winners.length) {
            revert InvalidIndex();
        }

        Winner storage winner = winners[winnerIndex];
        if (winner.claimed) {
            revert PrizeAlreadyClaimed();
        }
        winner.claimed = true;

        address participant = winner.participant;

        Prize storage prize = raffle.prizes[winner.prizeIndex];
        _transferPrize({prize: prize, recipient: participant, multiplier: 1});

        emit PrizeClaimed(raffleId, participant, prize.prizeType, prize.prizeAddress, prize.prizeId, prize.prizeAmount);
    }

    /**
     * @inheritdoc IRaffle
     */
    function getWinners(uint256 raffleId) external view returns (Winner[] memory winners) {
        winners = raffles[raffleId].winners;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getPrizes(uint256 raffleId) external view returns (Prize[] memory prizes) {
        prizes = raffles[raffleId].prizes;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getEntries(uint256 raffleId) external view returns (Entry[] memory entries) {
        entries = raffles[raffleId].entries;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getPricings(uint256 raffleId) external view returns (Pricing[PRICING_OPTIONS_PER_RAFFLE] memory pricings) {
        pricings = raffles[raffleId].pricings;
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimProtocolFees(address currency) external onlyOwner {
        uint256 claimableFees = protocolFeeRecipientClaimableFees[currency];
        protocolFeeRecipientClaimableFees[currency] = 0;
        _transferFungibleTokens(currency, protocolFeeRecipient, claimableFees);
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimFees(uint256 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.status != RaffleStatus.Drawn) {
            revert InvalidStatus();
        }

        uint256 claimableFees = raffle.claimableFees;
        uint256 protocolFees = (claimableFees * protocolFeeBp) / ONE_HUNDRED_PERCENT_BP;
        claimableFees -= protocolFees;

        raffle.status = RaffleStatus.Complete;
        raffle.claimableFees = 0;

        _transferFungibleTokens(raffle.feeTokenAddress, raffle.owner, claimableFees);

        if (protocolFees != 0) {
            protocolFeeRecipientClaimableFees[raffle.feeTokenAddress] += protocolFees;
        }

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Complete);
        emit FeesClaimed(raffleId, raffle.owner, claimableFees);
    }

    /**
     * @inheritdoc IRaffle
     */
    function cancel(uint256 raffleId) external {
        Raffle storage raffle = raffles[raffleId];

        RaffleStatus status = raffle.status;

        if (status != RaffleStatus.Created) {
            if (status != RaffleStatus.Open) {
                revert InvalidStatus();
            }
        }

        if (status == RaffleStatus.Open) {
            if (raffle.cutoffTime > block.timestamp) {
                revert CutoffTimeNotReached();
            }
        }

        raffle.status = RaffleStatus.Cancelled;

        // Raffle status == Open means prizes have been deposited
        if (status == RaffleStatus.Open) {
            uint256 prizesCount = raffle.prizes.length;
            for (uint256 i; i < prizesCount; ) {
                Prize storage prize = raffle.prizes[i];
                _transferPrize({prize: prize, recipient: raffle.owner, multiplier: prize.winnersCount});

                unchecked {
                    ++i;
                }
            }
        }

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Cancelled);
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimRefund(uint256 raffleId) external {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.status != RaffleStatus.Cancelled) {
            revert InvalidStatus();
        }

        ParticipantStats storage stats = rafflesParticipantsStats[raffleId][msg.sender];

        if (stats.refunded) {
            revert AlreadyRefunded();
        }

        stats.refunded = true;

        if (raffle.feeTokenAddress == address(0)) {
            _transferETH(msg.sender, stats.amountPaid);
        } else {
            _executeERC20DirectTransfer(raffle.feeTokenAddress, msg.sender, stats.amountPaid);
        }

        emit EntryRefunded(raffleId, msg.sender, stats.amountPaid);
    }

    function setCallbackGasLimitPerRandomWord(uint32 _callbackGasLimitPerRandomWord) external onlyOwner {
        if (
            _callbackGasLimitPerRandomWord < 20_000 ||
            _callbackGasLimitPerRandomWord * MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE > 2_500_000
        ) {
            revert InvalidCallbackGasLimitPerRandomWord();
        }
        callbackGasLimitPerRandomWord = _callbackGasLimitPerRandomWord;
        emit CallbackGasLimitPerRandomWordUpdated(_callbackGasLimitPerRandomWord);
    }

    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        _setProtocolFeeRecipient(_protocolFeeRecipient);
    }

    function setProtocolFeeBp(uint256 _protocolFeeBp) external onlyOwner {
        _setProtocolFeeBp(_protocolFeeBp);
    }

    function _setProtocolFeeRecipient(address _protocolFeeRecipient) private {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidProtocolFeeRecipient();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    function _setProtocolFeeBp(uint256 _protocolFeeBp) private {
        if (_protocolFeeBp > MAXIMUM_PROTOCOL_FEE_BP) {
            revert InvalidProtocolFeeBp();
        }
        protocolFeeBp = _protocolFeeBp;
        emit ProtocolFeeBpUpdated(_protocolFeeBp);
    }

    function _validatePricings(Pricing[PRICING_OPTIONS_PER_RAFFLE] calldata pricings) private pure {
        for (uint256 i; i < PRICING_OPTIONS_PER_RAFFLE; ) {
            Pricing memory pricing = pricings[i];
            if (pricing.entriesCount == 0) {
                revert InvalidEntriesCount();
            }

            if (pricing.price == 0) {
                revert InvalidPrice();
            }

            if (i != 0) {
                Pricing memory lastPricing = pricings[i - 1];
                if (pricing.entriesCount <= lastPricing.entriesCount) {
                    revert InvalidEntriesCount();
                }

                if (pricing.price <= lastPricing.price) {
                    revert InvalidPrice();
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function _validatePrize(Prize memory prize) private pure {
        if (prize.prizeType == TokenType.ERC721) {
            if (prize.prizeAmount != 1) {
                revert InvalidPrizeAmount();
            }

            if (prize.winnersCount != 1) {
                revert InvalidWinnersCount();
            }
        } else {
            if (prize.prizeAmount == 0) {
                revert InvalidPrizeAmount();
            }

            if (prize.winnersCount == 0) {
                revert InvalidWinnersCount();
            }
        }
    }

    function _incrementWinningEntryUntilThereIsNotADuplicate(
        uint80 currentEntryIndex,
        uint256 winningEntry,
        uint256[] memory winningEntriesBitmap
    ) private pure returns (uint256, uint256[] memory) {
        uint256 bucket = winningEntry >> 8;
        uint256 mask = 1 << (winningEntry & 0xff);
        while (winningEntriesBitmap[bucket] & mask != 0) {
            if (winningEntry == currentEntryIndex) {
                bucket = 0;
                winningEntry = 0;
            } else {
                winningEntry += 1;

                if (winningEntry % 256 == 0) {
                    if (bucket < winningEntriesBitmap.length - 1) {
                        bucket += 1;
                    } else {
                        bucket = 0;
                        winningEntry = 0;
                    }
                }
            }

            mask = 1 << (winningEntry & 0xff);
        }

        winningEntriesBitmap[bucket] |= mask;

        return (winningEntry, winningEntriesBitmap);
    }

    function _transferPrize(
        Prize storage prize,
        address recipient,
        uint256 multiplier
    ) private {
        if (prize.prizeType == TokenType.ERC721) {
            _executeERC721TransferFrom(prize.prizeAddress, address(this), recipient, prize.prizeId);
        } else if (prize.prizeType == TokenType.ERC1155) {
            _executeERC1155SafeTransferFrom(
                prize.prizeAddress,
                address(this),
                recipient,
                prize.prizeId,
                prize.prizeAmount * multiplier
            );
        } else if (prize.prizeType == TokenType.ETH) {
            _transferETH(recipient, prize.prizeAmount * multiplier);
        } else if (prize.prizeType == TokenType.ERC20) {
            _executeERC20DirectTransfer(prize.prizeAddress, recipient, prize.prizeAmount * multiplier);
        }
    }

    function _transferFungibleTokens(
        address currency,
        address recipient,
        uint256 amount
    ) private {
        if (currency == address(0)) {
            _transferETH(recipient, amount);
        } else {
            _executeERC20DirectTransfer(currency, recipient, amount);
        }
    }
}
