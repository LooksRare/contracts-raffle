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

        // address azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
        // address elementals = 0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e;
        // address beanz = 0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949;
        address pudgy = 0xBd3531dA5CF5857e7CfAA92426877b022e612cf8;
        address lilPudgy = 0x524cAB2ec69124574082676e6F654a18df49A048;
        address rods = 0x062E691c2054dE82F28008a8CCC6d7A1c8ce060D;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](21);

        for (uint256 i = 0; i <= 2; i++) {
            prizes[i].prizeTier = 0;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = pudgy;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[0].prizeId = 8488;

        for (uint256 i = 1; i <= 10; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = lilPudgy;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[1].prizeId = 994;
        prizes[2].prizeId = 2418;
        prizes[3].prizeId = 5476;
        prizes[4].prizeId = 9381;
        prizes[5].prizeId = 9558;
        prizes[6].prizeId = 11928;
        prizes[7].prizeId = 12023;
        prizes[8].prizeId = 15455;
        prizes[9].prizeId = 17612;
        prizes[10].prizeId = 21105;

        for (uint256 i = 11; i <= 20; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = rods;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[11].prizeId = 194;
        prizes[12].prizeId = 341;
        prizes[13].prizeId = 2088;
        prizes[14].prizeId = 2921;
        prizes[15].prizeId = 4101;
        prizes[16].prizeId = 5339;
        prizes[17].prizeId = 5871;
        prizes[18].prizeId = 7110;
        prizes[19].prizeId = 7152;
        prizes[20].prizeId = 7187;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 3 days + 2 hours + 30 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 33_000,
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
