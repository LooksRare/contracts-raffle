// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_DepositPrizes_Test is TestHelpers {
    Raffle private looksRareRaffle;
    MockERC20 private mockERC20;
    MockERC721 private mockERC721;

    function setUp() public {
        looksRareRaffle = new Raffle(KEY_HASH, SUBSCRIPTION_ID, VRF_COORDINATOR, owner, PROTOCOL_FEE_RECIPIENT, 500);
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));
        _createStandardRaffle(address(mockERC20), address(mockERC721), looksRareRaffle);
    }

    function test_despositPrizes() public asPrankedUser(user1) {
        looksRareRaffle.depositPrizes(0);

        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);
        assertEq(mockERC721.balanceOf(address(looksRareRaffle)), 6);
        for (uint256 i; i < 6; ) {
            assertEq(mockERC721.ownerOf(i), address(looksRareRaffle));
            unchecked {
                ++i;
            }
        }

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Open);
    }

    // TODO: Use vm.store to mock different raffle statuses
    function test_despositPrizes_RevertIf_StatusIsNotCreated() public {
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.depositPrizes(1);
    }

    function test_despositPrizes_RevertIf_PrizesAlreadyDeposited() public asPrankedUser(user1) {
        looksRareRaffle.depositPrizes(0);

        assertEq(mockERC20.balanceOf(user1), 0);
        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);

        mockERC20.mint(user1, 100_000 ether);

        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.depositPrizes(0);

        assertEq(mockERC20.balanceOf(user1), 100_000 ether);
        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);
    }
}
