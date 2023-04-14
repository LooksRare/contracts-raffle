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

    event PrizeClaimed(
        uint256 raffleId,
        address winner,
        IRaffle.TokenType prizeType,
        address prizeAddress,
        uint256 prizeId,
        uint256 prizeAmount
    );

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        looksRareRaffle = new Raffle(KEY_HASH, SUBSCRIPTION_ID, VRF_COORDINATOR, owner, PROTOCOL_FEE_RECIPIENT, 500);
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));

        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        // Make it 11 winners in total instead of 106 winners for easier testing.
        prizes[6].winnersCount = 5;
        IRaffle.Pricing[5] memory pricings = _generateStandardPricings();

        vm.startPrank(user1);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: uint64(107),
            maximumEntries: uint64(200),
            maximumEntriesPerParticipant: uint64(100),
            prizeValue: 1 ether,
            minimumProfitBp: uint16(500),
            feeTokenAddress: address(0),
            prizes: prizes,
            pricings: pricings
        });

        looksRareRaffle.depositPrizes(0);
        vm.stopPrank();
    }

    function test_claimPrize() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);

        for (uint256 i; i < 6; ) {
            vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
            emit PrizeClaimed({
                raffleId: 0,
                winner: winners[i].participant,
                prizeType: IRaffle.TokenType.ERC721,
                prizeAddress: address(mockERC721),
                prizeId: i,
                prizeAmount: 1
            });
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 6; i < 11; ) {
            vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
            emit PrizeClaimed({
                raffleId: 0,
                winner: winners[i].participant,
                prizeType: IRaffle.TokenType.ERC20,
                prizeAddress: address(mockERC20),
                prizeId: 0,
                prizeAmount: 1_000 ether
            });
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < 11; ) {
            assertFalse(winners[i].claimed);

            looksRareRaffle.claimPrize(0, i);
            unchecked {
                ++i;
            }
        }

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

        winners = looksRareRaffle.getWinners(0);
        for (uint256 i; i < 11; ) {
            assertTrue(winners[i].claimed);
            unchecked {
                ++i;
            }
        }
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

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);

        for (uint256 i; i < 11; ) {
            assertFalse(winners[i].claimed);

            looksRareRaffle.claimPrize(0, i);

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

        vm.prank(user2);
        vm.expectRevert(IRaffle.InvalidIndex.selector);
        looksRareRaffle.claimPrize(0, 11);
    }
}
