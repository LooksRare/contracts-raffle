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

        address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        address azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
        address elementals = 0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](32);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 8199;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        for (uint256 i = 1; i < 4; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = azuki;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[1].prizeId = 8256;
        prizes[2].prizeId = 5559;
        prizes[3].prizeId = 7167;

        for (uint256 i = 4; i < 32; i++) {
            prizes[i].prizeTier = 2;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = elementals;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[4].prizeId = 17322;
        prizes[5].prizeId = 1399;
        prizes[6].prizeId = 5922;
        prizes[7].prizeId = 19175;
        prizes[8].prizeId = 1579;
        prizes[9].prizeId = 10689;
        prizes[10].prizeId = 12017;
        prizes[11].prizeId = 15714;
        prizes[12].prizeId = 19642;
        prizes[13].prizeId = 14073;
        prizes[14].prizeId = 16888;
        prizes[15].prizeId = 15847;
        prizes[16].prizeId = 6523;
        prizes[17].prizeId = 3835;
        prizes[18].prizeId = 14901;
        prizes[19].prizeId = 18732;
        prizes[20].prizeId = 12251;
        prizes[21].prizeId = 6830;
        prizes[22].prizeId = 2147;
        prizes[23].prizeId = 18636;
        prizes[24].prizeId = 11174;
        prizes[25].prizeId = 18120;
        prizes[26].prizeId = 884;
        prizes[27].prizeId = 3560;
        prizes[28].prizeId = 3588;
        prizes[29].prizeId = 13985;
        prizes[30].prizeId = 3437;
        prizes[31].prizeId = 14333;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 2 days + 2 hours + 30 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 57_000,
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
