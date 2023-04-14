// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle_ClaimFees_Test is TestHelpers {
    Raffle private looksRareRaffle;
    MockERC20 private mockERC20;
    MockERC721 private mockERC721;

    event RaffleStatusUpdated(uint256 raffleId, IRaffle.RaffleStatus status);
    event FeesClaimed(uint256 raffleId, address recipient, uint256 amount);

    function setUp() public {
        vm.createSelectFork("sepolia", 3_269_983);

        looksRareRaffle = new Raffle(KEY_HASH, SUBSCRIPTION_ID, VRF_COORDINATOR, owner, PROTOCOL_FEE_RECIPIENT, 500);
        mockERC20 = new MockERC20();
        mockERC721 = new MockERC721();

        _mintStandardRafflePrizesToRaffleOwnerAndApprove(mockERC20, mockERC721, address(looksRareRaffle));

        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(address(mockERC20), address(mockERC721));
        // Make it 11 winners in total instead of 106 winners for easier testing.
        prizes[6].winnersCount = 5;
        IRaffle.Pricing[5] memory pricings = _generateStandardPricings();

        vm.startPrank(user1);
        looksRareRaffle.createRaffle({
            cutoffTime: block.timestamp + 86_400,
            minimumEntries: 107,
            maximumEntries: 200,
            maximumEntriesPerParticipant: 100,
            prizeValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricings: pricings
        });

        looksRareRaffle.depositPrizes(0);
        vm.stopPrank();
    }

    function test_claimFees() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);

        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        (, , , , , , , , , uint256 claimableFees) = looksRareRaffle.raffles(0);
        assertEq(address(looksRareRaffle).balance, 2.675 ether);
        assertEq(claimableFees, 2.675 ether);
        uint256 raffleOwnerBalance = user1.balance;

        assertEq(PROTOCOL_FEE_RECIPIENT.balance, 0);
        assertEq(looksRareRaffle.protocolFeeRecipientClaimableFees(address(0)), 0);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Complete);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit FeesClaimed(0, user1, 2.54125 ether);

        looksRareRaffle.claimFees(0);

        (, , , , , , , , , claimableFees) = looksRareRaffle.raffles(0);
        assertEq(address(looksRareRaffle).balance, 0.13375 ether);
        assertEq(claimableFees, 0);
        assertEq(user1.balance, raffleOwnerBalance + 2.54125 ether);
        assertEq(looksRareRaffle.protocolFeeRecipientClaimableFees(address(0)), 0.13375 ether);
        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Complete);

        vm.prank(owner);
        looksRareRaffle.claimProtocolFees(address(0));

        // After the raffle fees are claimed, we can receive the protocol fees.
        assertEq(PROTOCOL_FEE_RECIPIENT.balance, 0.13375 ether);
        assertEq(address(looksRareRaffle).balance, 0);
        assertEq(looksRareRaffle.protocolFeeRecipientClaimableFees(address(0)), 0);
    }

    function test_claimFees_RevertIf_InvalidStatus() public {
        _transitionRaffleStatusToDrawing(looksRareRaffle);
        vm.expectRevert(IRaffle.InvalidStatus.selector);
        looksRareRaffle.claimFees(0);
    }
}
