// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Jackpot} from "../../contracts/Jackpot.sol";
import {IJackpot} from "../../contracts/interfaces/IJackpot.sol";
import {TestHelpers} from "./TestHelpers.sol";

contract Jackpot_SetUpState_Test is TestHelpers {
    event CurrenciesStatusUpdated(address[] currencies, bool isAllowed);
    event RoundDurationUpdated(uint256 roundDuration);

    function setUp() public {
        _deployJackpot();
    }

    function test_setUpState() public {
        assertEq(jackpot.roundDuration(), 10 minutes);
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

    function test_updateRoundDuration() public asPrankedUser(owner) {
        expectEmitCheckAll();
        emit RoundDurationUpdated(1);

        jackpot.updateRoundDuration(1);
        assertEq(jackpot.roundDuration(), 1);
    }

    function test_updateRoundDuration_RevertIf_NotOwner() public {
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        jackpot.updateRoundDuration(1);
    }
}
