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
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.00165 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 100, price: 0.15 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 250, price: 0.325 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 500, price: 0.55 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 1_000, price: 0.98 ether});

        address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        address azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
        address looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](7);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffle.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 5368;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        for (uint256 i = 1; i < 6; ) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = azuki;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                ++i;
            }
        }
        prizes[1].prizeId = 8702;
        prizes[2].prizeId = 5882;
        prizes[3].prizeId = 3720;
        prizes[4].prizeId = 3113;
        prizes[5].prizeId = 9957;

        prizes[6].prizeTier = 2;
        prizes[6].prizeType = IRaffle.TokenType.ERC20;
        prizes[6].prizeAddress = address(looks);
        prizes[6].prizeAmount = 1_000e18;
        prizes[6].winnersCount = 100;

        console2.logBytes(
            abi.encodeCall(
                IRaffle.createRaffle,
                (
                    IRaffle.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 1 days + 5 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 150_000,
                        maximumEntriesPerParticipant: 7_500,
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
