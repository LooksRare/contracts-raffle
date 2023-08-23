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
        IRaffleV2 raffle = getRaffle(1);

        IRaffleV2.PricingOption[] memory pricingOptions = new IRaffleV2.PricingOption[](4);
        pricingOptions[0] = IRaffleV2.PricingOption({entriesCount: 20, price: 0.024 ether});
        pricingOptions[1] = IRaffleV2.PricingOption({entriesCount: 100, price: 0.11 ether});
        pricingOptions[2] = IRaffleV2.PricingOption({entriesCount: 500, price: 0.525 ether});
        pricingOptions[3] = IRaffleV2.PricingOption({entriesCount: 1_000, price: 0.98 ether});

        address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        address azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
        address elementals = 0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](64);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 4073;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        for (uint256 i = 1; i < 4; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = azuki;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[1].prizeId = 1295;
        prizes[2].prizeId = 6774;
        prizes[3].prizeId = 8758;

        for (uint256 i = 4; i < 64; i++) {
            prizes[i].prizeTier = 2;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = elementals;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[4].prizeId = 18943;
        prizes[5].prizeId = 5922;
        prizes[6].prizeId = 19227;
        prizes[7].prizeId = 10947;
        prizes[8].prizeId = 17226;
        prizes[9].prizeId = 256;
        prizes[10].prizeId = 3560;
        prizes[11].prizeId = 14073;
        prizes[12].prizeId = 9848;
        prizes[13].prizeId = 4600;
        prizes[14].prizeId = 4499;
        prizes[15].prizeId = 8675;
        prizes[16].prizeId = 12251;
        prizes[17].prizeId = 8376;
        prizes[18].prizeId = 19603;
        prizes[19].prizeId = 7152;
        prizes[20].prizeId = 16182;
        prizes[21].prizeId = 8855;
        prizes[22].prizeId = 1809;
        prizes[23].prizeId = 19818;
        prizes[24].prizeId = 16261;
        prizes[25].prizeId = 11776;
        prizes[26].prizeId = 3588;
        prizes[27].prizeId = 17888;
        prizes[28].prizeId = 7234;
        prizes[29].prizeId = 14325;
        prizes[30].prizeId = 3444;
        prizes[31].prizeId = 11378;
        prizes[32].prizeId = 19003;
        prizes[33].prizeId = 3928;
        prizes[34].prizeId = 12920;
        prizes[35].prizeId = 5652;
        prizes[36].prizeId = 2876;
        prizes[37].prizeId = 8008;
        prizes[38].prizeId = 16315;
        prizes[39].prizeId = 9621;
        prizes[40].prizeId = 11748;
        prizes[41].prizeId = 13665;
        prizes[42].prizeId = 16953;
        prizes[43].prizeId = 14124;
        prizes[44].prizeId = 10998;
        prizes[45].prizeId = 17716;
        prizes[46].prizeId = 12543;
        prizes[47].prizeId = 1077;
        prizes[48].prizeId = 11471;
        prizes[49].prizeId = 426;
        prizes[50].prizeId = 4466;
        prizes[51].prizeId = 12153;
        prizes[52].prizeId = 5140;
        prizes[53].prizeId = 13682;
        prizes[54].prizeId = 3499;
        prizes[55].prizeId = 19843;
        prizes[56].prizeId = 6503;
        prizes[57].prizeId = 1579;
        prizes[58].prizeId = 2282;
        prizes[59].prizeId = 12640;
        prizes[60].prizeId = 3868;
        prizes[61].prizeId = 19760;
        prizes[62].prizeId = 12550;
        prizes[63].prizeId = 13111;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 2 days + 2 hours + 30 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 60_000,
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
