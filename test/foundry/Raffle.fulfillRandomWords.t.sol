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

        looksRareRaffle = _deployRaffle();
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));

        vm.prank(owner);
        looksRareRaffle.updateCurrencyStatus(address(mockERC20), true);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        // Make it 11 winners in total instead of 106 winners for easier testing.
        params.prizes[6].winnersCount = 5;
        params.maximumEntries = 512;
        params.maximumEntriesPerParticipant = 100;

        vm.startPrank(user1);
        looksRareRaffle.createRaffle(params);

        looksRareRaffle.depositPrizes(1);
        vm.stopPrank();

        vm.prank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(looksRareRaffle));

        _enterRafflesWithSingleEntryUpToMinimumEntries(looksRareRaffle);
    }

    function test_fulfillRandomWords() public {
        uint256[] memory _randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(1, IRaffle.RaffleStatus.RandomnessFulfilled);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(
            FULFILL_RANDOM_WORDS_REQUEST_ID,
            _randomWords
        );

        (bool exists, uint256 raffleId) = looksRareRaffle.randomnessRequests(FULFILL_RANDOM_WORDS_REQUEST_ID);
        uint256[] memory randomWords = looksRareRaffle.getRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID);
        assertTrue(exists);
        assertEq(raffleId, 1);
        assertEq(randomWords, _randomWords);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.RandomnessFulfilled);
    }

    function test_fulfillRandomWords_RequestIdDoesNotExists() public {
        uint256[] memory _randomWords = _generateRandomWordsForRaffleWith11Winners();

        uint256 invalidRequestId = 69_420;

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(invalidRequestId, _randomWords);

        (bool exists, uint256 raffleId) = looksRareRaffle.randomnessRequests(invalidRequestId);
        uint256[] memory randomWords = looksRareRaffle.getRandomWords(invalidRequestId);
        assertFalse(exists);
        assertEq(raffleId, 0);
        assertEq(randomWords, new uint256[](0));

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Drawing);
    }

    function test_fulfillRandomWords_RandomWordsLengthIsNotEqualToCumulativeWinnersCount() public {
        uint256[] memory _randomWords = new uint256[](10);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(
            FULFILL_RANDOM_WORDS_REQUEST_ID,
            _randomWords
        );

        (bool exists, uint256 raffleId) = looksRareRaffle.randomnessRequests(FULFILL_RANDOM_WORDS_REQUEST_ID);
        uint256[] memory randomWords = looksRareRaffle.getRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID);
        assertTrue(exists);
        assertEq(raffleId, 1);
        assertEq(randomWords, new uint256[](0));

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Drawing);
    }

    function test_fulfillRandomWords_RaffleStatusIsNotDrawing() public {
        uint256[] memory _randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(1, IRaffle.RaffleStatus.RandomnessFulfilled);

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(
            FULFILL_RANDOM_WORDS_REQUEST_ID,
            _randomWords
        );

        uint256[] memory _randomWordsTwo = new uint256[](11);

        // It doesn't revert, but does not update the randomness request.
        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(
            FULFILL_RANDOM_WORDS_REQUEST_ID,
            _randomWordsTwo
        );

        (bool exists, uint256 raffleId) = looksRareRaffle.randomnessRequests(FULFILL_RANDOM_WORDS_REQUEST_ID);
        uint256[] memory randomWords = looksRareRaffle.getRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID);
        assertTrue(exists);
        assertEq(raffleId, 1);
        assertEq(randomWords, _randomWords);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.RandomnessFulfilled);
    }
}
