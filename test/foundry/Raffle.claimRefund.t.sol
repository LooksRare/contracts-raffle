// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

// TODO: test claimRefund with multiple raffles
contract Raffle_ClaimRefund_Test is TestHelpers {
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

        vm.prank(owner);
        looksRareRaffle.updateCurrencyStatus(address(mockERC20), true);

        vm.startPrank(user1);
        _createStandardRaffle(address(mockERC20), address(mockERC721), looksRareRaffle);

        looksRareRaffle.depositPrizes(0);
        vm.stopPrank();
    }

    function test_claimRefund() public {
        _enterRaffles();

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(0);

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Cancelled);

        _validClaimRefunds();
    }

    function test_claimRefund_RevertIf_InvalidStatus() public {
        _enterRaffles();

        for (uint256 i = 10; i < 109; ) {
            address participant = address(uint160(i + 1));

            vm.expectRevert(IRaffle.InvalidStatus.selector);
            vm.prank(participant);
            looksRareRaffle.claimRefund(new uint256[](1));

            unchecked {
                ++i;
            }
        }
    }

    function test_claimRefund_RevertIf_AlreadyRefunded() public {
        _enterRaffles();

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(0);

        _validClaimRefunds();

        for (uint256 i = 10; i < 109; ) {
            address participant = address(uint160(i + 1));

            vm.expectRevert(IRaffle.AlreadyRefunded.selector);
            vm.prank(participant);
            looksRareRaffle.claimRefund(new uint256[](1));

            unchecked {
                ++i;
            }
        }
    }

    function _enterRaffles() private {
        // 1 entry short of the minimum, starting with 10 to skip the precompile contracts
        for (uint256 i = 10; i < 109; ) {
            address participant = address(uint160(i + 1));

            vm.deal(participant, 0.025 ether);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            entries[0] = IRaffle.EntryCalldata({raffleId: 0, pricingOptionIndex: 0});

            vm.prank(participant);
            looksRareRaffle.enterRaffles{value: 0.025 ether}(entries);

            unchecked {
                ++i;
            }
        }
    }

    function _validClaimRefunds() private {
        for (uint256 i = 10; i < 109; ) {
            address participant = address(uint160(i + 1));

            vm.prank(participant);
            looksRareRaffle.claimRefund(new uint256[](1));

            assertEq(participant.balance, 0.025 ether);

            (uint256 amountPaid, uint256 entriesCount, bool refunded) = looksRareRaffle.rafflesParticipantsStats(
                0,
                participant
            );

            assertEq(amountPaid, 0.025 ether);
            assertEq(entriesCount, 1);
            assertTrue(refunded);

            unchecked {
                ++i;
            }
        }

        assertEq(address(looksRareRaffle).balance, 0);
    }
}
