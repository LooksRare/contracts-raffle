// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle_FeeTokenAddressIsERC20_Test is TestHelpers {
    MockERC20 private feeToken;

    event FeesClaimed(uint256 raffleId, uint256 amount);

    function setUp() public {
        _forkSepolia();

        _deployRaffle();
        _mintStandardRafflePrizesToRaffleOwnerAndApprove();
        feeToken = new MockERC20();

        address[] memory currencies = new address[](1);
        currencies[0] = address(feeToken);
        vm.prank(owner);
        looksRareRaffle.updateCurrenciesStatus(currencies, true);

        IRaffle.CreateRaffleCalldata memory params = _baseCreateRaffleParams(address(mockERC20), address(mockERC721));
        params.feeTokenAddress = address(feeToken);

        vm.prank(user1);
        looksRareRaffle.createRaffle(params);
    }

    function test_claimFees() public {
        _subscribeRaffleToVRF();

        for (uint256 i; i < 107; i++) {
            address participant = address(uint160(i + 1));

            uint256 price = 0.025 ether;

            deal(address(feeToken), participant, price);

            IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
            entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0, count: 1});

            vm.startPrank(participant);
            feeToken.approve(address(looksRareRaffle), price);
            looksRareRaffle.enterRaffles(entries, address(0));
            vm.stopPrank();
        }

        _fulfillRandomWords();

        looksRareRaffle.selectWinners(FULFILL_RANDOM_WORDS_REQUEST_ID);

        (, , , , , , , , , uint256 claimableFees) = looksRareRaffle.raffles(1);
        assertEq(feeToken.balanceOf(address(looksRareRaffle)), 2.675 ether);
        assertEq(claimableFees, 2.675 ether);
        uint256 raffleOwnerBalance = feeToken.balanceOf(user1);

        assertEq(feeToken.balanceOf(address(protocolFeeRecipient)), 0);

        assertRaffleStatusUpdatedEventEmitted(1, IRaffle.RaffleStatus.Complete);

        expectEmitCheckAll();
        emit FeesClaimed(1, 2.54125 ether);

        vm.prank(user1);
        looksRareRaffle.claimFees(1);

        (, , , , , , , , , claimableFees) = looksRareRaffle.raffles(1);
        assertEq(claimableFees, 0);
        assertEq(feeToken.balanceOf(user1), raffleOwnerBalance + 2.54125 ether);
        assertEq(feeToken.balanceOf(address(protocolFeeRecipient)), 0.13375 ether);
        assertRaffleStatus(looksRareRaffle, 1, IRaffle.RaffleStatus.Complete);
    }
}
