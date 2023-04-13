// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";
import {TestParameters} from "./TestParameters.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle_ClaimFees_Test is TestParameters, TestHelpers {
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
            prizeValue: 1 ether,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricings: pricings
        });

        uint256[] memory prizeIndices = _generatePrizeIndices(7);
        looksRareRaffle.depositPrizes({raffleId: 0, prizeIndices: prizeIndices});
        vm.stopPrank();
    }

    function test_claimFees() public {
        for (uint256 i; i < 107; ) {
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

        vm.startPrank(SUBSCRIPTION_ADMIN);
        VRFCoordinatorV2Interface(VRF_COORDINATOR).addConsumer(SUBSCRIPTION_ID, address(looksRareRaffle));
        looksRareRaffle.drawWinners(0);
        vm.stopPrank();

        uint256[] memory randomWords = _generateRandomWordsForRaffleWith11Winners();

        vm.prank(VRF_COORDINATOR);
        VRFConsumerBaseV2(address(looksRareRaffle)).rawFulfillRandomWords(FULFILL_RANDOM_WORDS_REQUEST_ID, randomWords);

        (, , , , , , , uint256 claimableFees) = looksRareRaffle.raffles(0);
        assertEq(address(looksRareRaffle).balance, 2.675 ether);
        assertEq(claimableFees, 2.675 ether);
        uint256 raffleOwnerBalance = user1.balance;

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit RaffleStatusUpdated(0, IRaffle.RaffleStatus.Complete);

        vm.expectEmit({checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true});
        emit FeesClaimed(0, user1, 2.54125 ether);

        looksRareRaffle.claimFees(0);

        (, , , , , , , claimableFees) = looksRareRaffle.raffles(0);
        assertEq(address(looksRareRaffle).balance, 0.13375 ether);
        assertEq(claimableFees, 0);
        assertEq(user1.balance, raffleOwnerBalance + 2.54125 ether);
        assertEq(looksRareRaffle.protocolFeeRecipientClaimableFees(address(0)), 0.13375 ether);
        assertRaffleStatus(looksRareRaffle, 0, IRaffle.RaffleStatus.Complete);
    }
}
