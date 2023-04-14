// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_Cancel_Test is TestHelpers {
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
        IRaffle.Pricing[5] memory pricings = _generateStandardPricings();

        vm.startPrank(user1);
        looksRareRaffle.createRaffle({
            cutoffTime: block.timestamp + 86_400,
            minimumEntries: 107,
            maximumEntries: 200,
            prizeValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricings: pricings
        });

        uint256[] memory prizeIndices = _generatePrizeIndices(7);
        looksRareRaffle.depositPrizes({raffleId: 0, prizeIndices: prizeIndices});
        vm.stopPrank();
    }

    // TODO: How do we prevent a user from creating a raffle with deposited NFTs from another raffle?
    function test_cancel_RaffleStatusIsCreated() public asPrankedUser(user1) {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        IRaffle.Pricing[5] memory pricings = _generateStandardPricings();

        looksRareRaffle.createRaffle({
            cutoffTime: block.timestamp + 86_400,
            minimumEntries: 107,
            maximumEntries: 200,
            prizeValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricings: pricings
        });

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(1, IRaffle.RaffleStatus.Cancelled);

        looksRareRaffle.cancel(1);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Cancelled);
    }

    function test_cancel_RaffleStatusIsOpen() public {
        _enterRaffles();
        vm.warp(block.timestamp + 86_400 + 1);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Cancelled);

        looksRareRaffle.cancel(0);

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Cancelled);
    }

    function test_cancel_RevertIf_InvalidStatus() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.cancel(0);
    }

    function test_cancel_RevertIf_CutoffTimeNotReached() public {
        _enterRaffles();
        vm.warp(block.timestamp + 86_399);
        vm.expectRevert(IRaffle.CutoffTimeNotReached.selector);
        looksRareRaffle.cancel(0);
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
