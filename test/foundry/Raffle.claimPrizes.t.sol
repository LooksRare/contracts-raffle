// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// TODO: Test claim prizes with multiple prizes / claim prizes from multiple raffles
contract Raffle_ClaimPrizes_Test is TestHelpers {
    event PrizesClaimed(uint256 raffleId, uint256[] winnerIndices);

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        // Make it 11 winners in total instead of 106 winners for easier testing.
        params.prizes[6].winnersCount = 5;

        vm.startPrank(user1);
        looksRareRaffle.createRaffle(params);

        looksRareRaffle.depositPrizes(1);
        vm.stopPrank();
    }

    function test_claimPrizes_StatusIsDrawn() public {
        _transitionRaffleStatusToDrawing();

        _fulfillRandomWords();

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        _assertPrizesClaimedEventsEmitted();
        _claimPrizes();
        _assertPrizesTransferred();
    }

    function test_claimPrizes_StatusIsComplete() public {
        _transitionRaffleStatusToDrawing();

        _fulfillRandomWords();

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);
        looksRareRaffle.claimFees(1);

        _assertPrizesClaimedEventsEmitted();
        _claimPrizes();
        _assertPrizesTransferred();
    }

    function test_claimPrizes_RevertIf_InvalidStatus() public {
        _transitionRaffleStatusToDrawing();

        uint256[] memory winnerIndices = new uint256[](1);
        winnerIndices[0] = 0;

        IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
        claimPrizesCalldata[0].raffleId = 1;
        claimPrizesCalldata[0].winnerIndices = winnerIndices;

        vm.expectRevert(IRaffle.InvalidStatus.selector);
        vm.prank(user2);
        looksRareRaffle.claimPrizes(claimPrizesCalldata);
    }

    function test_claimPrizes_RevertIf_PrizeAlreadyClaimed() public {
        _transitionRaffleStatusToDrawing();

        _fulfillRandomWords();

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(1);

        for (uint256 i; i < 11; ) {
            assertFalse(winners[i].claimed);

            uint256[] memory winnerIndices = new uint256[](1);
            winnerIndices[0] = i;

            IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
            claimPrizesCalldata[0].raffleId = 1;
            claimPrizesCalldata[0].winnerIndices = winnerIndices;

            vm.prank(winners[i].participant);
            looksRareRaffle.claimPrizes(claimPrizesCalldata);

            vm.prank(winners[i].participant);
            vm.expectRevert(IRaffle.PrizeAlreadyClaimed.selector);
            looksRareRaffle.claimPrizes(claimPrizesCalldata);

            unchecked {
                ++i;
            }
        }
    }

    function test_claimPrizes_RevertIf_InvalidIndex() public {
        _transitionRaffleStatusToDrawing();

        _fulfillRandomWords();

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(1);

        uint256[] memory winnerIndices = new uint256[](1);
        winnerIndices[0] = 11;

        IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
        claimPrizesCalldata[0].raffleId = 1;
        claimPrizesCalldata[0].winnerIndices = winnerIndices;

        vm.prank(winners[10].participant);
        vm.expectRevert(IRaffle.InvalidIndex.selector);
        looksRareRaffle.claimPrizes(claimPrizesCalldata);
    }

    function test_claimPrizes_RevertIf_NotWinner() public {
        _transitionRaffleStatusToDrawing();

        _fulfillRandomWords();

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        for (uint256 i; i < 11; ) {
            uint256[] memory winnerIndices = new uint256[](1);
            winnerIndices[0] = i;

            IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
            claimPrizesCalldata[0].raffleId = 1;
            claimPrizesCalldata[0].winnerIndices = winnerIndices;

            vm.prank(address(42));
            vm.expectRevert(IRaffle.NotWinner.selector);
            looksRareRaffle.claimPrizes(claimPrizesCalldata);

            unchecked {
                ++i;
            }
        }
    }

    function _claimPrizes() private {
        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(1);
        for (uint256 i; i < 11; ) {
            assertFalse(winners[i].claimed);

            uint256[] memory winnerIndices = new uint256[](1);
            winnerIndices[0] = i;

            IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
            claimPrizesCalldata[0].raffleId = 1;
            claimPrizesCalldata[0].winnerIndices = winnerIndices;

            vm.prank(winners[i].participant);
            looksRareRaffle.claimPrizes(claimPrizesCalldata);
            unchecked {
                ++i;
            }
        }
    }

    function _assertPrizesClaimedEventsEmitted() private {
        for (uint256 i; i < 11; ) {
            uint256[] memory winnerIndices = new uint256[](1);
            winnerIndices[0] = i;
            vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
            emit PrizesClaimed({raffleId: 1, winnerIndices: winnerIndices});
            unchecked {
                ++i;
            }
        }
    }

    function _assertPrizesTransferred() private {
        assertEq(mockERC721.balanceOf(address(79)), 1);
        assertEq(mockERC721.ownerOf(0), address(79));

        assertEq(mockERC721.balanceOf(address(95)), 1);
        assertEq(mockERC721.ownerOf(1), address(95));

        assertEq(mockERC721.balanceOf(address(29)), 1);
        assertEq(mockERC721.ownerOf(2), address(29));

        assertEq(mockERC721.balanceOf(address(56)), 1);
        assertEq(mockERC721.ownerOf(3), address(56));

        assertEq(mockERC721.balanceOf(address(17)), 1);
        assertEq(mockERC721.ownerOf(4), address(17));

        assertEq(mockERC721.balanceOf(address(100)), 1);
        assertEq(mockERC721.ownerOf(5), address(100));

        assertEq(mockERC20.balanceOf(address(31)), 1_000 ether);
        assertEq(mockERC20.balanceOf(address(33)), 1_000 ether);
        assertEq(mockERC20.balanceOf(address(62)), 1_000 ether);
        assertEq(mockERC20.balanceOf(address(70)), 1_000 ether);
        assertEq(mockERC20.balanceOf(address(8)), 1_000 ether);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(1);
        for (uint256 i; i < 11; ) {
            assertTrue(winners[i].claimed);
            unchecked {
                ++i;
            }
        }
    }
}
