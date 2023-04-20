// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LowLevelWETH} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelWETH.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {PackableReentrancyGuard} from "@looksrare/contracts-libs/contracts/PackableReentrancyGuard.sol";
import {Pausable} from "@looksrare/contracts-libs/contracts/Pausable.sol";

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
    LowLevelWETH,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    VRFConsumerBaseV2,
    OwnableTwoSteps,
    PackableReentrancyGuard,
    Pausable
{
    using Arrays for uint256[];

    address public immutable WETH;

    uint256 public constant ONE_DAY = 86_400 seconds;
    uint256 public constant ONE_WEEK = 604_800 seconds;

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
     * @notice It checks whether the currency is allowed.
     */
    mapping(address => bool) public isCurrencyAllowed;

    /**
     * @notice The maximum number of prizes per raffle.
     *         Each individual ERC-721 counts as one prize.
     *         Each ETH/ERC-20/ERC-1155 with winnersCount > 1 counts as one prize.
     */
    uint256 public constant MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE = 20;

    /**
     * @notice According to Chainlink, realistically the maximum number of random words is 125.
     */
    uint40 public constant MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE = 110;

    /**
     * @notice A Chainlink node should wait for 3 confirmations before responding.
     */
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

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
     * @notice The callback gas limit for fulfillRandomWords.
     */
    uint32 public callbackGasLimit = 500_000;

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
    uint16 public protocolFeeBp;

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
     * @param _weth The WETH address
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _owner The owner of the contract
     * @param _protocolFeeRecipient The recipient of the protocol fees
     * @param _protocolFeeBp The protocol fee in basis points
     */
    constructor(
        address _weth,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _owner,
        address _protocolFeeRecipient,
        uint16 _protocolFeeBp
    ) VRFConsumerBaseV2(_vrfCoordinator) OwnableTwoSteps(_owner) {
        _setProtocolFeeBp(_protocolFeeBp);
        _setProtocolFeeRecipient(_protocolFeeRecipient);

        WETH = _weth;
        KEY_HASH = _keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        SUBSCRIPTION_ID = _subscriptionId;
    }

    /**
     * @inheritdoc IRaffle
     */
    function createRaffle(CreateRaffleCalldata calldata params) external returns (uint256 raffleId) {
        if (params.maximumEntriesPerParticipant > params.maximumEntries) {
            revert InvalidMaximumEntriesPerParticipant();
        }

        if (params.minimumEntries > params.maximumEntries) {
            revert InvalidEntriesRange();
        }

        if (block.timestamp + ONE_DAY > params.cutoffTime || params.cutoffTime > block.timestamp + ONE_WEEK) {
            revert InvalidCutoffTime();
        }

        if (params.minimumProfitBp > ONE_HUNDRED_PERCENT_BP) {
            revert InvalidMinimumProfitBp();
        }

        if (params.protocolFeeBp != protocolFeeBp) {
            revert InvalidProtocolFeeBp();
        }

        if (!isCurrencyAllowed[params.feeTokenAddress]) {
            revert InvalidCurrency();
        }

        raffleId = ++rafflesCount;

        uint256 prizesCount = params.prizes.length;
        if (prizesCount == 0 || prizesCount > MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE) {
            revert InvalidPrizesCount();
        }

        uint40 cumulativeWinnersCount;
        uint8 currentPrizeTier;
        for (uint256 i; i < prizesCount; ) {
            Prize memory prize = params.prizes[i];
            if (prize.prizeTier < currentPrizeTier) {
                revert InvalidPrizeTier();
            }
            _validatePrize(prize);

            cumulativeWinnersCount += prize.winnersCount;
            prize.cumulativeWinnersCount = cumulativeWinnersCount;
            currentPrizeTier = prize.prizeTier;
            raffles[raffleId].prizes.push(prize);

            unchecked {
                ++i;
            }
        }

        if (
            cumulativeWinnersCount > params.minimumEntries ||
            cumulativeWinnersCount > MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE
        ) {
            revert InvalidWinnersCount();
        }

        _validateAndSetPricingOptions(raffleId, params.pricingOptions);

        raffles[raffleId].owner = msg.sender;
        raffles[raffleId].status = RaffleStatus.Created;
        raffles[raffleId].cutoffTime = params.cutoffTime;
        raffles[raffleId].minimumEntries = params.minimumEntries;
        raffles[raffleId].maximumEntries = params.maximumEntries;
        raffles[raffleId].maximumEntriesPerParticipant = params.maximumEntriesPerParticipant;
        raffles[raffleId].minimumProfitBp = params.minimumProfitBp;
        raffles[raffleId].protocolFeeBp = params.protocolFeeBp;
        raffles[raffleId].prizesTotalValue = params.prizesTotalValue;
        raffles[raffleId].feeTokenAddress = params.feeTokenAddress;

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Created);
    }

    /**
     * @inheritdoc IRaffle
     */
    function depositPrizes(uint256 raffleId) external payable nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.status != RaffleStatus.Created) {
            revert InvalidStatus();
        }

        if (msg.sender != raffle.owner) {
            revert NotRaffleOwner();
        }

        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint256 expectedEthValue;
        for (uint256 i; i < prizesCount; ) {
            Prize storage prize = prizes[i];
            TokenType prizeType = prize.prizeType;
            if (prizeType == TokenType.ERC721) {
                _executeERC721TransferFrom(prize.prizeAddress, msg.sender, address(this), prize.prizeId);
            } else if (prizeType == TokenType.ERC20) {
                _executeERC20TransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeAmount * prize.winnersCount
                );
            } else if (prizeType == TokenType.ETH) {
                expectedEthValue += (prize.prizeAmount * prize.winnersCount);
            } else {
                _executeERC1155SafeTransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeId,
                    prize.prizeAmount * prize.winnersCount
                );
            }
            unchecked {
                ++i;
            }
        }

        if (expectedEthValue > msg.value) {
            revert InsufficientNativeTokensSupplied();
        } else if (msg.value > expectedEthValue) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, msg.value - expectedEthValue, gasleft());
        }

        raffle.status = RaffleStatus.Open;
        emit RaffleStatusUpdated(raffleId, RaffleStatus.Open);
    }

    /**
     * @inheritdoc IRaffle
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable nonReentrant whenNotPaused {
        uint256 entriesCount = entries.length;
        uint256 expectedEthValue;
        for (uint256 i; i < entriesCount; ) {
            EntryCalldata calldata entry = entries[i];

            if (entry.pricingOptionIndex >= PRICING_OPTIONS_PER_RAFFLE) {
                revert InvalidIndex();
            }

            uint256 raffleId = entry.raffleId;
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status != RaffleStatus.Open) {
                revert InvalidStatus();
            }

            if (block.timestamp >= raffle.cutoffTime) {
                revert CutoffTimeReached();
            }

            PricingOption memory pricingOption = raffle.pricingOptions[entry.pricingOptionIndex];

            uint40 newParticipantEntriesCount = rafflesParticipantsStats[raffleId][msg.sender].entriesCount +
                pricingOption.entriesCount;
            if (newParticipantEntriesCount > raffle.maximumEntriesPerParticipant) {
                revert MaximumEntriesPerParticipantReached();
            }
            rafflesParticipantsStats[raffleId][msg.sender].entriesCount = newParticipantEntriesCount;

            uint256 price = pricingOption.price;

            if (raffle.feeTokenAddress == address(0)) {
                expectedEthValue += price;
            } else {
                _executeERC20TransferFrom(raffle.feeTokenAddress, msg.sender, address(this), price);
            }

            uint40 currentEntryIndex;
            uint256 raffleEntriesCount = raffle.entries.length;
            if (raffleEntriesCount == 0) {
                currentEntryIndex = pricingOption.entriesCount - 1;
            } else {
                currentEntryIndex =
                    raffle.entries[raffleEntriesCount - 1].currentEntryIndex +
                    pricingOption.entriesCount;
            }

            if (currentEntryIndex >= raffle.maximumEntries) {
                revert MaximumEntriesReached();
            }

            raffle.entries.push(Entry({currentEntryIndex: currentEntryIndex, participant: msg.sender}));
            raffle.claimableFees += price;

            rafflesParticipantsStats[raffleId][msg.sender].amountPaid += price;

            emit EntrySold(raffleId, msg.sender, pricingOption.entriesCount, price);

            if (currentEntryIndex >= raffle.minimumEntries - 1) {
                if (
                    raffle.claimableFees >
                    (raffle.prizesTotalValue * (ONE_HUNDRED_PERCENT_BP + raffle.minimumProfitBp)) /
                        ONE_HUNDRED_PERCENT_BP
                ) {
                    _drawWinners(raffleId, raffle);
                }
            }

            unchecked {
                ++i;
            }
        }

        if (expectedEthValue > msg.value) {
            revert InsufficientNativeTokensSupplied();
        } else if (msg.value > expectedEthValue) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, msg.value - expectedEthValue, gasleft());
        }
    }

    /**
     * @param _requestId The ID of the request
     * @param _randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (randomnessRequests[_requestId].exists) {
            uint256 raffleId = randomnessRequests[_requestId].raffleId;
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status == RaffleStatus.Drawing) {
                if (_randomWords.length == raffle.prizes[raffle.prizes.length - 1].cumulativeWinnersCount) {
                    raffle.status = RaffleStatus.RandomnessFulfilled;
                    randomnessRequests[_requestId].randomWords = _randomWords;
                    emit RaffleStatusUpdated(raffleId, RaffleStatus.RandomnessFulfilled);
                }
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function selectWinners(uint256 requestId) external {
        RandomnessRequest memory randomnessRequest = randomnessRequests[requestId];
        if (!randomnessRequest.exists) {
            revert RandomnessRequestDoesNotExist();
        }

        uint256 raffleId = randomnessRequest.raffleId;
        Raffle storage raffle = raffles[raffleId];
        if (raffle.status != RaffleStatus.RandomnessFulfilled) {
            revert InvalidStatus();
        }

        raffle.status = RaffleStatus.Drawn;

        uint256[] memory randomWords = randomnessRequest.randomWords;
        uint256 winnersCount = randomWords.length;

        Winner[] memory winners = new Winner[](winnersCount);

        uint256 entriesCount = raffle.entries.length;
        uint256 currentEntryIndex = uint256(raffle.entries[entriesCount - 1].currentEntryIndex);

        uint256[] memory winningEntriesBitmap = new uint256[]((currentEntryIndex >> 8) + 1);

        for (uint256 i; i < winnersCount; ) {
            uint256 randomWord = randomWords[i];
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

            Prize[] storage prizes = raffle.prizes;
            uint256 prizesCount = prizes.length;
            uint256[] memory cumulativeWinnersCountArray = new uint256[](prizesCount);
            for (uint256 j; j < prizesCount; ) {
                cumulativeWinnersCountArray[j] = prizes[j].cumulativeWinnersCount;
                unchecked {
                    ++j;
                }
            }
            uint8 prizeIndex = uint8(cumulativeWinnersCountArray.findUpperBound(i + 1));

            winners[i].participant = raffle.entries[winnerIndex].participant;
            winners[i].entryIndex = uint40(winningEntry);
            winners[i].prizeIndex = prizeIndex;

            raffle.winners.push(winners[i]);

            unchecked {
                ++i;
            }
        }

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Drawn);
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external nonReentrant whenNotPaused {
        uint256 claimsCount = claimPrizesCalldata.length;
        for (uint256 i; i < claimsCount; ) {
            _claimPrizesPerRaffle(claimPrizesCalldata[i]);
            unchecked {
                ++i;
            }
        }
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
    function getPricingOptions(uint256 raffleId)
        external
        view
        returns (PricingOption[PRICING_OPTIONS_PER_RAFFLE] memory pricingOptions)
    {
        pricingOptions = raffles[raffleId].pricingOptions;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getRandomWords(uint256 requestId) external view returns (uint256[] memory randomWords) {
        randomWords = randomnessRequests[requestId].randomWords;
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
    function claimFees(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.status != RaffleStatus.Drawn) {
            revert InvalidStatus();
        }

        uint256 claimableFees = raffle.claimableFees;
        uint256 protocolFees = (claimableFees * uint256(raffle.protocolFeeBp)) / ONE_HUNDRED_PERCENT_BP;
        claimableFees -= protocolFees;

        raffle.status = RaffleStatus.Complete;
        raffle.claimableFees = 0;

        address raffleOwner = raffle.owner;
        address feeTokenAddress = raffle.feeTokenAddress;
        _transferFungibleTokens(feeTokenAddress, raffleOwner, claimableFees);

        if (protocolFees != 0) {
            protocolFeeRecipientClaimableFees[feeTokenAddress] += protocolFees;
        }

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Complete);
        emit FeesClaimed(raffleId, raffleOwner, claimableFees);
    }

    /**
     * @inheritdoc IRaffle
     */
    function cancel(uint256 raffleId) external nonReentrant {
        Raffle storage raffle = raffles[raffleId];

        RaffleStatus status = raffle.status;
        bool isOpen = status == RaffleStatus.Open;

        if (isOpen) {
            if (raffle.cutoffTime > block.timestamp) {
                revert CutoffTimeNotReached();
            }
        } else if (status != RaffleStatus.Created) {
            revert InvalidStatus();
        }

        _cancel(raffleId, raffle, isOpen);
    }

    /**
     * @inheritdoc IRaffle
     */
    function cancelAfterRandomnessRequest(uint256 raffleId) external onlyOwner nonReentrant {
        Raffle storage raffle = raffles[raffleId];

        if (raffle.status != RaffleStatus.Drawing) {
            revert InvalidStatus();
        }

        if (block.timestamp < raffle.drawnAt + ONE_DAY) {
            revert DrawExpirationTimeNotReached();
        }

        _cancel(raffleId, raffle, true);
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimRefund(uint256[] calldata raffleIds) external nonReentrant whenNotPaused {
        uint256 count = raffleIds.length;

        for (uint256 i; i < count; ) {
            uint256 raffleId = raffleIds[i];
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status != RaffleStatus.Cancelled) {
                revert InvalidStatus();
            }

            ParticipantStats storage stats = rafflesParticipantsStats[raffleId][msg.sender];

            if (stats.refunded) {
                revert AlreadyRefunded();
            }

            stats.refunded = true;

            uint256 amountPaid = stats.amountPaid;
            _transferFungibleTokens(raffle.feeTokenAddress, msg.sender, amountPaid);

            emit EntryRefunded(raffleId, msg.sender, amountPaid);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        if (_callbackGasLimit > 2_500_000) {
            revert InvalidCallbackGasLimit();
        }
        callbackGasLimit = _callbackGasLimit;
        emit CallbackGasLimitUpdated(_callbackGasLimit);
    }

    /**
     * @inheritdoc IRaffle
     */
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        _setProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IRaffle
     */
    function setProtocolFeeBp(uint16 _protocolFeeBp) external onlyOwner {
        _setProtocolFeeBp(_protocolFeeBp);
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _setProtocolFeeRecipient(address _protocolFeeRecipient) private {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidProtocolFeeRecipient();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @param _protocolFeeBp The new protocol fee in basis points
     */
    function _setProtocolFeeBp(uint16 _protocolFeeBp) private {
        if (_protocolFeeBp > MAXIMUM_PROTOCOL_FEE_BP) {
            revert InvalidProtocolFeeBp();
        }
        protocolFeeBp = _protocolFeeBp;
        emit ProtocolFeeBpUpdated(_protocolFeeBp);
    }

    /**
     * @param raffleId The ID of the raffle.
     */
    function _validateAndSetPricingOptions(
        uint256 raffleId,
        PricingOption[PRICING_OPTIONS_PER_RAFFLE] calldata pricingOptions
    ) private {
        for (uint256 i; i < PRICING_OPTIONS_PER_RAFFLE; ) {
            PricingOption memory pricingOption = pricingOptions[i];

            if (i == 0) {
                if (pricingOption.entriesCount == 0) {
                    revert InvalidEntriesCount();
                }

                if (pricingOption.price == 0) {
                    revert InvalidPrice();
                }
            } else {
                PricingOption memory lastPricingOption = pricingOptions[i - 1];
                if (pricingOption.entriesCount <= lastPricingOption.entriesCount) {
                    revert InvalidEntriesCount();
                }

                if (pricingOption.price <= lastPricingOption.price) {
                    revert InvalidPrice();
                }
            }

            raffles[raffleId].pricingOptions[i] = pricingOption;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param prize The prize.
     */
    function _validatePrize(Prize memory prize) private view {
        if (prize.prizeType == TokenType.ERC721) {
            if (prize.prizeAmount != 1) {
                revert InvalidPrizeAmount();
            }

            if (prize.winnersCount != 1) {
                revert InvalidWinnersCount();
            }
        } else {
            // ETH or ERC-20
            if (uint8(prize.prizeType) > 1) {
                if (!isCurrencyAllowed[prize.prizeAddress]) {
                    revert InvalidCurrency();
                }
            }

            if (prize.prizeAmount == 0) {
                revert InvalidPrizeAmount();
            }

            if (prize.winnersCount == 0) {
                revert InvalidWinnersCount();
            }
        }
    }

    /**
     * @param currentEntryIndex The current entry index.
     * @param winningEntry The winning entry.
     * @param winningEntriesBitmap The bitmap of winning entries.
     */
    function _incrementWinningEntryUntilThereIsNotADuplicate(
        uint256 currentEntryIndex,
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
                    bucket += 1;
                }
            }

            mask = 1 << (winningEntry & 0xff);
        }

        winningEntriesBitmap[bucket] |= mask;

        return (winningEntry, winningEntriesBitmap);
    }

    /**
     * @param prize The prize to transfer.
     * @param recipient The recipient of the prize.
     * @param multiplier The multiplier to apply to the prize amount.
     */
    function _transferPrize(
        Prize storage prize,
        address recipient,
        uint256 multiplier
    ) private {
        TokenType prizeType = prize.prizeType;
        address prizeAddress = prize.prizeAddress;
        if (prizeType == TokenType.ERC721) {
            _executeERC721TransferFrom(prizeAddress, address(this), recipient, prize.prizeId);
        } else if (prizeType == TokenType.ERC1155) {
            _executeERC1155SafeTransferFrom(
                prizeAddress,
                address(this),
                recipient,
                prize.prizeId,
                prize.prizeAmount * multiplier
            );
        } else {
            _transferFungibleTokens(prizeAddress, recipient, prize.prizeAmount * multiplier);
        }
    }

    /**
     * @param currency The currency to transfer.
     * @param recipient The recipient of the currency.
     * @param amount The amount of currency to transfer.
     */
    function _transferFungibleTokens(
        address currency,
        address recipient,
        uint256 amount
    ) private {
        if (currency == address(0)) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, recipient, amount, gasleft());
        } else {
            _executeERC20DirectTransfer(currency, recipient, amount);
        }
    }

    /**
     * @param raffleId The ID of the raffle to cancel.
     * @param raffle The raffle to cancel.
     * @param shouldWithdrawPrizes Whether to withdraw the prizes to the raffle owner.
     */
    function _cancel(
        uint256 raffleId,
        Raffle storage raffle,
        bool shouldWithdrawPrizes
    ) private {
        raffle.status = RaffleStatus.Cancelled;

        if (shouldWithdrawPrizes) {
            uint256 prizesCount = raffle.prizes.length;
            for (uint256 i; i < prizesCount; ) {
                Prize storage prize = raffle.prizes[i];
                _transferPrize({prize: prize, recipient: raffle.owner, multiplier: uint256(prize.winnersCount)});

                unchecked {
                    ++i;
                }
            }
        }

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Cancelled);
    }

    /**
     * @param claimPrizesCalldata The calldata for claiming prizes.
     */
    function _claimPrizesPerRaffle(ClaimPrizesCalldata calldata claimPrizesCalldata) private {
        uint256 raffleId = claimPrizesCalldata.raffleId;
        Raffle storage raffle = raffles[raffleId];
        RaffleStatus status = raffle.status;
        if (status != RaffleStatus.Drawn) {
            if (status != RaffleStatus.Complete) {
                revert InvalidStatus();
            }
        }

        Winner[] storage winners = raffle.winners;
        uint256[] calldata winnerIndices = claimPrizesCalldata.winnerIndices;
        uint256 winnersCount = winners.length;
        uint256 claimsCount = winnerIndices.length;
        for (uint256 i; i < claimsCount; ) {
            uint256 winnerIndex = winnerIndices[i];

            if (winnerIndex >= winnersCount) {
                revert InvalidIndex();
            }

            Winner storage winner = winners[winnerIndex];
            if (winner.claimed) {
                revert PrizeAlreadyClaimed();
            }
            if (winner.participant != msg.sender) {
                revert NotWinner();
            }
            winner.claimed = true;

            Prize storage prize = raffle.prizes[winner.prizeIndex];
            _transferPrize({prize: prize, recipient: msg.sender, multiplier: 1});

            unchecked {
                ++i;
            }
        }

        emit PrizesClaimed(raffleId, winnerIndices);
    }

    /**
     * @param raffleId The ID of the raffle to draw winners for.
     * @param raffle The raffle to draw winners for.
     */
    function _drawWinners(uint256 raffleId, Raffle storage raffle) private {
        raffle.status = RaffleStatus.Drawing;
        raffle.drawnAt = uint40(block.timestamp);

        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint32 winnersCount = uint32(prizes[prizesCount - 1].cumulativeWinnersCount);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            winnersCount
        );

        // TODO: Test it
        if (randomnessRequests[requestId].exists) {
            revert RandomnessRequestAlreadyExists();
        }

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].raffleId = raffleId;

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Drawing);
        emit RandomnessRequested(raffleId, requestId);
    }

    /**
     * @inheritdoc IRaffle
     */
    function updateCurrencyStatus(address currency, bool isAllowed) external onlyOwner {
        isCurrencyAllowed[currency] = isAllowed;
        emit CurrencyStatusUpdated(currency, isAllowed);
    }

    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @inheritdoc IRaffle
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
