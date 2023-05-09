// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ProtocolFeeRecipient} from "@looksrare/contracts-exchange-v2/contracts/ProtocolFeeRecipient.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC721} from "./mock/MockERC721.sol";
import {MockERC20} from "./mock/MockERC20.sol";
import {MockWETH} from "./mock/MockWETH.sol";
import {MockVRFCoordinatorV2} from "./mock/MockVRFCoordinatorV2.sol";

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console2} from "forge-std/console2.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    Raffle public looksRareRaffle;
    MockERC721 public erc721;
    MockERC20 public erc20;
    MockVRFCoordinatorV2 public vrfCoordinatorV2;

    address private constant VRF_COORDINATOR_V2 = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    address private constant ETH = address(0);

    uint256 public ghost_ETH_prizesDepositedSum;
    uint256 public ghost_ETH_feesCollectedSum;
    uint256 public ghost_ETH_feesClaimedSum;
    uint256 public ghost_ETH_feesRefundedSum;
    uint256 public ghost_ETH_prizesReturnedSum;
    uint256 public ghost_ETH_prizesClaimedSum;
    uint256 public ghost_ETH_protocolFeesClaimedSum;

    uint256 public ghost_ERC20_prizesDepositedSum;
    uint256 public ghost_ERC20_feesCollectedSum;
    uint256 public ghost_ERC20_feesClaimedSum;
    uint256 public ghost_ERC20_feesRefundedSum;
    uint256 public ghost_ERC20_prizesReturnedSum;
    uint256 public ghost_ERC20_prizesClaimedSum;
    uint256 public ghost_ERC20_protocolFeesClaimedSum;

    address[100] internal actors;
    address internal currentActor;

    mapping(bytes32 => uint256) public calls;

    uint256[] public requestIdsReadyForWinnersSelection;

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, 99)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    function callSummary() external view {
        console2.log("Call summary:");
        console2.log("-------------------");
        console2.log("Create raffle", calls["createRaffle"]);
        console2.log("Deposit prizes", calls["depositPrizes"]);
        console2.log("Enter raffles", calls["enterRaffles"]);
        console2.log("Set protocol fee bp", calls["setProtocolFeeBp"]);
        console2.log("Toggle paused", calls["togglePaused"]);
        console2.log("Fulfill random words", calls["fulfillRandomWords"]);
        console2.log("Select winners", calls["selectWinners"]);
        console2.log("Claim fees", calls["claimFees"]);
        console2.log("Claim prizes", calls["claimPrizes"]);
        console2.log("Claim protocol fees", calls["claimProtocolFees"]);
        console2.log("Cancel", calls["cancel"]);
        console2.log("Cancel after randomness request", calls["cancelAfterRandomnessRequest"]);
        console2.log("Claim refund", calls["claimRefund"]);

        console2.log("ETH prizes deposited:", ghost_ETH_prizesDepositedSum);
        console2.log("ETH fees collected:", ghost_ETH_feesCollectedSum);
        console2.log("ETH fees claimed:", ghost_ETH_feesClaimedSum);
        console2.log("ETH fees refunded:", ghost_ETH_feesRefundedSum);
        console2.log("ETH protocol fees claimed:", ghost_ETH_protocolFeesClaimedSum);
        console2.log("ETH prizes returned:", ghost_ETH_prizesReturnedSum);
        console2.log("ETH prizes claimed:", ghost_ETH_prizesClaimedSum);

        console2.log("ERC20 prizes deposited:", ghost_ERC20_prizesDepositedSum);
        console2.log("ERC20 fees collected:", ghost_ERC20_feesCollectedSum);
        console2.log("ERC20 fees claimed:", ghost_ERC20_feesClaimedSum);
        console2.log("ERC20 fees refunded:", ghost_ERC20_feesRefundedSum);
        console2.log("ERC20 protocol fees claimed:", ghost_ERC20_protocolFeesClaimedSum);
        console2.log("ERC20 prizes returned:", ghost_ERC20_prizesReturnedSum);
        console2.log("ERC20 prizes claimed:", ghost_ERC20_prizesClaimedSum);
    }

    constructor(
        Raffle _looksRareRaffle,
        MockVRFCoordinatorV2 _vrfCoordinatorV2,
        MockERC721 _erc721,
        MockERC20 _erc20
    ) {
        looksRareRaffle = _looksRareRaffle;
        vrfCoordinatorV2 = _vrfCoordinatorV2;
        erc721 = _erc721;

        erc20 = _erc20;

        address[] memory currencies = new address[](1);
        currencies[0] = address(erc20);
        vm.prank(looksRareRaffle.owner());
        looksRareRaffle.updateCurrenciesStatus(currencies, true);

        for (uint256 i; i < 100; i++) {
            actors[i] = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
        }
    }

    function createRaffle(uint256 seed) public useActor(seed) countCall("createRaffle") {
        uint256 erc721TotalSupply = erc721.totalSupply();
        erc721.batchMint(currentActor, erc721TotalSupply, 6);
        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](7);
        for (uint256 i; i < 6; i++) {
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = address(erc721);
            prizes[i].prizeId = erc721TotalSupply + i;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            if (i != 0) {
                prizes[i].prizeTier = 1;
            }
        }

        prizes[6].prizeTier = 2;
        prizes[6].prizeAmount = 1 ether;
        prizes[6].winnersCount = 100;
        if (seed % 2 == 0) {
            prizes[6].prizeType = IRaffle.TokenType.ETH;
            prizes[6].prizeAddress = ETH;
        } else {
            prizes[6].prizeType = IRaffle.TokenType.ERC20;
            prizes[6].prizeAddress = address(erc20);
        }

        IRaffle.PricingOption[5] memory pricingOptions;
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.025 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 10, price: 0.22 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 25, price: 0.5 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 50, price: 0.75 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 100, price: 0.95 ether});

        IRaffle.CreateRaffleCalldata memory params = IRaffle.CreateRaffleCalldata({
            cutoffTime: uint40(block.timestamp + 86_400),
            isMinimumEntriesFixed: false,
            minimumEntries: 107,
            maximumEntriesPerParticipant: 200,
            protocolFeeBp: looksRareRaffle.protocolFeeBp(),
            feeTokenAddress: uint256(keccak256(abi.encodePacked(seed))) % 2 == 0 ? ETH : address(erc20),
            prizes: prizes,
            pricingOptions: pricingOptions
        });

        looksRareRaffle.createRaffle(params);
    }

    function depositPrizes(uint256 raffleId) public countCall("depositPrizes") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        bound(raffleId, 1, rafflesCount);

        (address raffleOwner, IRaffle.RaffleStatus status, , , , , , , , ) = looksRareRaffle.raffles(raffleId);
        if (status != IRaffle.RaffleStatus.Created) return;

        uint256 ethValue = _prizesValue(raffleId, IRaffle.TokenType.ETH);
        vm.deal(raffleOwner, ethValue);

        uint256 erc20Value = _prizesValue(raffleId, IRaffle.TokenType.ERC20);
        erc20.mint(raffleOwner, erc20Value);

        vm.startPrank(raffleOwner);
        erc721.setApprovalForAll(address(looksRareRaffle), true);
        erc20.approve(address(looksRareRaffle), erc20Value);
        looksRareRaffle.depositPrizes{value: ethValue}(raffleId);
        vm.stopPrank();

        ghost_ETH_prizesDepositedSum += ethValue;
        ghost_ERC20_prizesDepositedSum += erc20Value;
    }

    function enterRaffles(uint256 seed) public useActor(seed) countCall("enterRaffles") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        uint256 raffleId = (seed % rafflesCount) + 1;

        (, IRaffle.RaffleStatus status, , , , , , address feeTokenAddress, , ) = looksRareRaffle.raffles(raffleId);
        if (status != IRaffle.RaffleStatus.Open) return;

        uint256 pricingOptionIndex = seed % 5;
        IRaffle.PricingOption[5] memory pricingOptions = looksRareRaffle.getPricingOptions(raffleId);
        uint208 price = pricingOptions[pricingOptionIndex].price;

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: raffleId, pricingOptionIndex: pricingOptionIndex});

        if (feeTokenAddress == ETH) {
            vm.deal(currentActor, price);
            looksRareRaffle.enterRaffles{value: price}(entries);
            ghost_ETH_feesCollectedSum += price;
        } else if (feeTokenAddress == address(erc20)) {
            erc20.mint(currentActor, price);
            erc20.approve(address(looksRareRaffle), price);
            looksRareRaffle.enterRaffles(entries);
            ghost_ERC20_feesCollectedSum += price;
        }
    }

    function fulfillRandomWords(uint256 randomWord) public countCall("fulfillRandomWords") {
        uint256 requestId = vrfCoordinatorV2.fulfillRandomWords(randomWord);
        if (requestId == 0) {
            return;
        }
        requestIdsReadyForWinnersSelection.push(requestId);
    }

    // TODO: Try with invalid request ID
    function selectWinners() public countCall("selectWinners") {
        uint256 readyCount = requestIdsReadyForWinnersSelection.length;
        if (readyCount == 0) {
            return;
        }
        uint256 requestId = requestIdsReadyForWinnersSelection[readyCount - 1];
        requestIdsReadyForWinnersSelection.pop();
        looksRareRaffle.selectWinners(requestId);
    }

    // TODO: try with invalid owner/raffleId/status
    function claimFees(uint256 raffleId) public countCall("claimFees") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        bound(raffleId, 1, rafflesCount);

        (
            address raffleOwner,
            IRaffle.RaffleStatus status,
            ,
            ,
            ,
            ,
            ,
            address feeTokenAddress,
            uint16 protocolFeeBp,
            uint208 claimableFees
        ) = looksRareRaffle.raffles(raffleId);
        if (status != IRaffle.RaffleStatus.Drawn) return;

        vm.prank(raffleOwner);
        looksRareRaffle.claimFees(raffleId);

        // TODO: should claimFees return the claimed fees?
        uint256 protocolFees = (uint256(claimableFees) * uint256(protocolFeeBp)) / 10_000;
        uint256 claimedSum = uint256(claimableFees) - protocolFees;

        if (feeTokenAddress == ETH) {
            ghost_ETH_feesClaimedSum += claimedSum;
        } else if (feeTokenAddress == address(erc20)) {
            ghost_ERC20_feesClaimedSum += claimedSum;
        }
    }

    function claimPrizes(uint256 raffleId, uint256 seed) public countCall("claimPrizes") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        bound(raffleId, 1, rafflesCount);

        (, IRaffle.RaffleStatus status, , , , , , , , ) = looksRareRaffle.raffles(raffleId);
        if (status != IRaffle.RaffleStatus.Drawn && status != IRaffle.RaffleStatus.Complete) return;

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(raffleId);
        uint256 winnerIndex = seed % winners.length;
        IRaffle.Winner memory winner = winners[winnerIndex];

        if (winner.claimed) return;

        uint256[] memory winnerIndices = new uint256[](1);
        winnerIndices[0] = winnerIndex;

        IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
        claimPrizesCalldata[0].raffleId = raffleId;
        claimPrizesCalldata[0].winnerIndices = winnerIndices;

        vm.prank(winner.participant);
        looksRareRaffle.claimPrizes(claimPrizesCalldata);

        IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(raffleId);
        IRaffle.Prize memory prize = prizes[winner.prizeIndex];

        if (prize.prizeType == IRaffle.TokenType.ETH) {
            ghost_ETH_prizesClaimedSum += prize.prizeAmount;
        } else if (prize.prizeType == IRaffle.TokenType.ERC20) {
            ghost_ERC20_prizesClaimedSum += prize.prizeAmount;
        }
    }

    function claimRefund(uint256 raffleId, uint256 seed) public countCall("claimRefund") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        bound(raffleId, 1, rafflesCount);

        (, IRaffle.RaffleStatus status, , , , , , address feeTokenAddress, , ) = looksRareRaffle.raffles(raffleId);
        if (status != IRaffle.RaffleStatus.Cancelled) return;

        IRaffle.Entry[] memory entries = looksRareRaffle.getEntries(raffleId);
        if (entries.length == 0) return;
        IRaffle.Entry memory entry = entries[seed % entries.length];

        (uint208 amountPaid, , ) = looksRareRaffle.rafflesParticipantsStats(raffleId, entry.participant);

        uint256[] memory raffleIds = new uint256[](1);
        raffleIds[0] = raffleId;

        vm.prank(entry.participant);
        looksRareRaffle.claimRefund(raffleIds);

        if (feeTokenAddress == ETH) {
            ghost_ETH_feesRefundedSum += amountPaid;
        } else if (feeTokenAddress == address(erc20)) {
            ghost_ERC20_feesRefundedSum += amountPaid;
        }
    }

    function cancel(uint256 raffleId) public countCall("cancel") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        bound(raffleId, 1, rafflesCount);

        (, IRaffle.RaffleStatus status, , uint40 cutoffTime, , , , , , ) = looksRareRaffle.raffles(raffleId);
        if (status != IRaffle.RaffleStatus.Created && status != IRaffle.RaffleStatus.Open) return;

        vm.warp(cutoffTime + 1);

        looksRareRaffle.cancel(raffleId);

        if (status == IRaffle.RaffleStatus.Open) {
            uint256 ethValue = _prizesValue(raffleId, IRaffle.TokenType.ETH);
            ghost_ETH_prizesReturnedSum += ethValue;

            uint256 erc20Value = _prizesValue(raffleId, IRaffle.TokenType.ERC20);
            ghost_ERC20_prizesReturnedSum += erc20Value;
        }
    }

    function claimProtocolFees(uint256 seed) public countCall("claimProtocolFees") {
        address feeTokenAddress = seed % 2 == 0 ? ETH : address(erc20);
        uint256 claimableProtocolFees = looksRareRaffle.protocolFeeRecipientClaimableFees(feeTokenAddress);
        vm.prank(looksRareRaffle.owner());
        looksRareRaffle.claimProtocolFees(feeTokenAddress);
        if (feeTokenAddress == ETH) {
            ghost_ETH_protocolFeesClaimedSum += claimableProtocolFees;
        } else {
            ghost_ERC20_protocolFeesClaimedSum += claimableProtocolFees;
        }
    }

    function cancelAfterRandomnessRequest(uint256 raffleId) public countCall("cancelAfterRandomnessRequest") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        bound(raffleId, 1, rafflesCount);

        (, IRaffle.RaffleStatus status, , , uint40 drawnAt, , , , , ) = looksRareRaffle.raffles(raffleId);
        if (status != IRaffle.RaffleStatus.Drawing) return;

        vm.warp(drawnAt + 1 days + 1 seconds);

        vm.prank(looksRareRaffle.owner());
        looksRareRaffle.cancelAfterRandomnessRequest(raffleId);
    }

    function setProtocolFeeBp(uint16 protocolFeeBp) public countCall("setProtocolFeeBp") {
        protocolFeeBp = uint16(bound(protocolFeeBp, 0, 2_500));
        vm.prank(looksRareRaffle.owner());
        looksRareRaffle.setProtocolFeeBp(protocolFeeBp);
    }

    function togglePaused() public countCall("togglePaused") {
        // vm.prank(looksRareRaffle.owner());
        // looksRareRaffle.togglePaused();
    }

    function _prizesValue(uint256 raffleId, IRaffle.TokenType prizeType) private view returns (uint256 value) {
        if (prizeType != IRaffle.TokenType.ETH && prizeType != IRaffle.TokenType.ERC20) {
            revert("Invalid token type");
        }

        IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(raffleId);
        for (uint256 i; i < prizes.length; i++) {
            if (prizes[i].prizeType == prizeType) {
                value += prizes[i].prizeAmount * prizes[i].winnersCount;
            }
        }
    }
}

