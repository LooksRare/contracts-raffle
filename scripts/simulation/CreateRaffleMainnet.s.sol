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
        // address pudgy = 0xBd3531dA5CF5857e7CfAA92426877b022e612cf8;
        // address lilPudgy = 0x524cAB2ec69124574082676e6F654a18df49A048;
        // address rods = 0x062E691c2054dE82F28008a8CCC6d7A1c8ce060D;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](3);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[0].prizeAddress = azuki;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;
        prizes[0].prizeId = 8_647;

        prizes[1].prizeTier = 1;
        prizes[1].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[1].prizeAddress = elementals;
        prizes[1].prizeAmount = 1;
        prizes[1].winnersCount = 1;
        prizes[1].prizeId = 12_684;

        prizes[2].prizeTier = 2;
        prizes[2].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[2].prizeAddress = beanz;
        prizes[2].prizeAmount = 1;
        prizes[2].winnersCount = 1;
        prizes[2].prizeId = 6_279;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 1 days + 30 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 9_500,
                        maximumEntriesPerParticipant: 2_000,
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
