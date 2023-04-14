// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle_FulfillRandomWords_Test is TestHelpers {
    Raffle private looksRareRaffle;
    MockERC20 private mockERC20;
    MockERC721 private mockERC721;

    event RaffleStatusUpdated(uint256 raffleId, IRaffle.RaffleStatus status);

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        looksRareRaffle = new Raffle(KEY_HASH, SUBSCRIPTION_ID, VRF_COORDINATOR, owner, PROTOCOL_FEE_RECIPIENT, 500);
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
            minimumEntries: uint80(107),
            maximumEntries: uint80(512),
            maximumEntriesPerParticipant: uint80(100),
            prizesTotalValue: 1 ether,
            minimumProfitBp: uint16(500),
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });

        looksRareRaffle.depositPrizes(0);
        vm.stopPrank();
    }

    function test_fulfillRandomWords() public {
        for (uint256 i; i < 107; ) {
            address participant = address(uint160(i + 1));

            vm.deal(participant, 0.025 ether);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 0});

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

            unchecked {
                ++i;
            }
        }

        vm.startPrank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(looksRareRaffle));
        looksRareRaffle.drawWinners(0);
        vm.stopPrank();

        uint256 winnersCount = 11;
        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Drawn);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);
        assertEq(winners.length, winnersCount);

        assertEq(winners[0].participant, address(79));
        assertEq(winners[0].prizeIndex, 0);

        assertEq(winners[1].participant, address(95));
        assertEq(winners[1].prizeIndex, 1);

        assertEq(winners[2].participant, address(29));
        assertEq(winners[2].prizeIndex, 2);

        assertEq(winners[3].participant, address(56));
        assertEq(winners[3].prizeIndex, 3);

        assertEq(winners[4].participant, address(17));
        assertEq(winners[4].prizeIndex, 4);

        assertEq(winners[5].participant, address(100));
        assertEq(winners[5].prizeIndex, 5);

        assertEq(winners[6].participant, address(31));
        assertEq(winners[7].participant, address(33));
        assertEq(winners[8].participant, address(62));
        assertEq(winners[9].participant, address(70));
        assertEq(winners[10].participant, address(8));

        for (uint256 i = 6; i < winnersCount; ) {
            assertEq(winners[i].prizeIndex, 6);
            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < winnersCount; ) {
            assertFalse(winners[i].claimed);
            unchecked {
                ++i;
            }
        }

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Drawn);
    }

    function test_fulfillRandomWords_SomeParticipantsDrawnMoreThanOnce() public {
        for (uint256 i; i < 107; ) {
            address participant = address(uint160(i + 1));

            vm.deal(participant, 0.025 ether);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 0});

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

            unchecked {
                ++i;
            }
        }

        vm.startPrank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(looksRareRaffle));
        looksRareRaffle.drawWinners(0);
        vm.stopPrank();

        uint256 winnersCount = 11;
        uint256[] memory randomWords = new uint256[](winnersCount);
        randomWords[0] = 5_350; // 5350 % 107 + 1 = 1
        randomWords[1] = 5_351; // 5351 % 107 + 1 = 2
        randomWords[2] = 5_352; // 5352 % 107 + 1 = 3
        randomWords[3] = 10_700; // 10700 % 107 + 1 = 1 (becomes 4)
        randomWords[4] = 10_701; // 10701 % 107 + 1 = 2 (becomes 5)
        randomWords[5] = 10_702; // 10702 % 107 + 1 = 3 (becomes 6)
        randomWords[6] = 16_050; // 16050 % 107 + 1 = 1 (becomes 7)
        randomWords[7] = 16_051; // 16051 % 107 + 1 = 2 (becomes 8)
        randomWords[8] = 16_052; // 16052 % 107 + 1 = 3 (becomes 9)

        randomWords[9] = 21_405; // 21405 % 100 + 1 = 5 (becomes 10)
        randomWords[10] = 21_406; // 21406 % 100 + 1 = 6 (becomes 11)

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Drawn);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);
        assertEq(winners.length, winnersCount);

        assertEq(winners[0].participant, address(1));
        assertEq(winners[0].prizeIndex, 0);

        assertEq(winners[1].participant, address(2));
        assertEq(winners[1].prizeIndex, 1);

        assertEq(winners[2].participant, address(3));
        assertEq(winners[2].prizeIndex, 2);

        assertEq(winners[3].participant, address(4));
        assertEq(winners[3].prizeIndex, 3);

        assertEq(winners[4].participant, address(5));
        assertEq(winners[4].prizeIndex, 4);

        assertEq(winners[5].participant, address(6));
        assertEq(winners[5].prizeIndex, 5);

        assertEq(winners[6].participant, address(7));
        assertEq(winners[7].participant, address(8));
        assertEq(winners[8].participant, address(9));
        assertEq(winners[9].participant, address(10));
        assertEq(winners[10].participant, address(11));

        for (uint256 i = 6; i < winnersCount; ) {
            assertEq(winners[i].prizeIndex, 6);
            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < winnersCount; ) {
            assertFalse(winners[i].claimed);
            unchecked {
                ++i;
            }
        }

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Drawn);
    }

    function test_fulfillRandomWords_SomeParticipantsDrawnMoreThanOnce_MultipleBucketsWithOverflow() public {
        for (uint256 i; i < 512; ) {
            address participant = address(uint160(i + 1));

            vm.deal(participant, 0.025 ether);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 0});

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

            unchecked {
                ++i;
            }
        }

        vm.startPrank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(looksRareRaffle));
        looksRareRaffle.drawWinners(0);
        vm.stopPrank();

        uint256 winnersCount = 11;
        uint256[] memory randomWords = new uint256[](winnersCount);
        randomWords[0] = 766; // 766 % 512 + 1 = 255 (bucket 0, index 255)
        randomWords[1] = 1_278; // 1278 % 512 + 1 = 255, duplicate so 256 (bucket 1, index 0)
        randomWords[2] = 1_280; // 1280 % 512 + 1 = 257 (bucket 1, index 1)
        randomWords[3] = 1_792; // 1792 % 512 + 1 = 257, duplicate so 258 (bucket 1, index 1)
        randomWords[4] = 510; // 510 % 512 + 1 = 511 (bucket 1, index 255)
        randomWords[5] = 511; // 511 % 512 + 1 = 512 (cycle back to bucket 0, index 0)
        randomWords[6] = 333; // 333 % 512 + 1 = 334 (bucket 1, index 178)
        randomWords[7] = 45; // 45 % 512 + 1 = 46 (bucket 0, index 46)
        randomWords[8] = 512; // 512 % 512 + 1 = 1 (cycle back to bucket 0, index 1)

        randomWords[9] = 888; // 888 % 512 + 1 = 377 (bucket 1, index 121)
        randomWords[10] = 69_420; // 69420 % 512 + 1 = 301 (bucket 1, index 45)

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Drawn);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);
        assertEq(winners.length, winnersCount);

        assertEq(winners[0].participant, address(255));
        assertEq(winners[0].prizeIndex, 0);

        assertEq(winners[1].participant, address(256));
        assertEq(winners[1].prizeIndex, 1);

        assertEq(winners[2].participant, address(257));
        assertEq(winners[2].prizeIndex, 2);

        assertEq(winners[3].participant, address(258));
        assertEq(winners[3].prizeIndex, 3);

        assertEq(winners[4].participant, address(511));
        assertEq(winners[4].prizeIndex, 4);

        assertEq(winners[5].participant, address(512));
        assertEq(winners[5].prizeIndex, 5);

        assertEq(winners[6].participant, address(334));
        assertEq(winners[7].participant, address(46));
        assertEq(winners[8].participant, address(1));
        assertEq(winners[9].participant, address(377));
        assertEq(winners[10].participant, address(301));

        for (uint256 i = 6; i < winnersCount; ) {
            assertEq(winners[i].prizeIndex, 6);
            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < winnersCount; ) {
            assertFalse(winners[i].claimed);
            unchecked {
                ++i;
            }
        }

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Drawn);
    }

    mapping(uint256 => bool) private winningEntries;

    /**
     * @dev seed is uint248 so that I don't have to deal with the overflow
     *      when adding 1-10 to it
     */
    function testFuzz_fulfillRandomWords(uint248 seed) public {
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();
        uint256 userIndex;
        uint80 currentEntryIndex;
        while (currentEntryIndex < 107) {
            address participant = address(uint160(userIndex + 1));
            vm.deal(participant, 1 ether);

            uint256 pricingIndex = userIndex % 5;
            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: pricingIndex});

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: pricingOptions[pricingIndex].price}(entries);

            unchecked {
                currentEntryIndex += pricingOptions[pricingIndex].entriesCount;
                ++userIndex;
            }
        }

        vm.startPrank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(looksRareRaffle));
        looksRareRaffle.drawWinners(0);
        vm.stopPrank();

        uint256 winnersCount = 11;
        uint256[] memory randomWords = new uint256[](winnersCount);
        for (uint256 i; i < winnersCount; ) {
            randomWords[i] = uint256(keccak256(abi.encodePacked(seed + i)));
            unchecked {
                ++i;
            }
        }

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Drawn);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);
        assertEq(winners.length, winnersCount);

        for (uint256 i; i < 6; ) {
            assertEq(winners[i].prizeIndex, i);
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 6; i < winnersCount; ) {
            assertEq(winners[i].prizeIndex, 6);
            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < winnersCount; ) {
            assertFalse(winners[i].claimed);
            assertNotEq(winners[i].participant, address(0));

            uint80 entryIndex = winners[i].entryIndex;
            assertFalse(winningEntries[entryIndex]);
            winningEntries[entryIndex] = true;

            unchecked {
                ++i;
            }
        }

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Drawn);
    }
}
