// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_CancelAfterRandomnessRequest_Test is TestHelpers {
    function setUp() public {
        _forkSepolia();

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.prank(user1);
        looksRareRaffle.createRaffle(_baseCreateRaffleParams(address(mockERC20), address(mockERC721)));
    }

    function test_cancelAfterRandomnessRequest() public {
        _transitionRaffleStatusToDrawing();

        assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Refundable);

        (, , , , uint40 drawnAt, , , , , ) = looksRareRaffle.raffles(1);
        vm.warp(drawnAt + 86_400 + 1);

        vm.prank(owner);
        looksRareRaffle.cancelAfterRandomnessRequest(1);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Refundable);
    }

    function test_cancelAfterRandomnessRequest_RevertIf_NotOwner() public {
        _transitionRaffleStatusToDrawing();

        (, , , , uint40 drawnAt, , , , , ) = looksRareRaffle.raffles(1);
        vm.warp(drawnAt + 86_400 + 1);

        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        looksRareRaffle.cancelAfterRandomnessRequest(1);
    }

    function test_cancelAfterRandomnessRequest_RevertIf_InvalidStatus() public {
        _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(1);
        vm.prank(owner);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.cancelAfterRandomnessRequest(1);
    }

    function test_cancelAfterRandomnessRequest_RevertIf_DrawExpirationTimeNotReached() public {
        _transitionRaffleStatusToDrawing();

        (, , , , uint40 drawnAt, , , , , ) = looksRareRaffle.raffles(1);
        vm.warp(drawnAt + 86_399);

        vm.prank(owner);
        vm.expectRevert(IRaffle.DrawExpirationTimeNotReached.selector);
        looksRareRaffle.cancelAfterRandomnessRequest(1);
    }
}
