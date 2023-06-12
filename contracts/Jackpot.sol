// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";

import {IJackpot} from "./interfaces/IJackpot.sol";

/**
 * @title Jackpot
 * @notice This contract allows anyone to permissionlessly host jackpots on LooksRare.
 * @author LooksRare protocol team (👀,💎)
 */
contract Jackpot is IJackpot, OwnableTwoSteps {
    /**
     * @notice It checks whether the currency is allowed.
     * @dev 0 is not allowed, 1 is allowed.
     */
    mapping(address => uint256) public isCurrencyAllowed;

    /**
     *
     * @param _owner The owner of the contract.
     */
    constructor(address _owner) OwnableTwoSteps(_owner) {}

    /**
     * @inheritdoc IJackpot
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external onlyOwner {
        uint256 count = currencies.length;
        for (uint256 i; i < count; ) {
            isCurrencyAllowed[currencies[i]] = (isAllowed ? 1 : 0);
            unchecked {
                ++i;
            }
        }
        emit CurrenciesStatusUpdated(currencies, isAllowed);
    }
}
