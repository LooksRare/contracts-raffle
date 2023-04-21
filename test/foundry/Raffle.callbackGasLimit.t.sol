// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_CallbackGasLimit_Test is TestHelpers {
    event CallbackGasLimitUpdated(uint32 callbackGasLimit);

    function setUp() public {
        looksRareRaffle = _deployRaffle();
    }

    function test_setCallbackGasLimit() public asPrankedUser(owner) {
        uint32 newCallbackGasLimit = 2_500_000;
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit CallbackGasLimitUpdated(newCallbackGasLimit);
        looksRareRaffle.setCallbackGasLimit(newCallbackGasLimit);
        assertEq(looksRareRaffle.callbackGasLimit(), newCallbackGasLimit);
    }

    function test_setCallbackGasLimit_RevertIf_NotOwner() public {
        uint32 newCallbackGasLimit = 2_500_000;
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        looksRareRaffle.setCallbackGasLimit(newCallbackGasLimit);
    }

    function test_setCallbackGasLimit_RevertIf_InvalidCallbackGasLimit() public asPrankedUser(owner) {
        uint32 invalidGasLimit = 2_500_001;
        vm.expectRevert(IRaffle.InvalidCallbackGasLimit.selector);
        looksRareRaffle.setCallbackGasLimit(invalidGasLimit);
    }
}
