// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRaffle {
    enum RaffleStatus {
        None,
        Created,
        Open,
        ReadyToBeDrawn,
        Drawing,
        Drawn,
        Complete,
        Cancelled
    }

    enum TokenType {
        ERC721,
        ERC1155,
        ETH,
        ERC20
    }

    /**
     * @param entriesCount The number of entries that can be purchased for the given price.
     * @param price The price of the entries.
     */
    struct PricingOption {
        uint256 entriesCount;
        uint256 price;
    }

    /**
     * @param currentEntryIndex The cumulative number of entries in the raffle.
     * @param participant The address of the participant.
     */
    struct Entry {
        uint256 currentEntryIndex;
        address participant;
    }

    /**
     * @param participant The address of the winner.
     * @param claimed Whether the winner has claimed the prize.
     * @param prizeIndex The index of the prize that was won.
     * @param entryIndex The index of the entry that won.
     */
    struct Winner {
        address participant;
        bool claimed;
        uint8 prizeIndex;
        uint256 entryIndex;
    }

    /**
     * @param prizeType The type of the prize.
     * @param prizeAddress The address of the prize.
     * @param prizeId The id of the prize.
     * @param prizeAmount The amount of the prize.
     * @param winnersCount The number of winners.
     * @param cumulativeWinnersCount The cumulative number of winners in the raffle.
     */
    struct Prize {
        TokenType prizeType;
        address prizeAddress;
        uint256 prizeId;
        uint256 prizeAmount;
        uint256 winnersCount;
        uint256 cumulativeWinnersCount;
    }

    /**
     * @param owner The address of the raffle owner.
     * @param status The status of the raffle.
     * @param cutoffTime The time after which the raffle cannot be entered.
     * @param minimumEntries The minimum number of entries required to draw the raffle.
     * @param maximumEntries The maximum number of entries allowed in the raffle.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param minimumProfitBp The minimum profit in basis points required to draw the raffle.
     * @param prizesTotalValue The total value of the prizes.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param claimableFees The amount of fees collected from selling entries.
     * @param pricingOptions The pricing options for the raffle.
     * @param prizes The prizes to be distributed.
     * @param entries The entries that have been sold.
     * @param winners The winners of the raffle.
     */
    struct Raffle {
        address owner;
        RaffleStatus status;
        uint40 cutoffTime;
        uint64 minimumEntries;
        uint64 maximumEntries;
        uint64 maximumEntriesPerParticipant;
        uint16 minimumProfitBp;
        uint256 prizesTotalValue;
        address feeTokenAddress;
        uint256 claimableFees;
        PricingOption[5] pricingOptions;
        Prize[] prizes;
        Entry[] entries;
        Winner[] winners;
    }

    /**
     * @param amountPaid The amount paid by the participant.
     * @param entriesCount The number of entries purchased by the participant.
     * @param refunded Whether the participant has been refunded.
     */
    struct ParticipantStats {
        uint256 amountPaid;
        uint256 entriesCount;
        bool refunded;
    }

    /**
     * @param raffleId The id of the raffle.
     * @param pricingIndex The index of the selected pricing option.
     */
    struct EntryCalldata {
        uint256 raffleId;
        uint256 pricingIndex;
    }

    /**
     * @param exists Whether the request exists.
     * @param raffleId The id of the raffle.
     * @param randomWords The random words returned by Chainlink VRF.
     *                    If randomWords.length == 0, then the request is still pending.
     */
    struct RandomnessRequest {
        bool exists;
        uint256 raffleId;
        uint256[] randomWords;
    }

    event CallbackGasLimitPerRandomWordUpdated(uint32 callbackGasLimit);
    event EntryRefunded(uint256 raffleId, address buyer, uint256 amount);
    event EntrySold(uint256 raffleId, address buyer, uint256 entriesCount, uint256 price);
    event FeesClaimed(uint256 raffleId, address recipient, uint256 amount);
    event PrizeClaimed(
        uint256 raffleId,
        address winner,
        TokenType prizeType,
        address prizeAddress,
        uint256 prizeId,
        uint256 prizeAmount
    );
    event ProtocolFeeBpUpdated(uint256 protocolFeeBp);
    event ProtocolFeeRecipientUpdated(address protocolFeeRecipient);
    event RaffleStatusUpdated(uint256 raffleId, RaffleStatus status);

    error AlreadyRefunded();
    error CutoffTimeNotReached();
    error CutoffTimeReached();
    error InsufficientNativeTokensSupplied();
    error InvalidCallbackGasLimitPerRandomWord();
    error InvalidCutoffTime();
    error InvalidEntriesCount();
    error InvalidEntriesRange();
    error InvalidFeeToken();
    error InvalidIndex();
    error InvalidMaximumEntriesPerParticipant();
    error InvalidMinimumProfitBp();
    error InvalidPrice();
    error InvalidPrizeAmount();
    error InvalidProtocolFeeBp();
    error InvalidProtocolFeeRecipient();
    error InvalidStatus();
    error InvalidWinnersCount();
    error MaximumEntriesReached();
    error MaximumEntriesPerParticipantReached();
    error MinimumEntriesReached();
    error NotRaffleOwner();
    error PrizeAlreadyClaimed();
    error ProtocolFeeBpTooHigh();

    /**
     * @notice Creates a new raffle.
     * @param cutoffTime The time at which the raffle will be closed.
     * @param minimumEntries The minimum number of entries required to draw the raffle.
     * @param maximumEntries The maximum number of entries allowed to enter the raffle.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param prizesTotalValue The total value of the prizes.
     * @param minimumProfitBp The minimum profit in basis points required to draw the raffle.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param prizes The prizes to be distributed.
     * @param pricingOptions The pricing options for the raffle.
     * @return raffleId The id of the newly created raffle.
     */
    function createRaffle(
        uint40 cutoffTime,
        uint64 minimumEntries,
        uint64 maximumEntries,
        uint64 maximumEntriesPerParticipant,
        uint256 prizesTotalValue,
        uint16 minimumProfitBp,
        address feeTokenAddress,
        Prize[] memory prizes,
        PricingOption[5] calldata pricingOptions
    ) external returns (uint256 raffleId);

    /**
     * @notice Deposits prizes for a raffle.
     * @param raffleId The id of the raffle.
     */
    function depositPrizes(uint256 raffleId) external payable;

    /**
     * @notice Enters a raffle or multiple raffles.
     * @param entries The entries to be made.
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable;

    /**
     * @notice Draws the winners for a raffle.
     * @param raffleId The id of the raffle.
     */
    function drawWinners(uint256 raffleId) external;

    /**
     * @notice Gets the winners for a raffle.
     * @param raffleId The id of the raffle.
     * @return winners The winners of the raffle.
     */
    function getWinners(uint256 raffleId) external view returns (Winner[] memory);

    /**
     * @notice Gets the pricing options for a raffle.
     * @param raffleId The id of the raffle.
     * @return pricingOptions The pricing options for the raffle.
     */
    function getPricingOptions(uint256 raffleId) external view returns (PricingOption[5] memory);

    /**
     * @notice Gets the prizes for a raffle.
     * @param raffleId The id of the raffle.
     * @return prizes The prizes to be distributed.
     */
    function getPrizes(uint256 raffleId) external view returns (Prize[] memory);

    /**
     * @notice Gets the entries for a raffle.
     * @param raffleId The id of the raffle.
     * @return entries The entries entered for the raffle.
     */
    function getEntries(uint256 raffleId) external view returns (Entry[] memory);

    /**
     * @notice Claims the prize for a winner.
     * @param raffleId The id of the raffle.
     * @param winnerIndex The index of the winner.
     */
    function claimPrize(uint256 raffleId, uint256 winnerIndex) external;

    /**
     * @notice Claims the fees collected for a raffle.
     * @param raffleId The id of the raffle.
     */
    function claimFees(uint256 raffleId) external;

    /**
     * @notice Cancels a raffle beyond cut-off time without meeting minimum entries.
     * @param raffleId The id of the raffle.
     */
    function cancel(uint256 raffleId) external;

    /**
     * @notice Claims the refund for a cancelled raffle.
     * @param raffleId The id of the raffle.
     */
    function claimRefund(uint256 raffleId) external;

    /**
     * @notice Claims the protocol fees collected for a raffle.
     * @param currency The currency of the fees to be claimed.
     */
    function claimProtocolFees(address currency) external;

    /**
     * @notice Sets the callback gas limit per random word.
     * @param callbackGasLimit The callback gas limit per random word.
     */
    function setCallbackGasLimitPerRandomWord(uint32 callbackGasLimit) external;

    /**
     * @notice Sets the protocol fee in basis points.
     * @param protocolFeeBp The protocol fee in basis points.
     */
    function setProtocolFeeBp(uint256 protocolFeeBp) external;

    /**
     * @notice Sets the protocol fee recipient.
     * @param protocolFeeRecipient The protocol fee recipient.
     */
    function setProtocolFeeRecipient(address protocolFeeRecipient) external;
}
