// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../../lib/forge-std/src/Test.sol";

import {RaffleV2} from "../../contracts/RaffleV2.sol";
import {IRaffleV2} from "../../contracts/interfaces/IRaffleV2.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

abstract contract AssertionHelpers is Test {
    event EntrySold(uint256 raffleId, address buyer, uint40 entriesCount, uint208 price);
    event PrizeClaimed(uint256 raffleId, uint256 winnerIndex);
    event PrizesClaimed(uint256 raffleId, uint256[] winnerIndices);
    event RaffleStatusUpdated(uint256 raffleId, IRaffleV2.RaffleStatus status);
    event RandomnessRequested(uint256 raffleId, uint256 requestId);

    function assertRaffleStatus(
        RaffleV2 looksRareRaffle,
        uint256 raffleId,
        IRaffleV2.RaffleStatus expectedStatus
    ) internal {
        (, IRaffleV2.RaffleStatus status, , , , , , , , ) = looksRareRaffle.raffles(raffleId);
        assertEq(uint8(status), uint8(expectedStatus));
    }

    function assertAllWinnersClaimed(IRaffleV2.Winner[] memory winners) internal {
        for (uint256 i; i < winners.length; i++) {
            assertTrue(winners[i].claimed);
        }
    }

    function assertRaffleStatusUpdatedEventEmitted(uint256 raffleId, IRaffleV2.RaffleStatus status) internal {
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

    function _expectChainlinkCall() internal {
        vm.expectCall(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            abi.encodeCall(
                VRFCoordinatorV2Interface.requestRandomWords,
                (
                    hex"474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
                    uint64(1_122),
                    uint16(3),
                    500_000,
                    uint32(1)
                )
            )
        );
    }
}
