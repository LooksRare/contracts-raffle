// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_ProtocolFees_Test is TestHelpers {
    Raffle public looksRareRaffle;

    function setUp() public {
        looksRareRaffle = new Raffle(KEY_HASH, SUBSCRIPTION_ID, VRF_COORDINATOR, owner, PROTOCOL_FEE_RECIPIENT, 500);
    }

    function test_setProtocolFeeRecipient() public asPrankedUser(owner) {
        address newRecipient = address(0x1);
        looksRareRaffle.setProtocolFeeRecipient(newRecipient);
        assertEq(looksRareRaffle.protocolFeeRecipient(), newRecipient);
    }

    function test_setProtocolFeeRecipient_RevertIf_NotOwner() public {
        address newRecipient = address(0x1);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        looksRareRaffle.setProtocolFeeRecipient(newRecipient);
    }

    function test_setProtocolFeeRecipient_RevertIf_InvalidProtocolFeeRecipient() public asPrankedUser(owner) {
        address newRecipient = address(0);
        vm.expectRevert(IRaffle.InvalidProtocolFeeRecipient.selector);
        looksRareRaffle.setProtocolFeeRecipient(newRecipient);
    }
}
