// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_ClaimRefund_Test is TestHelpers {
    function setUp() public {
        _forkSepolia();

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.prank(user1);
        _createStandardRaffle();
    }

    function test_claimRefund() public {
        _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(1);

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Refundable);

        uint256[] memory raffleIds = new uint256[](1);
        raffleIds[0] = 1;
        _validClaimRefunds(raffleIds);
    }

    function test_claimRefund_DelegatedRecipient() public {
        uint256 price = 0.025 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0, count: 1});

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, user3);

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Refundable);

        uint256[] memory raffleIds = new uint256[](1);
        raffleIds[0] = 1;

        vm.prank(user3);
        looksRareRaffle.claimRefund(raffleIds);
        assertEq(user3.balance, 0);

        assertEq(address(looksRareRaffle).balance, 0.025 ether);

        vm.prank(user2);
        looksRareRaffle.claimRefund(raffleIds);
        assertEq(user2.balance, 0.025 ether);

        assertEq(address(looksRareRaffle).balance, 0);
    }

    function test_claimRefund_MultipleRaffles() public {
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        for (uint256 i; i < params.prizes.length; i++) {
            params.prizes[i].prizeId = i + 6;
        }
        vm.prank(user1);
        looksRareRaffle.createRaffle(params);

        _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(1);
        _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(2);

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);
        looksRareRaffle.cancel(2);

        looksRareRaffle.withdrawPrizes(1);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Cancelled);
        assertRaffleStatus(looksRareRaffle, 2, IRaffle.RaffleStatus.Refundable);

        uint256[] memory raffleIds = new uint256[](2);
        raffleIds[0] = 1;
        raffleIds[1] = 2;
        _validClaimRefunds(raffleIds);
    }

    function test_claimRefund_RevertIf_InvalidStatus() public {
        _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(1);

        for (uint256 i = 10; i < 116; i++) {
            address participant = address(uint160(i + 1));

            uint256[] memory raffleIds = new uint256[](1);
            raffleIds[0] = 1;

            vm.expectRevert(IRaffle.InvalidStatus.selector);
            vm.prank(participant);
            looksRareRaffle.claimRefund(raffleIds);
        }
    }

    function test_claimRefund_RevertIf_AlreadyRefunded() public {
        _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(1);

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        uint256[] memory raffleIds = new uint256[](1);
        raffleIds[0] = 1;
        _validClaimRefunds(raffleIds);

        for (uint256 i = 10; i < 116; i++) {
            address participant = address(uint160(i + 1));

            vm.expectRevert(IRaffle.AlreadyRefunded.selector);
            vm.prank(participant);
            looksRareRaffle.claimRefund(raffleIds);
        }
    }

    function _validClaimRefunds(uint256[] memory raffleIds) private {
        uint256 rafflesCount = raffleIds.length;
        for (uint256 i = 10; i < 116; i++) {
            address participant = address(uint160(i + 1));

            vm.prank(participant);
            looksRareRaffle.claimRefund(raffleIds);
            assertEq(participant.balance, 0.025 ether * rafflesCount);

            for (uint256 j; j < rafflesCount; j++) {
                (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(
                    raffleIds[j],
                    participant
                );

                assertEq(amountPaid, 0.025 ether);
                assertEq(entriesCount, 1);
                assertTrue(refunded);
            }
        }

        assertEq(address(looksRareRaffle).balance, 0);
    }
}
