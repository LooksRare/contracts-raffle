// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import "forge-std/console2.sol";

contract CreateRaffleMainnet is Script, SimulationBase {
    function run() external {
        IRaffle raffle = getRaffle(1);

        IRaffle.PricingOption[5] memory pricingOptions;
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.00125 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 20, price: 0.024 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 100, price: 0.11 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 500, price: 0.525 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 1_000, price: 0.98 ether});

        address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        address beanz = 0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949;
        address looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](12);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffle.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 9910;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        for (uint256 i = 1; i < 11; ) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = beanz;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                ++i;
            }
        }
        prizes[1].prizeId = 4847;
        prizes[2].prizeId = 5170;
        prizes[3].prizeId = 7220;
        prizes[4].prizeId = 8052;
        prizes[5].prizeId = 9012;
        prizes[6].prizeId = 12392;
        prizes[7].prizeId = 13799;
        prizes[8].prizeId = 13518;
        prizes[9].prizeId = 14440;
        prizes[10].prizeId = 18038;

        prizes[11].prizeTier = 2;
        prizes[11].prizeType = IRaffle.TokenType.ERC20;
        prizes[11].prizeAddress = address(looks);
        prizes[11].prizeAmount = 1_000e18;
        prizes[11].winnersCount = 99;

        console2.logBytes(
            abi.encodeCall(
                IRaffle.createRaffle,
                (
                    IRaffle.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 40 hours),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 69_000,
                        maximumEntriesPerParticipant: 14_000,
                        protocolFeeBp: 0,
                        feeTokenAddress: address(0),
                        prizes: prizes,
                        pricingOptions: pricingOptions
                    })
                )
            )
        );
    }
}
