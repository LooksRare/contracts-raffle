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
        vm.prank(user1);
        _createStandardRaffle(address(mockERC20), address(mockERC721), looksRareRaffle);
    }

    function test_depositPrizes() public asPrankedUser(user1) {
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

    function test_depositPrizes_PrizesAreETH() public asPrankedUser(user1) {
        vm.deal(user1, 1.5 ether);

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](2);
        prizes[0].prizeType = IRaffle.TokenType.ETH;
        prizes[0].prizeAddress = address(0);
        prizes[0].prizeId = 0;
        prizes[0].prizeAmount = 1 ether;
        prizes[0].winnersCount = 1;
        prizes[1].prizeType = IRaffle.TokenType.ETH;
        prizes[1].prizeAddress = address(0);
        prizes[1].prizeId = 0;
        prizes[1].prizeAmount = 0.5 ether;
        prizes[1].winnersCount = 1;

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        looksRareRaffle.createRaffle({
            cutoffTime: block.timestamp + 86_400,
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 200,
            prizesTotalValue: 1 ether,
            minimumProfitBp: uint16(500),
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });

        looksRareRaffle.depositPrizes{value: 1.5 ether}(1);

        assertEq(user1.balance, 0);
        assertEq(address(looksRareRaffle).balance, 1.5 ether);
        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Open);
    }

    // TODO: Use vm.store to mock different raffle statuses
    function test_depositPrizes_RevertIf_StatusIsNotCreated() public {
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.depositPrizes(1);
    }

    function test_depositPrizes_RevertIf_NotRaffleOwner() public asPrankedUser(user2) {
        vm.expectRevert(IRaffle.NotRaffleOwner.selector);
        looksRareRaffle.depositPrizes(0);
    }

    function test_depositPrizes_RevertIf_PrizesAlreadyDeposited() public asPrankedUser(user1) {
        looksRareRaffle.depositPrizes(0);

        assertEq(mockERC20.balanceOf(user1), 0);
        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);

        mockERC20.mint(user1, 100_000 ether);

        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.depositPrizes(0);

        assertEq(mockERC20.balanceOf(user1), 100_000 ether);
        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);
    }

    function test_depositPrizes_RevertIf_InsufficientNativeTokensSupplied() public asPrankedUser(user1) {
        vm.deal(user1, 1.49 ether);

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](2);
        prizes[0].prizeType = IRaffle.TokenType.ETH;
        prizes[0].prizeAddress = address(0);
        prizes[0].prizeId = 0;
        prizes[0].prizeAmount = 1 ether;
        prizes[0].winnersCount = 1;
        prizes[1].prizeType = IRaffle.TokenType.ETH;
        prizes[1].prizeAddress = address(0);
        prizes[1].prizeId = 0;
        prizes[1].prizeAmount = 0.5 ether;
        prizes[1].winnersCount = 1;

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        looksRareRaffle.createRaffle({
            cutoffTime: block.timestamp + 86_400,
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 200,
            prizesTotalValue: 1 ether,
            minimumProfitBp: uint16(500),
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });

        vm.expectRevert(IRaffle.InsufficientNativeTokensSupplied.selector);
        looksRareRaffle.depositPrizes{value: 1.49 ether}(1);
    }
}
