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
        _forkSepolia();

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.prank(user1);
        _createStandardRaffle();
    }

    function test_enterRaffles() public asPrankedUser(user2) {
        uint208 price = 0.025 ether;

        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0, count: 1});

        expectEmitCheckAll();
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 1, price: price});

        looksRareRaffle.enterRaffles{value: price}(entries, address(0));

        assertEq(user2.balance, 0);
        assertEq(address(looksRareRaffle).balance, price);

        (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 1);
        assertFalse(refunded);

        (, , , , , , , , , uint256 claimableFees) = looksRareRaffle.raffles(1);
        assertEq(claimableFees, price);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Open);
    }

    function test_enterRaffles_Multiple() public {
        _subscribeRaffleToVRF();

        uint208 price = 1.39 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1, count: 2});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4, count: 1});

        expectEmitCheckAll();
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 20, price: 0.44 ether});

        expectEmitCheckAll();
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 100, price: 0.95 ether});

        assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Drawing);

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));

        assertEq(user2.balance, 0);
        assertEq(address(looksRareRaffle).balance, price);

        (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 120);
        assertFalse(refunded);

        (, , , , , , , , , uint256 claimableFees) = looksRareRaffle.raffles(1);
        assertEq(claimableFees, price);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Drawing);
    }

    function test_enterRaffles_DelegatedRecipient() public {
        _subscribeRaffleToVRF();

        uint208 price = 1.39 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1, count: 2});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4, count: 1});

        expectEmitCheckAll();
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 20, price: 0.44 ether});

        expectEmitCheckAll();
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 100, price: 0.95 ether});

        assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Drawing);

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, user3);

        assertEq(user2.balance, 0);
        assertEq(address(looksRareRaffle).balance, price);

        (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 0);
        assertFalse(refunded);

        (amountPaid, entriesCount, refunded) = looksRareRaffle.rafflesParticipantsStats(1, user3);

        assertEq(amountPaid, 0);
        assertEq(entriesCount, 120);
        assertFalse(refunded);

        (, , , , , , , , , uint256 claimableFees) = looksRareRaffle.raffles(1);
        assertEq(claimableFees, price);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Drawing);
    }

    function testFuzz_enterRaffles_RefundExtraETH(uint256 extra) public asPrankedUser(user2) {
        uint208 price = 0.025 ether;
        vm.assume(extra != 0 && extra < type(uint208).max - price);
        vm.deal(user2, price + extra);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0, count: 1});

        expectEmitCheckAll();
        emit EntrySold({raffleId: 1, buyer: user2, entriesCount: 1, price: price});

        looksRareRaffle.enterRaffles{value: price + extra}(entries, address(0));

        assertEq(user2.balance, extra);
        assertEq(address(looksRareRaffle).balance, price);

        (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 1);
        assertFalse(refunded);

        (, , , , , , , , , uint256 claimableFees) = looksRareRaffle.raffles(1);
        assertEq(claimableFees, price);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Open);
    }

    function test_enterRaffles_RevertIf_InvalidIndex() public asPrankedUser(user2) {
        uint208 price = 0.025 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 5, count: 1});

        vm.expectRevert(IRaffle.InvalidIndex.selector);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));
    }

    function test_enterRaffles_RevertIf_InvalidCount() public asPrankedUser(user2) {
        uint208 price = 0.025 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0, count: 0});

        vm.expectRevert(IRaffle.InvalidCount.selector);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));
    }

    function test_enterRaffles_RevertIf_InvalidStatus() public {
        uint208 price = 0.025 ether;
        vm.deal(user2, price);

        // Raffle does not exist
        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 0, count: 1});

        vm.prank(user2);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));
    }

    function test_enterRaffles_RevertIf_InvalidStatus_StubAllStatuses() public {
        uint256 raffleId = 1;
        vm.deal(user2, 1 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: raffleId, pricingOptionIndex: 0, count: 1});

        for (uint8 status; status <= uint8(IRaffle.RaffleStatus.Cancelled); status++) {
            if (status != 1) {
                _stubRaffleStatus(raffleId, status);
                vm.prank(user2);
                vm.expectRevert(IRaffle.InvalidStatus.selector);
                looksRareRaffle.enterRaffles{value: 0.025 ether}(entries, address(0));
            }
        }
    }

    function test_enterRaffles_RevertIf_CutoffTimeReached() public asPrankedUser(user2) {
        vm.warp(block.timestamp + 86_400 + 1);

        uint208 price = 0.025 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0, count: 1});

        vm.expectRevert(IRaffle.CutoffTimeReached.selector);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));
    }

    function test_enterRaffles_RevertIf_InsufficientNativeTokensSupplied() public {
        _subscribeRaffleToVRF();

        uint208 price = 0.95 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1, count: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4, count: 1});

        vm.expectRevert(IRaffle.InsufficientNativeTokensSupplied.selector);
        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));
    }

    function test_enterRaffles_RevertIf_MaximumEntriesPerParticipantReached() public {
        _subscribeRaffleToVRF();

        uint208 price = 1.9 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4, count: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 4, count: 1});

        vm.expectRevert(IRaffle.MaximumEntriesPerParticipantReached.selector);
        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));
    }

    function test_enterRaffles_RevertIf_IsMinimumEntriesFixedAndMinimumEntriesReached() public {
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.startPrank(user1);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        for (uint256 i; i < 6; i++) {
            params.prizes[i].prizeId = i + 6;
        }
        params.isMinimumEntriesFixed = true;
        looksRareRaffle.createRaffle(params);

        vm.stopPrank();

        uint256 price = 1.71 ether;
        vm.deal(user2, price);

        // 110 entries > minimum entries (107)
        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 4, count: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 1, count: 1});

        vm.prank(user2);
        vm.expectRevert(IRaffle.MaximumEntriesReached.selector);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));
    }
}
