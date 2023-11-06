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

        address captainz = 0x769272677faB02575E84945F03Eca517ACc544Cc;
        address potatoz = 0x39ee2c7b3cb80254225884ca001F57118C8f21B6;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](13);

        for (uint256 i = 0; i <= 2; i++) {
            prizes[i].prizeTier = 0;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = captainz;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[0].prizeId = 7391;
        prizes[1].prizeId = 7971;
        prizes[2].prizeId = 9020;

        for (uint256 i = 3; i <= 12; i++) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffleV2.TokenType.ERC721;
            prizes[i].prizeAddress = potatoz;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;
        }

        prizes[3].prizeId = 2497;
        prizes[4].prizeId = 2875;
        prizes[5].prizeId = 2998;
        prizes[6].prizeId = 4088;
        prizes[7].prizeId = 5029;
        prizes[8].prizeId = 5589;
        prizes[9].prizeId = 8229;
        prizes[10].prizeId = 8818;
        prizes[11].prizeId = 9010;
        prizes[12].prizeId = 9714;

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
