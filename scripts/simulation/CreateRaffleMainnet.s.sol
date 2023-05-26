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
        IRaffle raffle = getRaffle(1);

        IRaffle.PricingOption[] memory pricingOptions = new IRaffle.PricingOption[](5);
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.00125 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 20, price: 0.024 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 100, price: 0.11 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 500, price: 0.525 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 1_000, price: 0.98 ether});

        address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        address azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
        address kubz = 0xEb2dFC54EbaFcA8F50eFcc1e21A9D100b5AEb349;

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](13);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffle.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 6425;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        prizes[1].prizeTier = 1;
        prizes[1].prizeType = IRaffle.TokenType.ERC721;
        prizes[1].prizeAddress = azuki;
        prizes[1].prizeId = 8766;
        prizes[1].prizeAmount = 1;
        prizes[1].winnersCount = 1;

        for (uint256 i = 2; i < 12; ) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = kubz;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                ++i;
            }
        }
        prizes[2].prizeId = 637;
        prizes[3].prizeId = 8059;
        prizes[4].prizeId = 8061;
        prizes[5].prizeId = 8062;
        prizes[6].prizeId = 8063;
        prizes[7].prizeId = 8064;
        prizes[8].prizeId = 183;
        prizes[9].prizeId = 554;
        prizes[10].prizeId = 556;
        prizes[11].prizeId = 6707;

        prizes[12].prizeTier = 2;
        prizes[12].prizeType = IRaffle.TokenType.ERC20;
        prizes[12].prizeAddress = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;
        prizes[12].prizeAmount = 500e18;
        prizes[12].winnersCount = 98;

        console2.logBytes(
            abi.encodeCall(
                IRaffle.createRaffle,
                (
                    IRaffle.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 50 hours),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 77_000,
                        maximumEntriesPerParticipant: 15_000,
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
