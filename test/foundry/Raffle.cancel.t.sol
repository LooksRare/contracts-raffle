// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_Cancel_Test is TestHelpers {
    function setUp() public {
        _forkSepolia();

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.prank(user1);
        looksRareRaffle.createRaffle(_baseCreateRaffleParams(address(mockERC20), address(mockERC721)));
    }

    function test_cancel() public {
        _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(1);
        vm.warp(block.timestamp + 86_400 + 1);

        assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Refundable);

        looksRareRaffle.cancel(1);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Refundable);
    }

    function test_cancel_RevertIf_InvalidStatus() public {
        _transitionRaffleStatusToDrawing();
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.cancel(1);
    }

    function test_cancel_RevertIf_CutoffTimeNotReached() public {
        _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(1);
        vm.warp(block.timestamp + 86_399);
        vm.expectRevert(IRaffle.CutoffTimeNotReached.selector);
        looksRareRaffle.cancel(1);
    }
}
