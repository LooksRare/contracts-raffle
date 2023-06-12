// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IJackpot {
    event CurrenciesStatusUpdated(address[] currencies, bool isAllowed);
    event RoundDurationUpdated(uint256 roundDuration);

    /**
     * @notice This function allows the owner to update currency statuses (ETH, ERC-20 and NFTs).
     * @param currencies Currency addresses (address(0) for ETH)
     * @param isAllowed Whether the currencies should be allowed in the jackpots
     * @dev Only callable by owner.
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external;

    /**
     * @notice This function allows the owner to update the duration of each round.
     * @param _roundDuration The duration of each round.
     */
    function updateRoundDuration(uint256 _roundDuration) external;
}
