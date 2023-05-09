// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_WithdrawPrizes_Test is TestHelpers {
    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();

        vm.startPrank(user1);
        looksRareRaffle.createRaffle(_baseCreateRaffleParams(address(mockERC20), address(mockERC721)));

        looksRareRaffle.depositPrizes(1);
        vm.stopPrank();
    }

    function test_withdrawPrizes() public {
        _enterRaffles();
        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(1);

        assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Cancelled);

        looksRareRaffle.withdrawPrizes(1);

        assertEq(mockERC721.balanceOf(user1), 6);
        for (uint256 i; i < 6; i++) {
            assertEq(mockERC721.ownerOf(i), user1);
        }
        assertEq(mockERC20.balanceOf(user1), 100_000 ether);

        // Second withdraw reverts
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.withdrawPrizes(1);
    }

    function test_withdrawPrizes_RevertIf_InvalidStatus() public asPrankedUser(user1) {
        looksRareRaffle.createRaffle(_baseCreateRaffleParams(address(mockERC20), address(mockERC721)));
        looksRareRaffle.cancel(2);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.withdrawPrizes(2);
    }

    function _enterRaffles() private {
        // 1 entry short of the minimum, starting with 10 to skip the precompile contracts
        for (uint256 i = 10; i < 116; i++) {
            address participant = address(uint160(i + 1));

            vm.deal(participant, 0.025 ether);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0});

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);
        }
    }
}
