// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_DepositPrizes_Test is TestParameters, TestHelpers {
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
        uint256[] memory prizeIndices = _generatePrizeIndices(7);
        looksRareRaffle.depositPrizes({raffleId: 0, prizeIndices: prizeIndices});

        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);
        assertEq(mockERC721.balanceOf(address(looksRareRaffle)), 6);
        for (uint256 i; i < 6; ) {
            assertEq(mockERC721.ownerOf(i), address(looksRareRaffle));
            unchecked {
                ++i;
            }
        }

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Open);

        IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(0);
        for (uint256 i; i < 7; ) {
            assertTrue(prizes[i].deposited);
            unchecked {
                ++i;
            }
        }
    }

    function test_despositPrizes_Separately() public asPrankedUser(user1) {
        uint256[] memory prizeIndices = _generatePrizeIndices(6);
        looksRareRaffle.depositPrizes({raffleId: 0, prizeIndices: prizeIndices});

        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 0);
        assertEq(mockERC721.balanceOf(address(looksRareRaffle)), 6);
        for (uint256 i; i < 6; ) {
            assertEq(mockERC721.ownerOf(i), address(looksRareRaffle));
            unchecked {
                ++i;
            }
        }

        // TODO: Validate prize deposited set to true
        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Created);

        IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(0);
        for (uint256 i; i < 6; ) {
            assertTrue(prizes[i].deposited);
            unchecked {
                ++i;
            }
        }
        assertFalse(prizes[6].deposited);

        uint256[] memory secondPrizeIndices = new uint256[](1);
        secondPrizeIndices[0] = 6;

        looksRareRaffle.depositPrizes({raffleId: 0, prizeIndices: secondPrizeIndices});

        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);

        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Open);

        prizes = looksRareRaffle.getPrizes(0);
        for (uint256 i; i < 7; ) {
            assertTrue(prizes[i].deposited);
            unchecked {
                ++i;
            }
        }
    }

    // TODO: Use vm.store to mock different raffle statuses
    function test_despositPrizes_RevertIf_StatusIsNotCreated() public {
        uint256[] memory prizeIndices = _generatePrizeIndices(7);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.depositPrizes({raffleId: 1, prizeIndices: prizeIndices});
    }

    function test_despositPrizes_RevertIf_InvalidIndex() public {
        uint256[] memory prizeIndices = _generatePrizeIndices(1);
        prizeIndices[0] = 7;
        vm.expectRevert(IRaffle.InvalidIndex.selector);
        looksRareRaffle.depositPrizes({raffleId: 0, prizeIndices: prizeIndices});
    }

    function test_despositPrizes_RevertIf_PrizeAlreadyDeposited() public {}
}
