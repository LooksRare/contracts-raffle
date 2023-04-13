// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_CallbackGasLimitPerRandomWord_Test is TestHelpers {
    Raffle public looksRareRaffle;

    event CallbackGasLimitPerRandomWordUpdated(uint32 callbackGasLimitPerRandomWord);

    function setUp() public {
        looksRareRaffle = new Raffle(KEY_HASH, SUBSCRIPTION_ID, VRF_COORDINATOR, owner, PROTOCOL_FEE_RECIPIENT, 500);
    }

    function test_setCallbackGasLimitPerRandomWord() public asPrankedUser(owner) {
        uint32 newCallbackGasLimitPerRandomWord = 20_001;
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit CallbackGasLimitPerRandomWordUpdated(newCallbackGasLimitPerRandomWord);
        looksRareRaffle.setCallbackGasLimitPerRandomWord(newCallbackGasLimitPerRandomWord);
        assertEq(looksRareRaffle.callbackGasLimitPerRandomWord(), newCallbackGasLimitPerRandomWord);
    }

    function test_setCallbackGasLimitPerRandomWord_RevertIf_NotOwner() public {
        uint32 newCallbackGasLimitPerRandomWord = 20_001;
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        looksRareRaffle.setCallbackGasLimitPerRandomWord(newCallbackGasLimitPerRandomWord);
    }

    function test_setCallbackGasLimitPerRandomWord_RevertIf_InvalidCallbackGasLimitPerRandomWord()
        public
        asPrankedUser(owner)
    {
        uint32 belowLimit = 19_999;
        vm.expectRevert(IRaffle.InvalidCallbackGasLimitPerRandomWord.selector);
        looksRareRaffle.setCallbackGasLimitPerRandomWord(belowLimit);

        uint32 aboveLimit = 22_728;
        vm.expectRevert(IRaffle.InvalidCallbackGasLimitPerRandomWord.selector);
        looksRareRaffle.setCallbackGasLimitPerRandomWord(aboveLimit);
    }
}
