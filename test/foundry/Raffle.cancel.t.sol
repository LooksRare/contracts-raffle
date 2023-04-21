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

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        looksRareRaffle = _deployRaffle();
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));

        vm.prank(owner);
        looksRareRaffle.updateCurrencyStatus(address(mockERC20), true);

        vm.startPrank(user1);
        looksRareRaffle.createRaffle(_baseCreateRaffleParams(address(mockERC20), address(mockERC721)));

        looksRareRaffle.depositPrizes(1);
        vm.stopPrank();
    }

    // TODO: How do we prevent a user from creating a raffle with deposited NFTs from another raffle?
    function test_cancel_RaffleStatusIsCreated() public asPrankedUser(user2) {
        looksRareRaffle.createRaffle(_baseCreateRaffleParams(address(mockERC20), address(mockERC721)));

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(2, IRaffle.RaffleStatus.Cancelled);

        looksRareRaffle.cancel(2);

        assertRaffleStatus(looksRareRaffle, 2, IRaffle.RaffleStatus.Cancelled);

        assertEq(mockERC721.balanceOf(user2), 0);
        assertEq(mockERC20.balanceOf(user2), 0);

        assertEq(mockERC721.balanceOf(address(looksRareRaffle)), 6);
        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);
    }

    function test_cancel_RaffleStatusIsOpen() public {
        _enterRaffles();
        vm.warp(block.timestamp + 86_400 + 1);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(1, IRaffle.RaffleStatus.Cancelled);

        looksRareRaffle.cancel(1);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Cancelled);

        assertEq(mockERC721.balanceOf(user1), 6);
        for (uint256 i; i < 6; ) {
            assertEq(mockERC721.ownerOf(i), user1);
            unchecked {
                ++i;
            }
        }
        assertEq(mockERC20.balanceOf(user1), 100_000 ether);
    }

    function test_cancel_RevertIf_InvalidStatus() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.cancel(1);
    }

    function test_cancel_RevertIf_CutoffTimeNotReached() public {
        _enterRaffles();
        vm.warp(block.timestamp + 86_399);
        vm.expectRevert(IRaffle.CutoffTimeNotReached.selector);
        looksRareRaffle.cancel(1);
    }

    function _enterRaffles() private {
        // 1 entry short of the minimum, starting with 10 to skip the precompile contracts
        for (uint256 i = 10; i < 116; ) {
            address participant = address(uint160(i + 1));

            vm.deal(participant, 0.025 ether);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0});

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

            unchecked {
                ++i;
            }
        }
    }
}
