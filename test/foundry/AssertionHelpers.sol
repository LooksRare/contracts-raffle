// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../../lib/forge-std/src/Test.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

abstract contract AssertionHelpers is Test {
    event PrizeClaimed(uint256 raffleId, uint256 winnerIndex);
    event PrizesClaimed(uint256 raffleId, uint256[] winnerIndices);
    event RaffleStatusUpdated(uint256 raffleId, IRaffle.RaffleStatus status);

    function assertRaffleStatus(
        Raffle looksRareRaffle,
        uint256 raffleId,
        IRaffle.RaffleStatus expectedStatus
    ) internal {
        (, IRaffle.RaffleStatus status, , , , , , , , ) = looksRareRaffle.raffles(raffleId);
        assertEq(uint8(status), uint8(expectedStatus));
    }

    function assertAllWinnersClaimed(IRaffle.Winner[] memory winners) internal {
        for (uint256 i; i < winners.length; i++) {
            assertTrue(winners[i].claimed);
        }
    }

    function assertRaffleStatusUpdatedEventEmitted(uint256 raffleId, IRaffle.RaffleStatus status) internal {
        expectEmitCheckAll();
        emit RaffleStatusUpdated(raffleId, status);
    }

    function expectEmitCheckAll() internal {
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
    }

    function assertERC721Balance(
        MockERC721 mockERC721,
        address participant,
        uint256 count
    ) internal {
        assertEq(mockERC721.balanceOf(participant), count);
        for (uint256 i; i < count; i++) {
            assertEq(mockERC721.ownerOf(i), participant);
        }
    }
}
