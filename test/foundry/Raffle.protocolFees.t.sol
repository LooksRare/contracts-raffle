// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_ProtocolFees_Test is TestHelpers {
    event ProtocolFeeParametersUpdated(uint16 protocolFeeBp, address protocolFeeRecipient);

    function setUp() public {
        _deployRaffle();
    }

    function test_setProtocolFeeParameters() public asPrankedUser(owner) {
        address newRecipient = address(0x1);
        expectEmitCheckAll();
        emit ProtocolFeeParametersUpdated(2_409, newRecipient);
        looksRareRaffle.setProtocolFeeParameters(2_409, newRecipient);
        assertEq(looksRareRaffle.protocolFeeBp(), 2_409);
        assertEq(looksRareRaffle.protocolFeeRecipient(), newRecipient);
    }

    function test_setProtocolFeeParameters_RevertIf_NotOwner() public {
        address newRecipient = address(0x1);
        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        looksRareRaffle.setProtocolFeeParameters(2_409, newRecipient);
    }

    function test_setProtocolFeeParameters_RevertIf_InvalidProtocolFeeRecipient() public asPrankedUser(owner) {
        address newRecipient = address(0);
        vm.expectRevert(IRaffle.InvalidProtocolFeeRecipient.selector);
        looksRareRaffle.setProtocolFeeParameters(2_409, newRecipient);
    }

    function test_setProtocolFeeParameters_RevertIf_InvalidProtocolFeeBp() public asPrankedUser(owner) {
        uint16 newProtocolFeeBp = 2_501;
        vm.expectRevert(IRaffle.InvalidProtocolFeeBp.selector);
        looksRareRaffle.setProtocolFeeParameters(newProtocolFeeBp, address(0x1));
    }
}
