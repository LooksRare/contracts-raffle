// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_EnterRaffles_Test is TestHelpers {
    event EntrySold(uint256 raffleId, address buyer, uint40 entriesCount, uint208 price);

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.startPrank(user1);
        _createStandardRaffle();

        looksRareRaffle.depositPrizes(1);
        vm.stopPrank();
    }

    function test_enterRaffles() public asPrankedUser(user2) {
        vm.deal(user2, 1 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 1, price: 0.025 ether});

        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

        assertEq(user2.balance, 0.975 ether);
        assertEq(address(looksRareRaffle).balance, 0.025 ether);

        (uint256 amountPaid, uint256 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, 0.025 ether);
        assertEq(entriesCount, 1);
        assertFalse(refunded);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Open);
    }

    function test_enterRaffles_Multiple() public {
        _subscribeRaffleToVRF();

        vm.deal(user2, 1.17 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 10, price: 0.22 ether});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 100, price: 0.95 ether});

        assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Drawing);

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: 1.17 ether}(entries);

        assertEq(user2.balance, 0);
        assertEq(address(looksRareRaffle).balance, 1.17 ether);

        (uint256 amountPaid, uint256 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, 1.17 ether);
        assertEq(entriesCount, 110);
        assertFalse(refunded);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Drawing);
    }

    function testFuzz_enterRaffles_RefundExtraETH(uint256 extra) public asPrankedUser(user2) {
        uint208 price = 0.025 ether;
        vm.assume(extra != 0 && extra < type(uint208).max - price);
        vm.deal(user2, price + extra);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 1, price: price});

        looksRareRaffle.enterRaffles{value: price + extra}(entries);

        assertEq(user2.balance, extra);
        assertEq(address(looksRareRaffle).balance, price);

        (uint256 amountPaid, uint256 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 1);
        assertFalse(refunded);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Open);
    }

    function test_enterRaffles_RevertIf_InvalidIndex() public asPrankedUser(user2) {
        vm.deal(user2, 0.025 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 5});

        vm.expectRevert(IRaffle.InvalidIndex.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);
    }

    function test_enterRaffles_RevertIf_InvalidStatus() public {
        vm.deal(user2, 1 ether);

        // Raffle does not exist
        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 0});

        vm.prank(user2);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

        // Raffle is not open
        vm.prank(user1);
        _createStandardRaffle();

        vm.prank(user2);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);
    }

    function test_enterRaffles_RevertIf_InvalidStatus_StubAllStatuses() public {
        uint256 raffleId = 1;
        vm.deal(user2, 1 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: raffleId, pricingOptionIndex: 0});

        for (uint8 status; status <= uint8(IRaffle.RaffleStatus.Cancelled); status++) {
            if (status != 2) {
                _stubRaffleStatus(raffleId, status);
                vm.prank(user2);
                vm.expectRevert(IRaffle.InvalidStatus.selector);
                looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);
            }
        }
    }

    function test_enterRaffles_RevertIf_CutoffTimeReached() public asPrankedUser(user2) {
        vm.warp(block.timestamp + 86_400 + 1);
        vm.deal(user2, 0.025 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0});

        vm.expectRevert(IRaffle.CutoffTimeReached.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);
    }

    function test_enterRaffles_RevertIf_InsufficientNativeTokensSupplied() public {
        _subscribeRaffleToVRF();

        vm.deal(user2, 0.95 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4});

        vm.expectRevert(IRaffle.InsufficientNativeTokensSupplied.selector);
        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: 0.95 ether}(entries);
    }

    function test_enterRaffles_RevertIf_MaximumEntriesPerParticipantReached() public {
        _subscribeRaffleToVRF();

        vm.deal(user2, 1.9 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4});

        vm.expectRevert(IRaffle.MaximumEntriesPerParticipantReached.selector);
        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: 1.9 ether}(entries);
    }

    function test_enterRaffles_RevertIf_IsMinimumEntriesFixedAndMinimumEntriesReached() public {
        mockERC20.mint(user1, 100_000 ether);
        mockERC721.batchMint(user1, 6, 6);

        vm.startPrank(user1);

        mockERC20.approve(address(looksRareRaffle), 100_000 ether);
        mockERC721.setApprovalForAll(address(looksRareRaffle), true);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        for (uint256 i; i < 6; i++) {
            params.prizes[i].prizeId = i + 6;
        }
        params.isMinimumEntriesFixed = true;
        looksRareRaffle.createRaffle(params);

        looksRareRaffle.depositPrizes(2);

        vm.stopPrank();

        uint256 cost = 1.71 ether;
        vm.deal(user2, cost);

        // 110 entries > minimum entries (107)
        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 4});
        entries[1] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 1});

        vm.prank(user2);
        vm.expectRevert(IRaffle.MaximumEntriesReached.selector);
        looksRareRaffle.enterRaffles{value: cost}(entries);
    }
}
