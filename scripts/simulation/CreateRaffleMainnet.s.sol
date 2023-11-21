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
        address beanz = 0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](33);

        for (uint256 i = 0; i <= 2; i++) {
            prizes[i].prizeTier = 0;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = azuki;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[0].prizeId = 7256;
        prizes[1].prizeId = 5105;
        prizes[2].prizeId = 7819;

        for (uint256 i = 3; i <= 12; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = elementals;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[3].prizeId = 724;
        prizes[4].prizeId = 3499;
        prizes[5].prizeId = 5014;
        prizes[6].prizeId = 5257;
        prizes[7].prizeId = 8335;
        prizes[8].prizeId = 9380;
        prizes[9].prizeId = 11776;
        prizes[10].prizeId = 12711;
        prizes[11].prizeId = 16255;
        prizes[12].prizeId = 19174;

        for (uint256 i = 13; i <= 32; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = beanz;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[13].prizeId = 1070;
        prizes[14].prizeId = 1655;
        prizes[15].prizeId = 3822;
        prizes[16].prizeId = 4728;
        prizes[17].prizeId = 4781;
        prizes[18].prizeId = 4797;
        prizes[19].prizeId = 5487;
        prizes[20].prizeId = 5625;
        prizes[21].prizeId = 6318;
        prizes[22].prizeId = 6750;
        prizes[23].prizeId = 7161;
        prizes[24].prizeId = 7353;
        prizes[25].prizeId = 8439;
        prizes[26].prizeId = 8887;
        prizes[27].prizeId = 9471;
        prizes[28].prizeId = 10794;
        prizes[29].prizeId = 15018;
        prizes[30].prizeId = 18000;
        prizes[31].prizeId = 18062;
        prizes[32].prizeId = 18173;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 3 days + 2 hours + 30 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 32_000,
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
