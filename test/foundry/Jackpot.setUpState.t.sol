// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Jackpot} from "../../contracts/Jackpot.sol";
import {IJackpot} from "../../contracts/interfaces/IJackpot.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract Jackpot_SetUpState_Test is TestHelpers {
    event CurrenciesStatusUpdated(address[] currencies, bool isAllowed);

    function setUp() public {
        _deployJackpot();
    }

    function test_updateCurrenciesStatus() public asPrankedUser(owner) {
        address[] memory currencies = new address[](1);
        currencies[0] = address(1);

        expectEmitCheckAll();
        emit CurrenciesStatusUpdated(currencies, true);

        jackpot.updateCurrenciesStatus(currencies, true);
        assertEq(jackpot.isCurrencyAllowed(address(1)), 1);
    }

    function test_updateCurrenciesStatus_RevertIf_NotOwner() public {
        address[] memory currencies = new address[](1);
        currencies[0] = address(1);

        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        jackpot.updateCurrenciesStatus(currencies, false);
    }
}
