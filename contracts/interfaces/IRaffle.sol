// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRaffle {
    enum RaffleStatus {
        None,
        Created,
        Open,
        Drawing,
        RandomnessFulfilled,
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
        uint40 entriesCount;
        uint256 price;
    }

    /**
     * @param currentEntryIndex The cumulative number of entries in the raffle.
     * @param participant The address of the participant.
     */
    struct Entry {
        uint40 currentEntryIndex;
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
        uint40 entryIndex;
    }

    /**
     * @param winnersCount The number of winners.
     * @param cumulativeWinnersCount The cumulative number of winners in the raffle.
     * @param prizeType The type of the prize.
     * @param prizeTier The tier of the prize.
     * @param prizeAddress The address of the prize.
     * @param prizeId The id of the prize.
     * @param prizeAmount The amount of the prize.
     */
    struct Prize {
        uint40 winnersCount;
        uint40 cumulativeWinnersCount;
        TokenType prizeType;
        uint8 prizeTier;
        address prizeAddress;
        uint256 prizeId;
        uint256 prizeAmount;
    }

    /**
     * @param owner The address of the raffle owner.
     * @param status The status of the raffle.
     * @param cutoffTime The time after which the raffle cannot be entered.
     * @param drawnAt The time at which the raffle was drawn. It is still pending Chainlink to fulfill the randomness request.
     * @param minimumEntries The minimum number of entries required to draw the raffle.
     * @param maximumEntries The maximum number of entries allowed in the raffle.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param minimumProfitBp The minimum profit in basis points required to draw the raffle.
     * @param protocolFeeBp The protocol fee in basis points. It must be equal to the protocol fee basis points when the raffle was created.
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
        uint40 drawnAt;
        uint40 minimumEntries;
        uint40 maximumEntries;
        uint40 maximumEntriesPerParticipant;
        uint16 minimumProfitBp;
        uint16 protocolFeeBp;
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
        uint40 entriesCount;
        bool refunded;
    }

    /**
     * @param raffleId The id of the raffle.
     * @param pricingOptionIndex The index of the selected pricing option.
     */
    struct EntryCalldata {
        uint256 raffleId;
        uint256 pricingOptionIndex;
    }

    /**
     * @param cutoffTime The time at which the raffle will be closed.
     * @param minimumEntries The minimum number of entries required to draw the raffle.
     * @param maximumEntries The maximum number of entries allowed to enter the raffle.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param minimumProfitBp The minimum profit in basis points required to draw the raffle.
     * @param protocolFeeBp The protocol fee in basis points. It must be equal to the protocol fee basis points when the raffle was created.
     * @param prizesTotalValue The total value of the prizes.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param prizes The prizes to be distributed.
     * @param pricingOptions The pricing options for the raffle.
     */
    struct CreateRaffleCalldata {
        uint40 cutoffTime;
        uint40 minimumEntries;
        uint40 maximumEntries;
        uint40 maximumEntriesPerParticipant;
        uint16 minimumProfitBp;
        uint16 protocolFeeBp;
        uint256 prizesTotalValue;
        address feeTokenAddress;
        Prize[] prizes;
        PricingOption[5] pricingOptions;
    }

    struct ClaimPrizesCalldata {
        uint256 raffleId;
        uint256[] winnerIndices;
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

    event CallbackGasLimitUpdated(uint32 callbackGasLimit);
    event CurrencyStatusUpdated(address currency, bool isAllowed);
    event EntryRefunded(uint256 raffleId, address buyer, uint256 amount);
    event EntrySold(uint256 raffleId, address buyer, uint40 entriesCount, uint256 price);
    event FeesClaimed(uint256 raffleId, address recipient, uint256 amount);
    event PrizesClaimed(uint256 raffleId, uint256[] winnerIndex);
    event ProtocolFeeBpUpdated(uint16 protocolFeeBp);
    event ProtocolFeeRecipientUpdated(address protocolFeeRecipient);
    event RaffleStatusUpdated(uint256 raffleId, RaffleStatus status);
    event RandomnessRequested(uint256 raffleId, uint256 requestId);

    error AlreadyRefunded();
    error CutoffTimeNotReached();
    error CutoffTimeReached();
    error DrawExpirationTimeNotReached();
    error InsufficientNativeTokensSupplied();
    error InvalidCallbackGasLimit();
    error InvalidCurrency();
    error InvalidCutoffTime();
    error InvalidEntriesCount();
    error InvalidEntriesRange();
    error InvalidIndex();
    error InvalidMaximumEntriesPerParticipant();
    error InvalidMinimumProfitBp();
    error InvalidPrice();
    error InvalidPrizeAmount();
    error InvalidPrizesCount();
    error InvalidPrizeTier();
    error InvalidProtocolFeeBp();
    error InvalidProtocolFeeRecipient();
    error InvalidStatus();
    error InvalidWinnersCount();
    error MaximumEntriesReached();
    error MaximumEntriesPerParticipantReached();
    error MinimumEntriesReached();
    error NotRaffleOwner();
    error NotWinner();
    error PrizeAlreadyClaimed();
    error RandomnessRequestAlreadyExists();
    error RandomnessRequestDoesNotExist();

    /**
     * @notice Creates a new raffle.
     * @param params The parameters of the raffle.
     * @return raffleId The id of the newly created raffle.
     */
    function createRaffle(CreateRaffleCalldata calldata params) external returns (uint256 raffleId);

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
     * @notice Select the winners for a raffle based on the random words returned by Chainlink.
     * @param requestId The request id returned by Chainlink.
     */
    function selectWinners(uint256 requestId) external;

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
     * @notice Gets the random words returned by Chainlink for a randomness request.
     * @param requestId The request id returned by Chainlink.
     */
    function getRandomWords(uint256 requestId) external view returns (uint256[] memory);

    /**
     * @notice Claims the prizes for a winner. A winner can claim multiple prizes
     *         from multiple raffles in a single transaction.
     * @param claimPrizesCalldata The calldata for claiming prizes.
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external;

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
     * @notice Cancels a raffle after randomness request if the randomness request
     *         does not arrive after a certain amount of time.
     *         Only callable by contract owner.
     * @param raffleId The id of the raffle.
     */
    function cancelAfterRandomnessRequest(uint256 raffleId) external;

    /**
     * @notice Claims the refund for a cancelled raffle.
     * @param raffleIds The ids of the raffles.
     */
    function claimRefund(uint256[] calldata raffleIds) external;

    /**
     * @notice Claims the protocol fees collected for a raffle.
     * @param currency The currency of the fees to be claimed.
     */
    function claimProtocolFees(address currency) external;

    /**
     * @notice Sets the callback gas limit for Chainlink. Only callable by contract owner.
     * @param callbackGasLimit The callback gas limit.
     */
    function setCallbackGasLimit(uint32 callbackGasLimit) external;

    /**
     * @notice Sets the protocol fee in basis points. Only callable by contract owner.
     * @param protocolFeeBp The protocol fee in basis points.
     */
    function setProtocolFeeBp(uint16 protocolFeeBp) external;

    /**
     * @notice Sets the protocol fee recipient. Only callable by contract owner.
     * @param protocolFeeRecipient The protocol fee recipient.
     */
    function setProtocolFeeRecipient(address protocolFeeRecipient) external;

    /**
     * @notice This function allows the owner to update the status of a currency.
     * @param currency Currency address (address(0) for ETH)
     * @param isAllowed Whether the currency should be allowed for trading
     * @dev Only callable by owner.
     */
    function updateCurrencyStatus(address currency, bool isAllowed) external;

    /**
     * @notice Pauses the contract. Only callable by contract owner.
     */
    function pause() external;

    /**
     * @notice Unpauses the contract. Only callable by contract owner.
     */
    function unpause() external;
}
