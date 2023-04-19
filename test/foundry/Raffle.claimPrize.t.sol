// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle_ClaimPrize_Test is TestHelpers {
    Raffle private looksRareRaffle;
    MockERC20 private mockERC20;
    MockERC721 private mockERC721;

    event PrizeClaimed(uint256 raffleId, uint256 winnerIndex);

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        looksRareRaffle = _deployRaffle();
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));

        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        // Make it 11 winners in total instead of 106 winners for easier testing.
        prizes[6].winnersCount = 5;
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.startPrank(user1);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });

        looksRareRaffle.depositPrizes(0);
        vm.stopPrank();
    }

    function test_claimPrize_StatusIsDrawn() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        _assertPrizesClaimedEventsEmitted();
        _claimPrizes();
        _assertPrizesTransferred();
    }

    function test_claimPrize_StatusIsComplete() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);
        looksRareRaffle.claimFees(0);

        _assertPrizesClaimedEventsEmitted();
        _claimPrizes();
        _assertPrizesTransferred();
    }

    function test_claimPrize_RevertIf_InvalidStatus() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        vm.expectRevert(IRaffle.InvalidStatus.selector);
        vm.prank(user2);
        looksRareRaffle.claimPrize(0, 0);
    }

    function test_claimPrize_RevertIf_PrizeAlreadyClaimed() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);

        for (uint256 i; i < 11; ) {
            assertFalse(winners[i].claimed);

            vm.prank(winners[i].participant);
            looksRareRaffle.claimPrize(0, i);

            vm.prank(winners[i].participant);
            vm.expectRevert(IRaffle.PrizeAlreadyClaimed.selector);
            looksRareRaffle.claimPrize(0, i);

            unchecked {
                ++i;
            }
        }
    }

    function test_claimPrize_RevertIf_InvalidIndex() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);

        vm.prank(winners[10].participant);
        vm.expectRevert(IRaffle.InvalidIndex.selector);
        looksRareRaffle.claimPrize(0, 11);
    }

    function test_claimPrize_RevertIf_NotWinner() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        for (uint256 i; i < 11; ) {
            vm.prank(address(42));
            vm.expectRevert(IRaffle.NotWinner.selector);
            looksRareRaffle.claimPrize(0, i);

            unchecked {
                ++i;
            }
        }
    }

    function _claimPrizes() private {
        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);
        for (uint256 i; i < 11; ) {
            assertFalse(winners[i].claimed);

            vm.prank(winners[i].participant);
            looksRareRaffle.claimPrize(0, i);
            unchecked {
                ++i;
            }
        }
    }

    function _assertPrizesClaimedEventsEmitted() private {
        for (uint256 i; i < 11; ) {
            vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
            emit PrizeClaimed({raffleId: 0, winnerIndex: i});
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

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);
        for (uint256 i; i < 11; ) {
            assertTrue(winners[i].claimed);
            unchecked {
                ++i;
            }
        }
    }
}
