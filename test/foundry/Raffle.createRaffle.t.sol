// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_CreateRaffle_Test is TestHelpers {
    Raffle public looksRareRaffle;
    MockERC20 private mockERC20;
    MockERC721 private mockERC721;

    event RaffleStatusUpdated(uint256 raffleId, IRaffle.RaffleStatus status);

    function setUp() public {
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();
        looksRareRaffle = _deployRaffle();
    }

    function test_createRaffle() public asPrankedUser(user1) {
        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Created);
        _createStandardRaffle(address(mockERC20), address(mockERC721), looksRareRaffle);

        (
            address owner,
            IRaffle.RaffleStatus status,
            uint40 cutoffTime,
            uint40 drawnAt,
            uint40 minimumEntries,
            uint40 maximumEntries,
            uint40 maximumEntriesPerParticipant,
            uint16 minimumProfitBp,
            uint256 prizesTotalValue,
            address feeTokenAddress,
            uint256 claimableFees
        ) = looksRareRaffle.raffles(0);
        assertEq(owner, user1);
        assertEq(uint8(status), uint8(IRaffle.RaffleStatus.Created));
        assertEq(cutoffTime, uint40(block.timestamp + 86_400));
        assertEq(drawnAt, 0);
        assertEq(minimumEntries, 107);
        assertEq(maximumEntries, 200);
        assertEq(maximumEntriesPerParticipant, 200);
        assertEq(prizesTotalValue, 1 ether);
        assertEq(minimumProfitBp, 500);
        assertEq(feeTokenAddress, address(0));
        assertEq(claimableFees, 0);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(0);
        assertEq(winners.length, 0);

        IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(0);
        assertEq(prizes.length, 7);
        for (uint256 i; i < 6; ) {
            assertEq(uint8(prizes[i].prizeType), uint8(IRaffle.TokenType.ERC721));
            if (i == 0) {
                assertEq(prizes[i].prizeTier, 0);
            } else {
                assertEq(prizes[i].prizeTier, 1);
            }
            assertEq(prizes[i].prizeAddress, address(mockERC721));
            assertEq(prizes[i].prizeId, i);
            assertEq(prizes[i].prizeAmount, 1);
            assertEq(prizes[i].winnersCount, 1);
            assertEq(prizes[i].cumulativeWinnersCount, i + 1);
            unchecked {
                ++i;
            }
        }
        assertEq(uint8(prizes[6].prizeType), uint8(IRaffle.TokenType.ERC20));
        assertEq(prizes[6].prizeTier, 2);
        assertEq(prizes[6].prizeAddress, address(mockERC20));
        assertEq(prizes[6].prizeId, 0);
        assertEq(prizes[6].prizeAmount, 1_000 ether);
        assertEq(prizes[6].winnersCount, 100);
        assertEq(prizes[6].cumulativeWinnersCount, 106);

        IRaffle.PricingOption[5] memory pricingOptions = looksRareRaffle.getPricingOptions(0);

        assertEq(pricingOptions[0].entriesCount, 1);
        assertEq(pricingOptions[1].entriesCount, 10);
        assertEq(pricingOptions[2].entriesCount, 25);
        assertEq(pricingOptions[3].entriesCount, 50);
        assertEq(pricingOptions[4].entriesCount, 100);

        assertEq(pricingOptions[0].price, 0.025 ether);
        assertEq(pricingOptions[1].price, 0.22 ether);
        assertEq(pricingOptions[2].price, 0.5 ether);
        assertEq(pricingOptions[3].price, 0.75 ether);
        assertEq(pricingOptions[4].price, 0.95 ether);

        IRaffle.Entry[] memory entries = looksRareRaffle.getEntries(0);
        assertEq(entries.length, 0);
    }

    function test_createRaffle_RevertIf_InvalidMaximumEntriesPerParticipant() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidMaximumEntriesPerParticipant.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 201,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_InvalidPrizeTier() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        prizes[2].prizeTier = 2;

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidPrizeTier.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 200,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_InvalidMinimumProfitBp() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidMinimumProfitBp.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 200,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 10_001,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_InvalidEntriesRange() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        uint8[2] memory maximumEntries = [106, 107];
        for (uint256 i; i < 2; ) {
            vm.expectRevert(IRaffle.InvalidEntriesRange.selector);
            looksRareRaffle.createRaffle({
                cutoffTime: uint40(block.timestamp + 86_400),
                minimumEntries: 107,
                maximumEntries: maximumEntries[i],
                maximumEntriesPerParticipant: 100,
                prizesTotalValue: 1 ether,
                minimumProfitBp: 500,
                feeTokenAddress: address(0),
                prizes: prizes,
                pricingOptions: pricingOptions
            });

            unchecked {
                ++i;
            }
        }
    }

    function testFuzz_createRaffle_RevertIf_InvalidCutoffTime(uint256 lifespan) public {
        vm.assume(lifespan < 86_400);
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidCutoffTime.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + lifespan),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function testFuzz_createRaffle_RevertIf_PrizeIsERC721_InvalidPrizeAmount(uint256 prizeAmount) public {
        vm.assume(prizeAmount != 1);
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        prizes[0].prizeAmount = prizeAmount;

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidPrizeAmount.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function testFuzz_createRaffle_RevertIf_PrizeIsERC721_InvalidWinnersCount(uint40 winnersCount) public {
        vm.assume(winnersCount != 1);
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        prizes[0].winnersCount = winnersCount;

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_PrizeIsERC1155_InvalidPrizeAmount() public {}

    function test_createRaffle_RevertIf_PrizeIsERC1155_InvalidWinnersCount() public {}

    function test_createRaffle_RevertIf_PrizeIsERC20_InvalidPrizeAmount() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        prizes[6].prizeAmount = 0;

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidPrizeAmount.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_PrizeIsERC20_InvalidWinnersCount() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        prizes[6].winnersCount = 0;

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_PrizeIsETH_InvalidPrizeAmount() public {}

    function test_createRaffle_RevertIf_PrizeIsETH_InvalidWinnersCount() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 105,
            maximumEntries: 106,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_CumulativeWinnersCountGreaterThanMaximumNumberOfWinnersPerRaffle()
        public
        asPrankedUser(user1)
    {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        prizes[6].winnersCount = 105; // 1 + 5 + 105 = 111 > 110
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 111,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_PricingEntriesCountIsZero() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();
        pricingOptions[0].entriesCount = 0;

        vm.expectRevert(IRaffle.InvalidEntriesCount.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_PricingPriceIsZero() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();
        pricingOptions[0].price = 0;

        vm.expectRevert(IRaffle.InvalidPrice.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_PricingEntriesCountIsNotGreaterThanLastPricing() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();
        // pricingOptions[1].entriesCount == 10
        pricingOptions[2].entriesCount = 9;

        vm.expectRevert(IRaffle.InvalidEntriesCount.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_PricingPriceIsNotGreaterThanLastPrice() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));

        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();
        // pricingOptions[1].price == 0.22 ether
        pricingOptions[2].price = 0.219 ether;

        vm.expectRevert(IRaffle.InvalidPrice.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }

    function test_createRaffle_RevertIf_PricingInvalidERC20FeeToken() public {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        IRaffle.PricingOption[5] memory pricingOptions = _generateStandardPricings();

        vm.expectRevert(IRaffle.InvalidFeeToken.selector);
        looksRareRaffle.createRaffle({
            cutoffTime: uint40(block.timestamp + 86_400),
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0xA11ce),
            prizes: prizes,
            pricingOptions: pricingOptions
        });
    }
}
