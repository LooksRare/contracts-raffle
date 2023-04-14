// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {AssertionHelpers} from "./AssertionHelpers.sol";
import {TestParameters} from "./TestParameters.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

abstract contract TestHelpers is AssertionHelpers, TestParameters {
    address public user1 = address(1);
    address public user2 = address(2);
    address public user3 = address(3);
    address public owner = address(69);

    modifier asPrankedUser(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    function _generateStandardPricings() internal pure returns (IRaffle.Pricing[5] memory pricings) {
        pricings[0] = IRaffle.Pricing({entriesCount: 1, price: 0.025 ether});
        pricings[1] = IRaffle.Pricing({entriesCount: 10, price: 0.22 ether});
        pricings[2] = IRaffle.Pricing({entriesCount: 25, price: 0.5 ether});
        pricings[3] = IRaffle.Pricing({entriesCount: 50, price: 0.75 ether});
        pricings[4] = IRaffle.Pricing({entriesCount: 100, price: 0.95 ether});
    }

    /**
     * @dev 1st prize: rare ERC721 (1 winner)
     *      2nd prize: floor ERC721 (5 winners)
     *      3rd prize: 1,000 LOOKS (100 winners)
     */
    function _generateStandardRafflePrizes(address mockERC20, address mockERC721)
        internal
        pure
        returns (IRaffle.Prize[] memory prizes)
    {
        prizes = new IRaffle.Prize[](7);
        for (uint256 i; i < 6; ) {
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = mockERC721;
            prizes[i].prizeId = i;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                i++;
            }
        }
        prizes[6].prizeType = IRaffle.TokenType.ERC20;
        prizes[6].prizeAddress = mockERC20;
        prizes[6].prizeAmount = 1_000e18;
        prizes[6].winnersCount = 100;
    }

    function _generateRandomWordsForRaffleWith11Winners() internal pure returns (uint256[] memory randomWords) {
        randomWords = new uint256[](11);
        randomWords[0] = 5_000; // 5000 % 107 + 1 = 79
        randomWords[1] = 69_42; // 6942 % 107 + 1 = 95
        randomWords[2] = 777; // 777 % 107 + 1 = 29
        randomWords[3] = 55; // 55 % 107 + 1 = 56
        randomWords[4] = 123; // 123 % 107 + 1 = 17
        randomWords[5] = 99; // 99 % 107 + 1 = 100
        randomWords[6] = 9_981; // 9981 % 107 + 1 = 31
        randomWords[7] = 888; // 888 % 107 + 1 = 33
        randomWords[8] = 168; // 168 % 107 + 1 = 62
        randomWords[9] = 4_670; // 4670 % 107 + 1 = 70
        randomWords[10] = 3_14159; // 314159 % 107 + 1 = 8
    }

    function _mintStandardRafflePrizesToRaffleOwnerAndApprove(
        MockERC20 mockERC20,
        MockERC721 mockERC721,
        address looksRareRaffle
    ) internal {
        mockERC20.mint(user1, 100_000 ether);
        mockERC721.batchMint(user1, 6);

        vm.startPrank(user1);
        mockERC20.approve(looksRareRaffle, 100_000 ether);
        mockERC721.setApprovalForAll(looksRareRaffle, true);
        vm.stopPrank();
    }

    function _createStandardRaffle(
        address mockERC20,
        address mockERC721,
        Raffle looksRareRaffle
    ) internal {
        IRaffle.Prize[] memory prizes = _generateStandardRafflePrizes(mockERC20, mockERC721);
        IRaffle.Pricing[5] memory pricings = _generateStandardPricings();

        looksRareRaffle.createRaffle({
            cutoffTime: block.timestamp + 86_400,
            minimumEntries: 107,
            maximumEntries: 200,
            prizeValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricings: pricings
        });
    }

    function _transitionRaffleStatusToDrawing(Raffle looksRareRaffle) internal {
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
    }
}
