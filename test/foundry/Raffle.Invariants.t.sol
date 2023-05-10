// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ProtocolFeeRecipient} from "@looksrare/contracts-exchange-v2/contracts/ProtocolFeeRecipient.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC721} from "./mock/MockERC721.sol";
import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC1155} from "./mock/MockERC1155.sol";
import {MockWETH} from "./mock/MockWETH.sol";
import {MockVRFCoordinatorV2} from "./mock/MockVRFCoordinatorV2.sol";

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console2} from "forge-std/console2.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    bool public callsMustBeValid;

    Raffle public looksRareRaffle;
    MockERC721 public erc721;
    MockERC20 public erc20;
    MockERC1155 public erc1155;
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

    uint256 public erc1155TokenId = 69;
    uint256 public ghost_ERC1155_prizesDepositedSum;
    uint256 public ghost_ERC1155_prizesReturnedSum;
    uint256 public ghost_ERC1155_prizesClaimedSum;

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
        console2.log("Fulfill random words", calls["fulfillRandomWords"]);
        console2.log("Select winners", calls["selectWinners"]);
        console2.log("Claim fees", calls["claimFees"]);
        console2.log("Claim prizes", calls["claimPrizes"]);
        console2.log("Claim protocol fees", calls["claimProtocolFees"]);
        console2.log("Cancel", calls["cancel"]);
        console2.log("Cancel after randomness request", calls["cancelAfterRandomnessRequest"]);
        console2.log("Claim refund", calls["claimRefund"]);
        console2.log("Withdraw prizes", calls["withdrawPrizes"]);
        console2.log("-------------------");

        console2.log("Token flow summary:");
        console2.log("-------------------");
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

        console2.log("ERC1155 prizes deposited:", ghost_ERC1155_prizesDepositedSum);
        console2.log("ERC1155 prizes returned:", ghost_ERC1155_prizesReturnedSum);
        console2.log("ERC1155 prizes claimed:", ghost_ERC1155_prizesClaimedSum);
        console2.log("-------------------");
    }

    constructor(
        Raffle _looksRareRaffle,
        MockVRFCoordinatorV2 _vrfCoordinatorV2,
        MockERC721 _erc721,
        MockERC20 _erc20,
        MockERC1155 _erc1155
    ) {
        looksRareRaffle = _looksRareRaffle;
        vrfCoordinatorV2 = _vrfCoordinatorV2;

        erc721 = _erc721;
        erc20 = _erc20;
        erc1155 = _erc1155;

        address[] memory currencies = new address[](1);
        currencies[0] = address(erc20);
        vm.prank(looksRareRaffle.owner());
        looksRareRaffle.updateCurrenciesStatus(currencies, true);

        for (uint256 i; i < 100; i++) {
            actors[i] = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
        }

        callsMustBeValid = vm.envBool("FOUNDRY_INVARIANT_FAIL_ON_REVERT");
    }

    function createRaffle(uint256 seed) public useActor(seed) countCall("createRaffle") {
        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](7);

        uint40 minimumEntries;

        for (uint256 i; i < prizes.length; i++) {
            prizes[i].prizeTier = uint8(i);

            if (seed % 4 == 0) {
                prizes[i].prizeType = IRaffle.TokenType.ETH;
                prizes[i].prizeAddress = ETH;
                prizes[i].prizeAmount = 1 ether;
                prizes[i].winnersCount = 10;
            } else if (seed % 4 == 1) {
                prizes[i].prizeType = IRaffle.TokenType.ERC20;
                prizes[i].prizeAddress = address(erc20);
                prizes[i].prizeAmount = 1 ether;
                prizes[i].winnersCount = 10;
            } else if (seed % 4 == 2) {
                uint256 tokenId = erc721.totalSupply();
                erc721.mint(currentActor, tokenId);
                prizes[i].prizeType = IRaffle.TokenType.ERC721;
                prizes[i].prizeAddress = address(erc721);
                prizes[i].prizeId = tokenId;
                prizes[i].prizeAmount = 1;
                prizes[i].winnersCount = 1;
            } else {
                erc1155.mint(currentActor, erc1155TokenId, 4);
                prizes[i].prizeType = IRaffle.TokenType.ERC1155;
                prizes[i].prizeAddress = address(erc1155);
                prizes[i].prizeId = erc1155TokenId;
                prizes[i].prizeAmount = 2;
                prizes[i].winnersCount = 2;
            }

            minimumEntries += prizes[i].winnersCount;
        }

        minimumEntries = (minimumEntries * 10_500) / 10_000;

        IRaffle.PricingOption[5] memory pricingOptions;
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.025 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 10, price: 0.22 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 25, price: 0.5 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 50, price: 0.75 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 100, price: 0.95 ether});

        if (minimumEntries < pricingOptions[4].entriesCount) {
            minimumEntries = pricingOptions[4].entriesCount;
        }

        IRaffle.CreateRaffleCalldata memory params = IRaffle.CreateRaffleCalldata({
            cutoffTime: uint40(block.timestamp + 86_400),
            isMinimumEntriesFixed: uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(seed))))) % 2 == 0,
            minimumEntries: minimumEntries,
            maximumEntriesPerParticipant: pricingOptions[4].entriesCount,
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
        if (callsMustBeValid && status != IRaffle.RaffleStatus.Created) return;

        uint256 ethValue = _prizesValue(raffleId, IRaffle.TokenType.ETH);
        vm.deal(raffleOwner, ethValue);

        uint256 erc20Value = _prizesValue(raffleId, IRaffle.TokenType.ERC20);
        erc20.mint(raffleOwner, erc20Value);

        uint256 erc1155Value = _prizesValue(raffleId, IRaffle.TokenType.ERC1155);

        vm.startPrank(raffleOwner);
        erc721.setApprovalForAll(address(looksRareRaffle), true);
        erc20.approve(address(looksRareRaffle), erc20Value);
        erc1155.setApprovalForAll(address(looksRareRaffle), true);
        looksRareRaffle.depositPrizes{value: ethValue}(raffleId);
        vm.stopPrank();

        ghost_ETH_prizesDepositedSum += ethValue;
        ghost_ERC20_prizesDepositedSum += erc20Value;
        ghost_ERC1155_prizesDepositedSum += erc1155Value;
    }

    function enterRaffles(uint256 seed) public useActor(seed) countCall("enterRaffles") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        uint256 raffleId = (seed % rafflesCount) + 1;

        (
            ,
            IRaffle.RaffleStatus status,
            bool isMinimumEntriesFixed,
            uint40 cutoffTime,
            ,
            uint40 minimumEntries,
            uint40 maximumEntriesPerParticipant,
            address feeTokenAddress,
            ,

        ) = looksRareRaffle.raffles(raffleId);
        if (callsMustBeValid) {
            if (status != IRaffle.RaffleStatus.Open) return;
            if (block.timestamp >= cutoffTime) return;
        }

        uint256 pricingOptionIndex = seed % 5;
        IRaffle.PricingOption[5] memory pricingOptions = looksRareRaffle.getPricingOptions(raffleId);
        uint208 price = pricingOptions[pricingOptionIndex].price;

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: raffleId, pricingOptionIndex: pricingOptionIndex});

        if (callsMustBeValid) {
            (, uint40 entriesCount, ) = looksRareRaffle.rafflesParticipantsStats(raffleId, currentActor);
            uint40 pricingOptionEntriesCount = pricingOptions[pricingOptionIndex].entriesCount;

            if (entriesCount + pricingOptionEntriesCount > maximumEntriesPerParticipant) return;

            if (isMinimumEntriesFixed) {
                IRaffle.Entry[] memory currentEntries = looksRareRaffle.getEntries(raffleId);
                if (currentEntries.length != 0) {
                    uint40 currentEntryIndex = currentEntries[currentEntries.length - 1].currentEntryIndex;
                    if (currentEntryIndex + pricingOptionEntriesCount >= minimumEntries) return;
                }
            }
        }

        if (feeTokenAddress == ETH) {
            // Pseudorandomly add 1 wei to test refund, not using seed because stack too deep :(
            vm.deal(currentActor, price + (block.timestamp % 2));
            looksRareRaffle.enterRaffles{value: price + (block.timestamp % 2)}(entries);
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
        if (requestId == 0) return;

        requestIdsReadyForWinnersSelection.push(requestId);
    }

    function selectWinners(uint256 seed) public countCall("selectWinners") {
        uint256 requestId;
        if (seed % 2 == 0) {
            uint256 readyCount = requestIdsReadyForWinnersSelection.length;
            if (readyCount == 0) return;

            requestId = requestIdsReadyForWinnersSelection[readyCount - 1];
            requestIdsReadyForWinnersSelection.pop();
        } else {
            // Try with invalid requestId
            requestId = uint256(keccak256(abi.encodePacked(seed)));
        }

        if (callsMustBeValid) {
            (, , uint256 raffleId) = looksRareRaffle.randomnessRequests(requestId);
            (, IRaffle.RaffleStatus status, , , , , , , , ) = looksRareRaffle.raffles(raffleId);
            if (status != IRaffle.RaffleStatus.Drawing) return;
        }

        looksRareRaffle.selectWinners(requestId);
    }

    function claimFees(uint256 raffleId, uint256 seed) public countCall("claimFees") {
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
        if (callsMustBeValid && status != IRaffle.RaffleStatus.Drawn) return;

        address caller = (callsMustBeValid || seed % 2 == 0) ? raffleOwner : actors[bound(seed, 0, 99)];
        vm.prank(caller);
        looksRareRaffle.claimFees(raffleId);

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
        if (callsMustBeValid && status != IRaffle.RaffleStatus.Drawn && status != IRaffle.RaffleStatus.Complete) return;

        IRaffle.Winner[] memory winners = looksRareRaffle.getWinners(raffleId);
        uint256 winnerIndex = seed % winners.length;
        IRaffle.Winner memory winner = winners[winnerIndex];

        if (callsMustBeValid && winner.claimed) return;

        uint256[] memory winnerIndices = new uint256[](1);
        winnerIndices[0] = winnerIndex;

        IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
        claimPrizesCalldata[0].raffleId = raffleId;
        claimPrizesCalldata[0].winnerIndices = winnerIndices;

        address caller = (callsMustBeValid || seed % 2 == 0) ? winner.participant : actors[bound(seed, 0, 99)];
        vm.prank(caller);
        looksRareRaffle.claimPrizes(claimPrizesCalldata);

        IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(raffleId);
        IRaffle.Prize memory prize = prizes[winner.prizeIndex];

        if (prize.prizeType == IRaffle.TokenType.ETH) {
            ghost_ETH_prizesClaimedSum += prize.prizeAmount;
        } else if (prize.prizeType == IRaffle.TokenType.ERC20) {
            ghost_ERC20_prizesClaimedSum += prize.prizeAmount;
        } else if (prize.prizeType == IRaffle.TokenType.ERC1155) {
            ghost_ERC1155_prizesClaimedSum += prize.prizeAmount;
        }
    }

    function claimRefund(uint256 raffleId, uint256 seed) public countCall("claimRefund") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        bound(raffleId, 1, rafflesCount);

        (, IRaffle.RaffleStatus status, , , , , , address feeTokenAddress, , ) = looksRareRaffle.raffles(raffleId);
        if (callsMustBeValid && status != IRaffle.RaffleStatus.Cancelled) return;

        IRaffle.Entry[] memory entries = looksRareRaffle.getEntries(raffleId);
        if (entries.length == 0) return;
        IRaffle.Entry memory entry = entries[seed % entries.length];

        (uint208 amountPaid, , ) = looksRareRaffle.rafflesParticipantsStats(raffleId, entry.participant);

        uint256[] memory raffleIds = new uint256[](1);
        raffleIds[0] = raffleId;

        address caller = (callsMustBeValid || seed % 2 == 0) ? entry.participant : actors[bound(seed, 0, 99)];
        vm.prank(caller);
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
        if (callsMustBeValid && status != IRaffle.RaffleStatus.Created && status != IRaffle.RaffleStatus.Open) return;

        vm.warp(cutoffTime + 1);

        looksRareRaffle.cancel(raffleId);
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
        if (callsMustBeValid && status != IRaffle.RaffleStatus.Drawing) return;

        vm.warp(drawnAt + 1 days + 1 seconds);

        vm.prank(looksRareRaffle.owner());
        looksRareRaffle.cancelAfterRandomnessRequest(raffleId);
    }

    function withdrawPrizes(uint256 raffleId) public countCall("withdrawPrizes") {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        if (rafflesCount == 0) return;

        bound(raffleId, 1, rafflesCount);

        (, IRaffle.RaffleStatus status, , , , , , , , ) = looksRareRaffle.raffles(raffleId);
        if (callsMustBeValid && status != IRaffle.RaffleStatus.Refundable) return;

        vm.prank(looksRareRaffle.owner());
        looksRareRaffle.withdrawPrizes(raffleId);

        ghost_ETH_prizesReturnedSum += _prizesValue(raffleId, IRaffle.TokenType.ETH);
        ghost_ERC20_prizesReturnedSum += _prizesValue(raffleId, IRaffle.TokenType.ERC20);
        ghost_ERC1155_prizesReturnedSum += _prizesValue(raffleId, IRaffle.TokenType.ERC1155);
    }

    function _prizesValue(uint256 raffleId, IRaffle.TokenType prizeType) private view returns (uint256 value) {
        if (prizeType == IRaffle.TokenType.ERC721) {
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
        MockERC1155 mockERC1155 = new MockERC1155();

        vrfCoordinatorV2.setRaffle(address(looksRareRaffle));

        handler = new Handler(looksRareRaffle, vrfCoordinatorV2, mockERC721, mockERC20, mockERC1155);
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

    /**
     * Invariant D: For each raffle with an ERC1155 as prizes collection.balanceOf(address(looksRareRaffle), tokenID) >= (∑collection/id prizes deposited) - (∑prizes returned in collection/id + ∑prizes claimed in collection/id)
     */
    function invariant_D() public {
        uint256 rafflesCount = looksRareRaffle.rafflesCount();
        for (uint256 raffleId; raffleId < rafflesCount; raffleId++) {
            (, IRaffle.RaffleStatus status, , , , , , , , ) = looksRareRaffle.raffles(raffleId);
            if (status >= IRaffle.RaffleStatus.Open && status <= IRaffle.RaffleStatus.RandomnessFulfilled) {
                IRaffle.Prize[] memory prizes = looksRareRaffle.getPrizes(raffleId);
                for (uint256 i; i < prizes.length; i++) {
                    IRaffle.Prize memory prize = prizes[i];
                    if (prize.prizeType == IRaffle.TokenType.ERC1155) {
                        assertGe(
                            MockERC1155(prize.prizeAddress).balanceOf(address(looksRareRaffle), prize.prizeId),
                            handler.ghost_ERC1155_prizesDepositedSum() -
                                handler.ghost_ERC1155_prizesReturnedSum() -
                                handler.ghost_ERC1155_prizesClaimedSum()
                        );
                    }
                }
            }
        }
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}
