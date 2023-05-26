// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_CreateRaffle_Test is TestHelpers {
    function setUp() public {
        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();
    }

    function test_createRaffle() public asPrankedUser(user1) {
        assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Open);
        uint256 raffleId = looksRareRaffle.createRaffle(
            _baseCreateRaffleParams(address(mockERC20), address(mockERC721))
        );

        assertEq(raffleId, 1);

        (
            address owner,
            IRaffle.RaffleStatus status,
            bool isMinimumEntriesFixed,
            uint40 cutoffTime,
            uint40 drawnAt,
            uint40 minimumEntries,
            uint40 maximumEntriesPerParticipant,
            address feeTokenAddress,
            uint16 protocolFeeBp,
            uint256 claimableFees
        ) = looksRareRaffle.raffles(1);
        assertEq(owner, user1);
        assertEq(uint8(status), uint8(IRaffle.RaffleStatus.Open));
        assertFalse(isMinimumEntriesFixed);
        assertEq(cutoffTime, uint40(block.timestamp + 86_400));
        assertEq(drawnAt, 0);
        assertEq(minimumEntries, 107);
        assertEq(maximumEntriesPerParticipant, 199);
        assertEq(protocolFeeBp, 500);
        assertEq(feeTokenAddress, address(0));
        assertEq(claimableFees, 0);

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(1);
        assertEq(winners.length, 0);

        IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(1);
        assertEq(prizes.length, 7);
        for (uint256 i; i < 6; i++) {
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
        }
        assertEq(uint8(prizes[6].prizeType), uint8(IRaffle.TokenType.ERC20));
        assertEq(prizes[6].prizeTier, 2);
        assertEq(prizes[6].prizeAddress, address(mockERC20));
        assertEq(prizes[6].prizeId, 0);
        assertEq(prizes[6].prizeAmount, 1_000 ether);
        assertEq(prizes[6].winnersCount, 100);
        assertEq(prizes[6].cumulativeWinnersCount, 106);

        IRaffle.PricingOption[] memory pricingOptions = looksRareRaffle.getPricingOptions(1);

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

        IRaffle.Entry[] memory entries = looksRareRaffle.getEntries(1);
        assertEq(entries.length, 0);

        assertEq(looksRareRaffle.rafflesCount(), 1);

        assertEq(mockERC20.balanceOf(address(looksRareRaffle)), 100_000 ether);
        assertERC721Balance(mockERC721, address(looksRareRaffle), 6);
        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Open);
    }

    function test_createRaffle_PrizesAreETH() public asPrankedUser(user1) {
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
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes = prizes;
        looksRareRaffle.createRaffle{value: 1.5 ether}(params);

        assertEq(user1.balance, 0);
        assertEq(address(looksRareRaffle).balance, 1.5 ether);
        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Open);
    }

    function testFuzz_createRaffle_PrizesAreETH_RefundExtraETH(uint256 extra) public asPrankedUser(user1) {
        uint256 prizesValue = 1.5 ether;
        vm.assume(extra != 0 && extra < type(uint256).max - prizesValue);
        vm.deal(user1, prizesValue + extra);
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
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes = prizes;
        looksRareRaffle.createRaffle{value: prizesValue + extra}(params);

        assertEq(user1.balance, extra);
        assertEq(address(looksRareRaffle).balance, prizesValue);
        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Open);
    }

    function test_createRaffle_RevertIf_InsufficientNativeTokensSupplied() public asPrankedUser(user1) {
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
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes = prizes;

        vm.expectRevert(IRaffle.InsufficientNativeTokensSupplied.selector);
        looksRareRaffle.createRaffle{value: 1.49 ether}(params);
    }

    function test_createRaffle_RevertIf_InvalidPrizesCount_TooManyPrizes() public {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes = new IRaffle.Prize[](21);

        vm.expectRevert(IRaffle.InvalidPrizesCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_InvalidPrizeTier() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[2].prizeTier = 2;

        vm.expectRevert(IRaffle.InvalidPrize.selector);
        looksRareRaffle.createRaffle(params);
    }

    function testFuzz_createRaffle_RevertIf_InvalidProtocolFeeBp(uint16 protocolFeeBp) public {
        vm.assume(protocolFeeBp != 500);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.protocolFeeBp = protocolFeeBp;

        vm.expectRevert(IRaffle.InvalidProtocolFeeBp.selector);
        looksRareRaffle.createRaffle(params);
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

        vm.expectRevert(IRaffle.InvalidPrize.selector);
        looksRareRaffle.createRaffle(params);
    }

    function testFuzz_createRaffle_RevertIf_PrizeIsERC721_InvalidWinnersCount(uint40 winnersCount) public {
        vm.assume(winnersCount != 1);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[0].winnersCount = winnersCount;

        vm.expectRevert(IRaffle.InvalidPrize.selector);
        looksRareRaffle.createRaffle(params);
    }

    // TODO: test ERC1155 prizes
    function test_createRaffle_RevertIf_PrizeIsERC1155_InvalidPrizeAmount() public {}

    function test_createRaffle_RevertIf_PrizeIsERC1155_InvalidWinnersCount() public {}

    function test_createRaffle_RevertIf_PrizeIsERC20_InvalidPrizeAmount() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[6].prizeAmount = 0;

        vm.expectRevert(IRaffle.InvalidPrize.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PrizeIsERC20_InvalidWinnersCount() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.prizes[6].winnersCount = 0;

        vm.expectRevert(IRaffle.InvalidPrize.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PrizeIsETH_InvalidPrizeAmount() public {}

    function test_createRaffle_RevertIf_PrizeIsETH_InvalidWinnersCount() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.minimumEntries = 105;
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

        mockERC20.mint(user1, 5_000e18);
        mockERC20.approve(address(looksRareRaffle), 105_000e18);

        vm.expectRevert(IRaffle.InvalidWinnersCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_NoPricingOptions() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.pricingOptions = new IRaffle.PricingOption[](0);

        vm.expectRevert(IRaffle.InvalidPricingOptionsCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_TooManyPricingOptions() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.pricingOptions = new IRaffle.PricingOption[](6);

        vm.expectRevert(IRaffle.InvalidPricingOptionsCount.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PricingOptionPricingOptionIsMoreExpensiveThanTheLastOne()
        public
        asPrankedUser(user1)
    {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.pricingOptions[1].entriesCount = 2;

        vm.expectRevert(IRaffle.InvalidPricingOption.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PricingOptionPriceIsNotDivisibleByEntriesCount() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.pricingOptions[4].entriesCount = 123;

        vm.expectRevert(IRaffle.InvalidPricingOption.selector);
        looksRareRaffle.createRaffle(params);
    }

    function testFuzz_createRaffle_RevertIf_MinimumEntriesIsNotDivisibleByFirstPricingOptionEntriesCount(
        uint40 entriesCount
    ) public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        vm.assume(entriesCount != 0 && params.minimumEntries % entriesCount != 0);
        params.pricingOptions[0].entriesCount = entriesCount;

        vm.expectRevert(IRaffle.InvalidPricingOption.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_FirstPricingOptionPriceIsZero() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.pricingOptions[0].price = 0;

        vm.expectRevert(IRaffle.InvalidPricingOption.selector);
        looksRareRaffle.createRaffle(params);
    }

    function testFuzz_createRaffle_RevertIf_PricingOptionEntriesCountIsNotDivisibleByFirstPricingOptionEntriesCount(
        uint8 entriesCount
    ) public asPrankedUser(user1) {
        for (uint256 index = 1; index <= 4; index++) {
            IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(
                address(mockERC20),
                address(mockERC721)
            );
            params.pricingOptions[0].entriesCount = 10;
            vm.assume(uint40(entriesCount) % 10 != 0);
            params.pricingOptions[index].entriesCount = uint40(entriesCount);
            vm.expectRevert(IRaffle.InvalidPricingOption.selector);
            looksRareRaffle.createRaffle(params);
        }
    }

    function test_createRaffle_RevertIf_PricingOptionEntriesCountIsNotGreaterThanLastPricing()
        public
        asPrankedUser(user1)
    {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        // params.pricingOptions[1].entriesCount == 10
        params.pricingOptions[2].entriesCount = 9;

        vm.expectRevert(IRaffle.InvalidPricingOption.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_PricingPriceIsNotGreaterThanLastPrice() public asPrankedUser(user1) {
        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        // params.pricingOptions[1].price == 0.22 ether
        params.pricingOptions[2].price = 0.219 ether;

        vm.expectRevert(IRaffle.InvalidPricingOption.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_InvalidCurrency_Fee() public {
        address[] memory currencies = new address[](1);
        currencies[0] = address(mockERC20);

        vm.prank(owner);
        looksRareRaffle.updateCurrenciesStatus(currencies, false);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.feeTokenAddress = address(mockERC20);

        vm.expectRevert(IRaffle.InvalidCurrency.selector);
        looksRareRaffle.createRaffle(params);
    }

    function test_createRaffle_RevertIf_InvalidCurrency_Prize() public {
        address[] memory currencies = new address[](1);
        currencies[0] = address(mockERC20);

        vm.prank(owner);
        looksRareRaffle.updateCurrenciesStatus(currencies, false);

        vm.prank(user1);
        vm.expectRevert(IRaffle.InvalidCurrency.selector);
        looksRareRaffle.createRaffle(_baseCreateRaffleParams(address(mockERC20), address(mockERC721)));
    }
}
