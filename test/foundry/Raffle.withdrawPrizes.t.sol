// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_WithdrawPrizes_Test is TestHelpers {
    Raffle private looksRareRaffle;
    MockERC20 private mockERC20;
    MockERC721 private mockERC721;

    event PrizesWithdrawn(uint256 raffleId);

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        looksRareRaffle = new Raffle(KEY_HASH, SUBSCRIPTION_ID, VRF_COORDINATOR, owner, PROTOCOL_FEE_RECIPIENT, 500);
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));

        vm.startPrank(user1);
        _createStandardRaffle(address(mockERC20), address(mockERC721), looksRareRaffle);

        looksRareRaffle.depositPrizes(0);
        vm.stopPrank();
    }

    function test_withdrawPrizes() public {
        _enterRaffles();

        vm.warp(block.timestamp + 86_400 + 1);

        looksRareRaffle.cancel(0);
        looksRareRaffle.withdrawPrizes(0);

        assertEq(mockERC721.balanceOf(user1), 6);
        for (uint256 i; i < 6; ) {
            assertEq(mockERC721.ownerOf(i), user1);
            unchecked {
                ++i;
            }
        }
        assertEq(mockERC20.balanceOf(user1), 100_000 ether);
        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 0);

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.PrizesWithdrawn);
    }

    function test_withdrawPrizes_PrizesAreNotDeposited() public asPrankedUser(user1) {
        /**
         * The tokens should have been deposited by other raffle owners,
         * but we'll just mint them here for simplicity
         * */
        mockERC721.mint(address(looksRareRaffle), 6);
        mockERC721.mint(address(looksRareRaffle), 7);
        mockERC721.mint(address(looksRareRaffle), 8);
        mockERC721.mint(address(looksRareRaffle), 9);
        mockERC721.mint(address(looksRareRaffle), 10);
        mockERC721.mint(address(looksRareRaffle), 11);
        mockERC721.mint(address(looksRareRaffle), 12);
        mockERC20.mint(address(looksRareRaffle), 100_000 ether);

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](7);
        for (uint256 i; i < 6; ) {
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = address(mockERC721);
            prizes[i].prizeId = i + 6;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                i++;
            }
        }
        prizes[6].prizeType = IRaffle.TokenType.ERC20;
        prizes[6].prizeAddress = address(mockERC20);
        prizes[6].prizeAmount = 1_000e18;
        prizes[6].winnersCount = 100;
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

        looksRareRaffle.cancel(1);
        looksRareRaffle.withdrawPrizes(1);

        assertEq(mockERC721.balanceOf(user1), 0);
        assertEq(mockERC20.balanceOf(user1), 0);

        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.PrizesWithdrawn);
    }

    function test_withdrawPrizes_RevertIf_InvalidStatus() public {
        _enterRaffles();
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.withdrawPrizes(0);
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
