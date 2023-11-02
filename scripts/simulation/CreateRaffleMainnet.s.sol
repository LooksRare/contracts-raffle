// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {RaffleV2} from "../../contracts/RaffleV2.sol";
import {IRaffleV2} from "../../contracts/interfaces/IRaffleV2.sol";

contract CreateRaffleMainnet is Script, SimulationBase {
    function run() external view {
        IRaffleV2.PricingOption[] memory pricingOptions = new IRaffleV2.PricingOption[](4);
        pricingOptions[0] = IRaffleV2.PricingOption({entriesCount: 20, price: 0.024 ether});
        pricingOptions[1] = IRaffleV2.PricingOption({entriesCount: 100, price: 0.11 ether});
        pricingOptions[2] = IRaffleV2.PricingOption({entriesCount: 500, price: 0.525 ether});
        pricingOptions[3] = IRaffleV2.PricingOption({entriesCount: 1_000, price: 0.98 ether});

        address azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
        address elementals = 0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](13);

        for (uint256 i = 0; i <= 2; i++) {
            prizes[i].prizeTier = 0;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = azuki;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[0].prizeId = 4519;
        prizes[1].prizeId = 7491;
        prizes[2].prizeId = 7428;

        for (uint256 i = 3; i <= 12; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = elementals;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[3].prizeId = 3274;
        prizes[4].prizeId = 4628;
        prizes[5].prizeId = 7453;
        prizes[6].prizeId = 9060;
        prizes[7].prizeId = 10082;
        prizes[8].prizeId = 12298;
        prizes[9].prizeId = 13676;
        prizes[10].prizeId = 13845;
        prizes[11].prizeId = 18187;
        prizes[12].prizeId = 19124;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 3 days + 2 hours + 30 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 23_000,
                        maximumEntriesPerParticipant: 10_000,
                        protocolFeeBp: 500,
                        feeTokenAddress: address(0),
                        prizes: prizes,
                        pricingOptions: pricingOptions
                    })
                )
            )
        );
    }
}
