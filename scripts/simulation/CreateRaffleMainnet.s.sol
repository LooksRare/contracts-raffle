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
        // address elementals = 0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e;
        address vessel = 0x5b1085136a811e55b2Bb2CA1eA456bA82126A376;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](54);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 9_617;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        for (uint256 i = 1; i < 4; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = azuki;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[1].prizeId = 4_155;
        prizes[2].prizeId = 8_305;
        prizes[3].prizeId = 2_641;

        for (uint256 i = 4; i < 54; i++) {
            prizes[i].prizeTier = 2;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = vessel;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[4].prizeId = 50396;
        prizes[5].prizeId = 95850;
        prizes[6].prizeId = 18091;
        prizes[7].prizeId = 68794;
        prizes[8].prizeId = 62222;
        prizes[9].prizeId = 87239;
        prizes[10].prizeId = 46657;
        prizes[11].prizeId = 63193;
        prizes[12].prizeId = 78483;
        prizes[13].prizeId = 31490;
        prizes[14].prizeId = 73512;
        prizes[15].prizeId = 74793;
        prizes[16].prizeId = 68831;
        prizes[17].prizeId = 20466;
        prizes[18].prizeId = 71509;
        prizes[19].prizeId = 58503;
        prizes[20].prizeId = 78915;
        prizes[21].prizeId = 55268;
        prizes[22].prizeId = 70466;
        prizes[23].prizeId = 46120;
        prizes[24].prizeId = 60251;
        prizes[25].prizeId = 96519;
        prizes[26].prizeId = 72393;
        prizes[27].prizeId = 50773;
        prizes[28].prizeId = 63380;
        prizes[29].prizeId = 95037;
        prizes[30].prizeId = 91029;
        prizes[31].prizeId = 82008;
        prizes[32].prizeId = 21340;
        prizes[33].prizeId = 83035;
        prizes[34].prizeId = 93365;
        prizes[35].prizeId = 94768;
        prizes[36].prizeId = 69859;
        prizes[37].prizeId = 46439;
        prizes[38].prizeId = 95465;
        prizes[39].prizeId = 89137;
        prizes[40].prizeId = 82817;
        prizes[41].prizeId = 90377;
        prizes[42].prizeId = 76079;
        prizes[43].prizeId = 92719;
        prizes[44].prizeId = 95765;
        prizes[45].prizeId = 74740;
        prizes[46].prizeId = 84610;
        prizes[47].prizeId = 86278;
        prizes[48].prizeId = 55483;
        prizes[49].prizeId = 71513;
        prizes[50].prizeId = 95759;
        prizes[51].prizeId = 87927;
        prizes[52].prizeId = 93359;
        prizes[53].prizeId = 72257;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 2 days + 2 hours + 30 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 52_000,
                        maximumEntriesPerParticipant: 15_000,
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
