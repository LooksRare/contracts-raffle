// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IOwnableTwoSteps} from "@looksrare/contracts-libs/contracts/interfaces/IOwnableTwoSteps.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_CancelAfterRandomnessRequest_Test is TestHelpers {
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

        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.startPrank(user1);
        looksRareRaffle.createRaffle({
            cutoffTime: block.timestamp + 86_400,
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

    function test_cancelAfterRandomnessRequest() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Cancelled);

        (, , , uint256 drawnAt, , , , , , , ) = looksRareRaffle.raffles(0);
        vm.warp(drawnAt + 86_400 + 1);

        vm.prank(owner);
        looksRareRaffle.cancelAfterRandomnessRequest(0);

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Cancelled);

        assertEq(mockERC721.balanceOf(user1), 6);
        for (uint256 i; i < 6; ) {
            assertEq(mockERC721.ownerOf(i), user1);
            unchecked {
                ++i;
            }
        }
        assertEq(mockERC20.balanceOf(user1), 100_000 ether);
    }

    function test_cancelAfterRandomnessRequest_RevertIf_NotOwner() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        (, , , uint256 drawnAt, , , , , , , ) = looksRareRaffle.raffles(0);
        vm.warp(drawnAt + 86_400 + 1);

        vm.expectRevert(IOwnableTwoSteps.NotOwner.selector);
        looksRareRaffle.cancelAfterRandomnessRequest(0);
    }

    function test_cancelAfterRandomnessRequest_RevertIf_InvalidStatus() public {
        _enterRaffles();
        vm.prank(owner);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.cancelAfterRandomnessRequest(0);
    }

    function test_cancelAfterRandomnessRequest_RevertIf_DrawExpirationTimeNotReached() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        (, , , uint256 drawnAt, , , , , , , ) = looksRareRaffle.raffles(0);
        vm.warp(drawnAt + 86_399);

        vm.prank(owner);
        vm.expectRevert(IRaffle.DrawExpirationTimeNotReached.selector);
        looksRareRaffle.cancelAfterRandomnessRequest(0);
    }

    function _enterRaffles() private {
        // 1 entry short of the minimum, starting with 10 to skip the precompile contracts
        for (uint256 i = 10; i < 116; ) {
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
    }
}
