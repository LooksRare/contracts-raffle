// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_Rollover_Test is TestHelpers {
    function setUp() public {
        _forkSepolia();

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.prank(user1);
        _createStandardRaffle();
    }

    function test_rollover() public {
        uint256 price = 0.22 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1, count: 1});

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        _createOpenRaffle();

        uint256[] memory refundableRaffleIds = new uint256[](1);
        refundableRaffleIds[0] = 1;

        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 1, count: 1});

        vm.prank(user2);
        looksRareRaffle.rollover(refundableRaffleIds, entries, address(0));

        (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 10);
        assertTrue(refunded);

        (amountPaid, entriesCount, refunded) = looksRareRaffle.rafflesParticipantsStats(2, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 10);
        assertFalse(refunded);

        assertEq(user2.balance, 0);
    }

    function test_rollover_RolloverAmountGreaterThanExpectedAmount() public {
        uint256 price = 0.22 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1, count: 1});

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        _createOpenRaffle();

        uint256[] memory refundableRaffleIds = new uint256[](1);
        refundableRaffleIds[0] = 1;

        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 0, count: 1});

        vm.prank(user2);
        looksRareRaffle.rollover(refundableRaffleIds, entries, address(0));

        (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 10);
        assertTrue(refunded);

        (amountPaid, entriesCount, refunded) = looksRareRaffle.rafflesParticipantsStats(2, user2);

        assertEq(amountPaid, 0.025 ether);
        assertEq(entriesCount, 1);
        assertFalse(refunded);

        assertEq(user2.balance, 0.195 ether);
    }

    function test_rollover_ExpectedAmountGreaterThanRolloverAmount() public {
        uint256 price = 0.22 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1, count: 1});

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        _createOpenRaffle();

        uint256[] memory refundableRaffleIds = new uint256[](1);
        refundableRaffleIds[0] = 1;

        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 2, count: 1});

        vm.deal(user2, 0.28 ether);

        vm.prank(user2);
        looksRareRaffle.rollover{value: 0.28 ether}(refundableRaffleIds, entries, address(0));

        (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 10);
        assertTrue(refunded);

        (amountPaid, entriesCount, refunded) = looksRareRaffle.rafflesParticipantsStats(2, user2);

        assertEq(amountPaid, 0.5 ether);
        assertEq(entriesCount, 25);
        assertFalse(refunded);

        assertEq(user2.balance, 0);
    }

    function test_rollover_RevertIf_InvalidCurrency() public {
        uint256 price = 0.22 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1, count: 1});

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        for (uint256 i; i < 6; i++) {
            params.prizes[i].prizeId = i + 6;
        }
        params.feeTokenAddress = address(mockERC20);
        vm.prank(user1);
        looksRareRaffle.createRaffle(params);

        uint256[] memory refundableRaffleIds = new uint256[](1);
        refundableRaffleIds[0] = 1;

        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 1, count: 1});

        vm.prank(user2);
        vm.expectRevert(IRaffle.InvalidCurrency.selector);
        looksRareRaffle.rollover(refundableRaffleIds, entries, address(0));

        assertEq(user2.balance, 0);
    }

    function _createOpenRaffle() private {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        for (uint256 i; i < 6; i++) {
            params.prizes[i].prizeId = i + 6;
        }
        vm.prank(user1);
        looksRareRaffle.createRaffle(params);
    }
}
