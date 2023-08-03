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
        address looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](6);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 2_511;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        prizes[1].prizeTier = 1;
        prizes[1].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[1].prizeAddress = azuki;
        prizes[1].prizeId = 6_646;
        prizes[1].prizeAmount = 1;
        prizes[1].winnersCount = 1;

        prizes[2].prizeTier = 1;
        prizes[2].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[2].prizeAddress = azuki;
        prizes[2].prizeId = 8_463;
        prizes[2].prizeAmount = 1;
        prizes[2].winnersCount = 1;

        prizes[3].prizeTier = 1;
        prizes[3].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[3].prizeAddress = azuki;
        prizes[3].prizeId = 8_719;
        prizes[3].prizeAmount = 1;
        prizes[3].winnersCount = 1;

        prizes[4].prizeTier = 1;
        prizes[4].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[4].prizeAddress = azuki;
        prizes[4].prizeId = 9_894;
        prizes[4].prizeAmount = 1;
        prizes[4].winnersCount = 1;

        prizes[5].prizeTier = 2;
        prizes[5].prizeType = IRaffleV2.TokenType.ERC20;
        prizes[5].prizeAddress = looks;
        prizes[5].prizeId = 0;
        prizes[5].prizeAmount = 500e18;
        prizes[5].winnersCount = 150;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 5 days + 10 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 55_000,
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
