// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_EnterRaffles_Test is TestHelpers {
    Raffle private looksRareRaffle;
    MockERC20 private mockERC20;
    MockERC721 private mockERC721;

    event EntrySold(uint256 raffleId, address buyer, uint256 entriesCount, uint256 price);

    event RaffleStatusUpdated(uint256 raffleId, IRaffle.RaffleStatus status);

    function setUp() public {
        looksRareRaffle = new Raffle(KEY_HASH, SUBSCRIPTION_ID, VRF_COORDINATOR, owner, PROTOCOL_FEE_RECIPIENT, 500);
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));

        vm.startPrank(user1);
        _createStandardRaffle(address(mockERC20), address(mockERC721), looksRareRaffle);

        looksRareRaffle.depositPrizes(0);
        vm.stopPrank();
    }

    function test_enterRaffles() public asPrankedUser(user2) {
        vm.deal(user2, 1 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 0});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit EntrySold({raffleId: 0, buyer: user2, entriesCount: 1, price: 0.025 ether});

        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

        assertEq(user2.balance, 0.975 ether);
        assertEq(address(looksRareRaffle).balance, 0.025 ether);

        (uint256 amountPaid, uint256 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(0, user2);

        assertEq(amountPaid, 0.025 ether);
        assertEq(entriesCount, 1);
        assertFalse(refunded);

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Open);
    }

    function test_enterRaffles_Multiple() public asPrankedUser(user2) {
        vm.deal(user2, 1.17 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 4});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit EntrySold({raffleId: 0, buyer: user2, entriesCount: 10, price: 0.22 ether});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit EntrySold({raffleId: 0, buyer: user2, entriesCount: 100, price: 0.95 ether});

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.ReadyToBeDrawn);

        looksRareRaffle.enterRaffles{value: 1.17 ether}(entries);

        assertEq(user2.balance, 0);
        assertEq(address(looksRareRaffle).balance, 1.17 ether);

        (uint256 amountPaid, uint256 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(0, user2);

        assertEq(amountPaid, 1.17 ether);
        assertEq(entriesCount, 110);
        assertFalse(refunded);

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.ReadyToBeDrawn);
    }

    function test_enterRaffles_RevertIf_InvalidIndex() public asPrankedUser(user2) {
        vm.deal(user2, 0.025 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 5});

        vm.expectRevert(IRaffle.InvalidIndex.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);
    }

    // TODO: use vm.store to mock the raffle status
    function test_enterRaffles_RevertIf_InvalidStatus() public {
        vm.deal(user2, 1 ether);

        // Raffle does not exist
        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingIndex: 0});

        vm.prank(user2);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

        // Raffle is not open
        vm.prank(user1);
        _createStandardRaffle(address(mockERC20), address(mockERC721), looksRareRaffle);

        vm.prank(user2);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);
    }

    function test_enterRaffles_RevertIf_CutoffTimeReached() public asPrankedUser(user2) {
        vm.warp(uint40(block.timestamp + 86_400) + 1);
        vm.deal(user2, 0.025 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 0});

        vm.expectRevert(IRaffle.CutoffTimeReached.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);
    }

    function test_enterRaffles_RevertIf_MaximumEntriesReached() public {
        vm.deal(user2, 0.95 ether);
        vm.deal(user3, 1 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 4});

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: 0.95 ether}(entries);

        vm.startPrank(user3);
        looksRareRaffle.enterRaffles{value: 0.95 ether}(entries);

        entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 0});

        vm.expectRevert(IRaffle.MaximumEntriesReached.selector);
        looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

        vm.stopPrank();
    }

    function test_enterRaffles_RevertIf_InsufficientNativeTokensSupplied() public asPrankedUser(user2) {
        vm.deal(user2, 0.95 ether);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 1});
        entries[1] = IRaffle.EntryCalldata({raffleId: 0, pricingIndex: 4});

        vm.expectRevert(IRaffle.InsufficientNativeTokensSupplied.selector);
        looksRareRaffle.enterRaffles{value: 0.95 ether}(entries);
    }
}
