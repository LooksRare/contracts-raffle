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
        address on1 = 0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949;
        address beanz = 0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949;

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](16);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffle.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 8412;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        for (uint256 i = 1; i < 11; ) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = on1;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                ++i;
            }
        }
        prizes[1].prizeId = 4878;
        prizes[2].prizeId = 4910;
        prizes[3].prizeId = 5023;
        prizes[4].prizeId = 5556;
        prizes[5].prizeId = 6381;
        prizes[6].prizeId = 1801;
        prizes[7].prizeId = 356;
        prizes[8].prizeId = 1239;
        prizes[9].prizeId = 1800;
        prizes[10].prizeId = 4293;

        for (uint256 i = 11; i < 16; ) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = beanz;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                ++i;
            }
        }
        prizes[11].prizeId = 8052;
        prizes[12].prizeId = 8943;
        prizes[13].prizeId = 15081;
        prizes[14].prizeId = 5822;
        prizes[15].prizeId = 19119;

        console2.logBytes(
            abi.encodeCall(
                IRaffle.createRaffle,
                (
                    IRaffle.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 50 hours),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 75_000,
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
