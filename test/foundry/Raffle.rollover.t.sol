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
        uint256 price = 0.025 ether;
        vm.deal(user2, price);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0, count: 1});

        vm.prank(user2);
        looksRareRaffle.enterRaffles{value: price}(entries, address(0));

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        for (uint256 i; i < 6; i++) {
            params.prizes[i].prizeId = i + 6;
        }
        vm.prank(user1);
        looksRareRaffle.createRaffle(params);

        uint256[] memory refundableRaffleIds = new uint256[](1);
        refundableRaffleIds[0] = 1;

        entries[0] = IRaffle.EntryCalldata({raffleId: 2, pricingOptionIndex: 0, count: 1});

        vm.prank(user2);
        looksRareRaffle.rollover(refundableRaffleIds, entries, address(0));

        (uint208 amountPaid, uint40 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(1, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 1);
        assertTrue(refunded);

        (amountPaid, entriesCount, refunded) = looksRareRaffle.rafflesParticipantsStats(2, user2);

        assertEq(amountPaid, price);
        assertEq(entriesCount, 1);
        assertFalse(refunded);
    }

    // function test_claimRefund_MultipleRaffles() public {
    //     _mintStandardRafflePrizesToRaffleOwnerAndApprove();

    //     IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
    //     for (uint256 i; i < params.prizes.length; i++) {
    //         params.prizes[i].prizeId = i + 6;
    //     }
    //     vm.prank(user1);
    //     looksRareRaffle.createRaffle(params);

    //     _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(1);
    //     _enterRafflesWithSingleEntryUpToMinimumEntriesMinusOne(2);

    //     vm.warp(block.timestamp + 86_400 + 1);

    //     looksRareRaffle.cancel(1);
    //     looksRareRaffle.cancel(2);

    //     looksRareRaffle.withdrawPrizes(1);

    //     assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Cancelled);
    //     assertRaffleStatus(looksRareRaffle, 2, IRaffle.RaffleStatus.Refundable);

    //     uint256[] memory raffleIds = new uint256[](2);
    //     raffleIds[0] = 1;
    //     raffleIds[1] = 2;
    //     _validClaimRefunds(raffleIds);
    // }
}
