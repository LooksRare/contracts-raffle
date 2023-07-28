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
        pricingOptions[0] = IRaffleV2.PricingOption({entriesCount: 20, price: 420 ether});
        pricingOptions[1] = IRaffleV2.PricingOption({entriesCount: 100, price: 1_900 ether});
        pricingOptions[2] = IRaffleV2.PricingOption({entriesCount: 500, price: 9_000 ether});
        pricingOptions[3] = IRaffleV2.PricingOption({entriesCount: 1_000, price: 16_000 ether});

        address azuki = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
        address beans = 0x3Af2A97414d1101E2107a70E7F33955da1346305;
        address looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](6);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[0].prizeAddress = azuki;
        prizes[0].prizeId = 8_631;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        prizes[1].prizeTier = 1;
        prizes[1].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[1].prizeAddress = beans;
        prizes[1].prizeId = 10_176;
        prizes[1].prizeAmount = 1;
        prizes[1].winnersCount = 1;

        prizes[2].prizeTier = 1;
        prizes[2].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[2].prizeAddress = beans;
        prizes[2].prizeId = 15_739;
        prizes[2].prizeAmount = 1;
        prizes[2].winnersCount = 1;

        prizes[3].prizeTier = 1;
        prizes[3].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[3].prizeAddress = beans;
        prizes[3].prizeId = 16_496;
        prizes[3].prizeAmount = 1;
        prizes[3].winnersCount = 1;

        prizes[4].prizeTier = 1;
        prizes[4].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[4].prizeAddress = beans;
        prizes[4].prizeId = 19_775;
        prizes[4].prizeAmount = 1;
        prizes[4].winnersCount = 1;

        prizes[5].prizeTier = 2;
        prizes[5].prizeType = IRaffleV2.TokenType.ERC20;
        prizes[5].prizeAddress = looks;
        prizes[5].prizeId = 0;
        prizes[5].prizeAmount = 500e18;
        prizes[5].winnersCount = 100;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 2 days),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 25_000,
                        maximumEntriesPerParticipant: 5_000,
                        protocolFeeBp: 0,
                        feeTokenAddress: looks,
                        prizes: prizes,
                        pricingOptions: pricingOptions
                    })
                )
            )
        );
    }
}