contract Raffle_Invariants is TestHelpers {
    Handler public handler;

    function setUp() public {
        MockVRFCoordinatorV2 vrfCoordinatorV2 = new MockVRFCoordinatorV2();

        MockWETH weth = new MockWETH();

        protocolFeeRecipient = new ProtocolFeeRecipient(address(weth), address(69_420));

        looksRareRaffle = new Raffle(
            address(weth),
            KEY_HASH,
            SUBSCRIPTION_ID,
            address(vrfCoordinatorV2),
            owner,
            address(protocolFeeRecipient),
            500
        );

        mockERC721 = new MockERC721();
        mockERC20 = new MockERC20();

        vrfCoordinatorV2.setRaffle(address(looksRareRaffle));

        handler = new Handler(looksRareRaffle, vrfCoordinatorV2, mockERC721, mockERC20);
        targetContract(address(handler));
        excludeContract(looksRareRaffle.protocolFeeRecipient());
    }

    /**
     * Invariant A: Raffle contract ERC20 balance >= (∑ERC20 prizes deposited + ∑fees paid in ERC20) - (∑fees claimed in ERC20 + ∑fees refunded in ERC20 + ∑prizes returned in ERC20 + ∑prizes claimed in ERC20)
     */

    function invariant_A() public {
        assertGe(
            mockERC20.balanceOf(address(looksRareRaffle)),
            handler.ghost_ERC20_prizesDepositedSum() +
                handler.ghost_ERC20_feesCollectedSum() -
                handler.ghost_ERC20_feesClaimedSum() -
                handler.ghost_ERC20_feesRefundedSum() -
                handler.ghost_ERC20_prizesReturnedSum() -
                handler.ghost_ERC20_prizesClaimedSum() -
                handler.ghost_ERC20_protocolFeesClaimedSum()
        );
    }

    /**
     * Invariant B: Raffle contract ETH balance >= (∑ETH prizes deposited + ∑fees paid in ETH) - (∑fees claimed in ETH + ∑fees refunded in ETH + ∑prizes returned in ETH + ∑prizes claimed in ETH)
     */

    function invariant_B() public {
        assertGe(
            address(looksRareRaffle).balance,
            handler.ghost_ETH_prizesDepositedSum() +
                handler.ghost_ETH_feesCollectedSum() -
                handler.ghost_ETH_feesClaimedSum() -
                handler.ghost_ETH_feesRefundedSum() -
                handler.ghost_ETH_prizesReturnedSum() -
                handler.ghost_ETH_prizesClaimedSum() -
                handler.ghost_ETH_protocolFeesClaimedSum()
        );
    }

    /**
     * Invariant C: For each raffle with an ERC721 token as prize in states Open, Drawing, RandomnessFulfilled, collection.ownerOf(tokenID) == address(looksRareRaffle)
     */
    function invariant_C() public {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        for (uint256 raffleId; raffleId < rafflesCount; raffleId++) {
            (, IRaffle.RaffleStatus status, , , , , , , , ) = looksRareRaffle.raffles(raffleId);
            if (status >= IRaffle.RaffleStatus.Open && status <= IRaffle.RaffleStatus.RandomnessFulfilled) {
                IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(raffleId);
                for (uint256 i; i < prizes.length; i++) {
                    IRaffle.Prize memory prize = prizes[i];
                    if (prize.prizeType == IRaffle.TokenType.ERC721) {
                        assertEq(MockERC721(prize.prizeAddress).ownerOf(prize.prizeId), address(looksRareRaffle));
                    }
                }
            }
        }
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}
