// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Pausable} from "@looksrare/contracts-libs/contracts/Pausable.sol";
import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_SetUpState_Test is TestHelpers {
    Raffle public looksRareRaffle;

    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        looksRareRaffle = _deployRaffle();
    }

    function test_pause() public asPrankedUser(owner) {
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit Paused(owner);
        looksRareRaffle.togglePaused();
        assertTrue(looksRareRaffle.paused());
    }

    function test_pause_RevertIf_NotOwner() public {
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        looksRareRaffle.togglePaused();
    }

    function test_unpause() public asPrankedUser(owner) {
        looksRareRaffle.togglePaused();
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit Unpaused(owner);
        looksRareRaffle.togglePaused();
        assertFalse(looksRareRaffle.paused());
    }

    function test_unpause_RevertIf_NotOwner() public {
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        looksRareRaffle.togglePaused();
    }
}