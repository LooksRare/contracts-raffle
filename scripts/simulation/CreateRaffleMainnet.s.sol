// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {RaffleV2} from "../../contracts/RaffleV2.sol";
import {IRaffleV2} from "../../contracts/interfaces/IRaffleV2.sol";

interface IERC721 {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

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
        address nakamigos = 0xd774557b647330C91Bf44cfEAB205095f7E6c367;
        address looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](88);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 3815;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        prizes[1].prizeTier = 1;
        prizes[1].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[1].prizeAddress = azuki;
        prizes[1].prizeId = 306;
        prizes[1].prizeAmount = 1;
        prizes[1].winnersCount = 1;

        prizes[2].prizeTier = 1;
        prizes[2].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[2].prizeAddress = azuki;
        prizes[2].prizeId = 2048;
        prizes[2].prizeAmount = 1;
        prizes[2].winnersCount = 1;

        prizes[3].prizeTier = 1;
        prizes[3].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[3].prizeAddress = azuki;
        prizes[3].prizeId = 6716;
        prizes[3].prizeAmount = 1;
        prizes[3].winnersCount = 1;

        for (uint256 i = 4; i < 88; i++) {
            prizes[i].prizeTier = 2;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = nakamigos;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[4].prizeId = 17610;
        prizes[5].prizeId = 19358;
        prizes[6].prizeId = 17433;
        prizes[7].prizeId = 15604;
        prizes[8].prizeId = 2305;
        prizes[9].prizeId = 17945;
        prizes[10].prizeId = 3319;
        prizes[11].prizeId = 8176;
        prizes[12].prizeId = 9902;
        prizes[13].prizeId = 16064;
        prizes[14].prizeId = 14869;
        prizes[15].prizeId = 7947;
        prizes[16].prizeId = 9997;
        prizes[17].prizeId = 5205;
        prizes[18].prizeId = 5319;
        prizes[19].prizeId = 5990;
        prizes[20].prizeId = 3032;
        prizes[21].prizeId = 4380;
        prizes[22].prizeId = 3672;
        prizes[23].prizeId = 5186;
        prizes[24].prizeId = 16347;
        prizes[25].prizeId = 7913;
        prizes[26].prizeId = 19314;
        prizes[27].prizeId = 2639;
        prizes[28].prizeId = 19056;
        prizes[29].prizeId = 15846;
        prizes[30].prizeId = 470;
        prizes[31].prizeId = 10079;
        prizes[32].prizeId = 17528;
        prizes[33].prizeId = 10716;
        prizes[34].prizeId = 16211;
        prizes[35].prizeId = 19798;
        prizes[36].prizeId = 1493;
        prizes[37].prizeId = 4993;
        prizes[38].prizeId = 18949;
        prizes[39].prizeId = 2292;
        prizes[40].prizeId = 2460;
        prizes[41].prizeId = 16240;
        prizes[42].prizeId = 7944;
        prizes[43].prizeId = 1849;
        prizes[44].prizeId = 19294;
        prizes[45].prizeId = 17041;
        prizes[46].prizeId = 18892;
        prizes[47].prizeId = 17956;
        prizes[48].prizeId = 17197;
        prizes[49].prizeId = 1712;
        prizes[50].prizeId = 1900;
        prizes[51].prizeId = 19703;
        prizes[52].prizeId = 19137;
        prizes[53].prizeId = 17548;
        prizes[54].prizeId = 5210;
        prizes[55].prizeId = 3326;
        prizes[56].prizeId = 19883;
        prizes[57].prizeId = 5376;
        prizes[58].prizeId = 6058;
        prizes[59].prizeId = 9933;
        prizes[60].prizeId = 19990;
        prizes[61].prizeId = 8156;
        prizes[62].prizeId = 2342;
        prizes[63].prizeId = 4409;
        prizes[64].prizeId = 9948;
        prizes[65].prizeId = 19433;
        prizes[66].prizeId = 15708;
        prizes[67].prizeId = 16150;
        prizes[68].prizeId = 14453;
        prizes[69].prizeId = 17216;
        prizes[70].prizeId = 7733;
        prizes[71].prizeId = 12401;
        prizes[72].prizeId = 5899;
        prizes[73].prizeId = 10887;
        prizes[74].prizeId = 13781;
        prizes[75].prizeId = 2852;
        prizes[76].prizeId = 14995;
        prizes[77].prizeId = 14828;
        prizes[78].prizeId = 16507;
        prizes[79].prizeId = 2682;
        prizes[80].prizeId = 4435;
        prizes[81].prizeId = 8947;
        prizes[82].prizeId = 6495;
        prizes[83].prizeId = 16132;
        prizes[84].prizeId = 16701;
        prizes[85].prizeId = 18198;
        prizes[86].prizeId = 19000;
        prizes[87].prizeId = 6041;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 2 days + 30 minutes),
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
