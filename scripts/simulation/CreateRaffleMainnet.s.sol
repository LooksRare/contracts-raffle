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
    function run() external view {
        IRaffle.PricingOption[5] memory pricingOptions;
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.00098 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 20, price: 0.0196 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 100, price: 0.098 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 500, price: 0.49 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 1_000, price: 0.98 ether});

        address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        address azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](4);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffle.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 5151;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        prizes[1].prizeTier = 1;
        prizes[1].prizeType = IRaffle.TokenType.ERC721;
        prizes[1].prizeAddress = azuki;
        prizes[1].prizeId = 2164;
        prizes[1].prizeAmount = 1;
        prizes[1].winnersCount = 1;

        prizes[2].prizeTier = 1;
        prizes[2].prizeType = IRaffle.TokenType.ERC721;
        prizes[2].prizeAddress = azuki;
        prizes[2].prizeId = 6500;
        prizes[2].prizeAmount = 1;
        prizes[2].winnersCount = 1;

        prizes[3].prizeTier = 2;
        prizes[3].prizeType = IRaffle.TokenType.ERC20;
        prizes[3].prizeAddress = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;
        prizes[3].prizeId = 0;
        prizes[3].prizeAmount = 5_000e18;
        prizes[3].winnersCount = 100;

        console2.logBytes(
            abi.encodeCall(
                IRaffle.createRaffle,
                (
                    IRaffle.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 5 days + 6 hours + 2 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 169_000,
                        maximumEntriesPerParticipant: 33_000,
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
