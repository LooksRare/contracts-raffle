// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Raffle_DrawWinners_Test is TestHelpers {
    event EntrySold(uint256 raffleId, address buyer, uint40 entriesCount, uint208 price);
    event RandomnessRequested(uint256 raffleId, uint256 requestId);

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_915);

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.prank(user1);
        _createStandardRaffle();
    }

    function test_drawWinners() public {
        _subscribeRaffleToVRF();

        IRaffle.PricingOption[] memory pricingOptions = _generateStandardPricings();

        for (uint256 i; i < 5; i++) {
            address participant = address(uint160(i + 1));

            vm.deal(participant, 1 ether);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            uint256 pricingOptionIndex = i % 5;
            entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: pricingOptionIndex, count: 1});

            uint208 price = pricingOptions[pricingOptionIndex].price;

            expectEmitCheckAll();
            emit EntrySold(1, participant, pricingOptions[pricingOptionIndex].entriesCount, price);

            // 1 + 10 + 25 + 50 = 86, adding another 100 will trigger the draw
            if (pricingOptionIndex == 4) {
                assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Drawing);

                _expectChainlinkCall();

                expectEmitCheckAll();
                emit RandomnessRequested(1, FULFILL_RANDOM_WORDS_REQUEST_ID);
            }

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: price}(entries, address(0));
        }

        (bool exists, uint248 randomWord, uint256 raffleId) = looksRareRaffle.randomnessRequests(
            FULFILL_RANDOM_WORDS_REQUEST_ID
        );

        assertTrue(exists);
        assertEq(raffleId, 1);
        assertEq(randomWord, 0);

        (, IRaffle.RaffleStatus status, , , uint40 drawnAt, , , , , ) = looksRareRaffle.raffles(1);
        assertEq(uint8(status), uint8(IRaffle.RaffleStatus.Drawing));
        assertEq(drawnAt, block.timestamp);
    }

    function test_drawWinners_RevertIf_RandomnessRequestAlreadyExists() public {
        _subscribeRaffleToVRF();

        IRaffle.PricingOption[] memory pricingOptions = _generateStandardPricings();

        _expectChainlinkCall();

        _stubRandomnessRequestExistence(FULFILL_RANDOM_WORDS_REQUEST_ID, true);

        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);

        uint256 price = pricingOptions[4].price;

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4, count: 1});

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));

        vm.expectRevert(IRaffle.RandomnessRequestAlreadyExists.selector);
        vm.prank(user3);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));
    }

    function _expectChainlinkCall() private {
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
