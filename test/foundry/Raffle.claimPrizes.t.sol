// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

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

    function test_claimPrizes_MultiplePrizes() public {
        _subscribeRaffleToVRF();

        address participant = address(69);
        uint256 price = 1.17 ether;

        vm.deal(participant, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4});

        vm.prank(participant);
        looksRareRaffle.enterRaffles{value: price}(entries);
        _fulfillRandomWords();
        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        uint256[] memory winnerIndices = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            winnerIndices[i] = i;
        }
        IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
        claimPrizesCalldata[0].raffleId = 1;
        claimPrizesCalldata[0].winnerIndices = winnerIndices;

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit PrizesClaimed({raffleId: 1, winnerIndices: winnerIndices});

        vm.prank(participant);
        looksRareRaffle.claimPrizes(claimPrizesCalldata);

        assertEq(mockERC721.balanceOf(participant), 6);
        for (uint256 i; i < 6; i++) {
            assertEq(mockERC721.ownerOf(i), participant);
        }

        assertEq(mockERC20.balanceOf(participant), 5_000 ether);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(1);
        assertAllWinnersClaimed(winners);
    }

    function test_claimPrizes_MultipleRaffles() public {
        mockERC721.batchMint(user1, 6, 6);

        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        for (uint256 i; i < prizes.length; i++) {
            prizes[i].prizeId = i + 6;
        }

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        prizes[6].winnersCount = 5;
        params.prizes = prizes;

        vm.startPrank(user1);
        looksRareRaffle.createRaffle(params);
        looksRareRaffle.depositPrizes(2);
        vm.stopPrank();

        _subscribeRaffleToVRF();

        address participant = address(69);
        uint256 price = 2.34 ether;

        vm.deal(participant, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](4);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4});
        entries[2] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 1});
        entries[3] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 4});

        vm.prank(participant);
        looksRareRaffle.enterRaffles{value: price}(entries);
        _fulfillRandomWords();
        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        uint256 requestIdTwo = 108392438658618723438648115145292582477374264027476206043327064348457204807342;
        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();
        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(looksRareRaffle).rawFulfillRandomWords(requestIdTwo, randomWords);
        looksRareRaffle.selectWinners(requestIdTwo);

        uint256[] memory winnerIndices = new uint256[](11);
        for (uint256 i; i < 11; i++) {
            winnerIndices[i] = i;
        }
        IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](2);
        claimPrizesCalldata[0].raffleId = 1;
        claimPrizesCalldata[0].winnerIndices = winnerIndices;
        claimPrizesCalldata[1].raffleId = 2;
        claimPrizesCalldata[1].winnerIndices = winnerIndices;

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit PrizesClaimed({raffleId: 1, winnerIndices: winnerIndices});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit PrizesClaimed({raffleId: 2, winnerIndices: winnerIndices});

        vm.prank(participant);
        looksRareRaffle.claimPrizes(claimPrizesCalldata);

        assertEq(mockERC721.balanceOf(participant), 12);
        for (uint256 i; i < 12; i++) {
            assertEq(mockERC721.ownerOf(i), participant);
        }

        assertEq(mockERC20.balanceOf(participant), 10_000 ether);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(1);
        assertAllWinnersClaimed(winners);

        winners = looksRareRaffle.getWinners(2);
        assertAllWinnersClaimed(winners);
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

        for (uint256 i; i < 11; i++) {
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

        for (uint256 i; i < 11; i++) {
            uint256[] memory winnerIndices = new uint256[](1);
            winnerIndices[0] = i;

            IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
            claimPrizesCalldata[0].raffleId = 1;
            claimPrizesCalldata[0].winnerIndices = winnerIndices;

            vm.prank(address(42));
            vm.expectRevert(IRaffle.NotWinner.selector);
            looksRareRaffle.claimPrizes(claimPrizesCalldata);
        }
    }

    function _claimPrizes() private {
        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(1);
        for (uint256 i; i < 11; i++) {
            assertFalse(winners[i].claimed);

            uint256[] memory winnerIndices = new uint256[](1);
            winnerIndices[0] = i;

            IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
            claimPrizesCalldata[0].raffleId = 1;
            claimPrizesCalldata[0].winnerIndices = winnerIndices;

            vm.prank(winners[i].participant);
            looksRareRaffle.claimPrizes(claimPrizesCalldata);
        }
    }

    function _assertPrizesClaimedEventsEmitted() private {
        for (uint256 i; i < 11; i++) {
            uint256[] memory winnerIndices = new uint256[](1);
            winnerIndices[0] = i;
            vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
            emit PrizesClaimed({raffleId: 1, winnerIndices: winnerIndices});
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
        assertAllWinnersClaimed(winners);
    }
}
