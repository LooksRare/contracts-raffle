// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";
import {Null} from "./mock/Null.sol";

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
            uint16 protocolFeeBp,
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
        assertEq(protocolFeeBp, 500);
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
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.maximumEntriesPerParticipant = params.maximumEntries + 1;

        vm.expectRevert(IRaffle.InvalidMaximumEntriesPerParticipant.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_InvalidPrizesCount_TooManyPrizes() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes = new IRaffle.Prize[](21);

        vm.expectRevert(IRaffle.InvalidPrizesCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_InvalidPrizeTier() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[2].prizeTier = 2;

        vm.expectRevert(IRaffle.InvalidPrizeTier.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_InvalidMinimumProfitBp() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.minimumProfitBp = 10_001;

        vm.expectRevert(IRaffle.InvalidMinimumProfitBp.selector);
        looksRareRaffle.createRaffle(params);
    }

    function testFuzz_createRaffle_RevertIf_InvalidProtocolFeeBp(uint16 protocolFeeBp) public {
        vm.assume(protocolFeeBp != 500);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.protocolFeeBp = protocolFeeBp;

        vm.expectRevert(IRaffle.InvalidProtocolFeeBp.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_InvalidEntriesRange() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));

        uint8[2] memory maximumEntries = [106, 107];
        for (uint256 i; i < 2; ) {
            params.maximumEntries = maximumEntries[i];
            params.maximumEntriesPerParticipant = maximumEntries[i];
            vm.expectRevert(IRaffle.InvalidEntriesRange.selector);
            looksRareRaffle.createRaffle(params);

            unchecked {
                ++i;
            }
        }
    }

    function testFuzz_createRaffle_RevertIf_InvalidCutoffTime_TooShort(uint256 lifespan) public {
        vm.assume(lifespan < 86_400);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.cutoffTime = uint40(block.timestamp + lifespan);

        vm.expectRevert(IRaffle.InvalidCutoffTime.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_InvalidPrizesCount_ZeroPrizes() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes = new IRaffle.Prize[](0);

        vm.expectRevert(IRaffle.InvalidPrizesCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function testFuzz_createRaffle_RevertIf_InvalidCutoffTime_TooLong(uint256 lifespan) public {
        vm.assume(lifespan > 86_400 * 7);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.cutoffTime = uint40(block.timestamp + lifespan);

        vm.expectRevert(IRaffle.InvalidCutoffTime.selector);
        looksRareRaffle.createRaffle(params);
    }

    function testFuzz_createRaffle_RevertIf_PrizeIsERC721_InvalidPrizeAmount(uint256 prizeAmount) public {
        vm.assume(prizeAmount != 1);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[0].prizeAmount = prizeAmount;

        vm.expectRevert(IRaffle.InvalidPrizeAmount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function testFuzz_createRaffle_RevertIf_PrizeIsERC721_InvalidWinnersCount(uint40 winnersCount) public {
        vm.assume(winnersCount != 1);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[0].winnersCount = winnersCount;

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PrizeIsERC1155_InvalidPrizeAmount() public {}

    function test_createRaffle_RevertIf_PrizeIsERC1155_InvalidWinnersCount() public {}

    function test_createRaffle_RevertIf_PrizeIsERC20_InvalidPrizeAmount() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[6].prizeAmount = 0;

        vm.expectRevert(IRaffle.InvalidPrizeAmount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PrizeIsERC20_InvalidWinnersCount() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[6].winnersCount = 0;

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PrizeIsETH_InvalidPrizeAmount() public {}

    function test_createRaffle_RevertIf_PrizeIsETH_InvalidWinnersCount() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.minimumEntries = 105;
        params.maximumEntries = 106;
        params.maximumEntriesPerParticipant = 100;

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_CumulativeWinnersCountGreaterThanMaximumNumberOfWinnersPerRaffle()
        public
        asPrankedUser(user1)
    {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[6].winnersCount = 105; // 1 + 5 + 105 = 111 > 110

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PricingEntriesCountIsZero() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.pricingOptions[0].entriesCount = 0;

        vm.expectRevert(IRaffle.InvalidEntriesCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PricingPriceIsZero() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.pricingOptions[0].price = 0;

        vm.expectRevert(IRaffle.InvalidPrice.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PricingEntriesCountIsNotGreaterThanLastPricing() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        // params.pricingOptions[1].entriesCount == 10
        params.pricingOptions[2].entriesCount = 9;

        vm.expectRevert(IRaffle.InvalidEntriesCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PricingPriceIsNotGreaterThanLastPrice() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        // params.pricingOptions[1].price == 0.22 ether
        params.pricingOptions[2].price = 0.219 ether;

        vm.expectRevert(IRaffle.InvalidPrice.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PricingInvalidERC20FeeToken() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.feeTokenAddress = address(0xA11ce);

        vm.expectRevert(IRaffle.InvalidFeeToken.selector);
        looksRareRaffle.createRaffle(params);

        Null nonERC20Contract = new Null();
        params.feeTokenAddress = address(nonERC20Contract);

        vm.expectRevert(IRaffle.InvalidFeeToken.selector);
        looksRareRaffle.createRaffle(params);
    }
}
