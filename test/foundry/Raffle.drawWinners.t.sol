// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Raffle_DrawWinners_Test is TestHelpers {
    Raffle private looksRareRaffle;
    MockERC20 private mockERC20;
    MockERC721 private mockERC721;

    event RaffleStatusUpdated(uint256 raffleId, IRaffle.RaffleStatus status);
    event RandomnessRequested(uint256 raffleId, uint256 requestId);

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_915);

        looksRareRaffle = _deployRaffle();
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));

        vm.startPrank(user1);
        _createStandardRaffle(address(mockERC20), address(mockERC721), looksRareRaffle);

        looksRareRaffle.depositPrizes(0);
        vm.stopPrank();
    }

    function test_drawWinners() public {
        for (uint256 i; i < 10; ) {
            (, IRaffle.RaffleStatus status, , , , , , , , , ) = looksRareRaffle.raffles(0);

            if (status == IRaffle.RaffleStatus.ReadyToBeDrawn) {
                break;
            }

            address participant = address(uint160(i + 1));

            vm.deal(participant, 1 ether);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            uint256 pricingOptionIndex = i % 5;
            entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingOptionIndex: pricingOptionIndex});

            IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: pricingOptions[pricingOptionIndex].price}(entries);

            unchecked {
                ++i;
            }
        }

        uint32 winnersCount = 106;

        vm.expectCall(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            abi.encodeCall(
                VRFCoordinatorV2Interface.requestRandomWords,
                (
                    hex"474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
                    uint64(1_122),
                    uint16(3),
                    20_000 * winnersCount,
                    winnersCount
                )
            )
        );

        vm.startPrank(SUBSCRIPTION_ADMIN);

        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(looksRareRaffle));

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Drawing);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RandomnessRequested(0, FULFILL_RANDOM_WORDS_REQUEST_ID);

        looksRareRaffle.drawWinners(0);

        vm.stopPrank();

        (bool exists, uint256 raffleId) = looksRareRaffle.randomnessRequests(FULFILL_RANDOM_WORDS_REQUEST_ID);

        assertTrue(exists);
        assertEq(raffleId, 0);

        (, IRaffle.RaffleStatus status, , uint40 drawnAt, , , , , , , ) = looksRareRaffle.raffles(0);
        assertEq(uint8(status), uint8(IRaffle.RaffleStatus.Drawing));
        assertEq(drawnAt, block.timestamp);
    }

    function test_drawWinners_RevertIf_InvalidStatus() public asPrankedUser(user2) {
        vm.deal(user2, 0.95 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingOptionIndex: 4});

        looksRareRaffle.enterRaffles{value: 0.95 ether}(entries);

        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.drawWinners(0);
    }
}
