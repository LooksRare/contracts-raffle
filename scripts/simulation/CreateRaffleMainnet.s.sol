// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import "forge-std/console2.sol";

contract CreateRaffleMainnet is Script, SimulationBase {
    function run() external {
        IRaffle raffle = getRaffle(1);

        IRaffle.PricingOption[5] memory pricingOptions;
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.0012 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 20, price: 0.024 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 100, price: 0.11 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 500, price: 0.525 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 1_000, price: 0.98 ether});

        address bayc = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
        address onOne = 0x3bf2922f4520a8BA0c2eFC3D2a1539678DaD5e9D;
        address looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](12);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffle.TokenType.ERC721;
        prizes[0].prizeAddress = bayc;
        prizes[0].prizeId = 4847;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        for (uint256 i = 1; i < 11; ) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = onOne;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                ++i;
            }
        }
        prizes[1].prizeId = 1857;
        prizes[2].prizeId = 5391;
        prizes[3].prizeId = 4770;
        prizes[4].prizeId = 5791;
        prizes[5].prizeId = 5601;
        prizes[6].prizeId = 4960;
        prizes[7].prizeId = 570;
        prizes[8].prizeId = 4377;
        prizes[9].prizeId = 7419;
        prizes[10].prizeId = 4518;

        prizes[11].prizeTier = 2;
        prizes[11].prizeType = IRaffle.TokenType.ERC20;
        prizes[11].prizeAddress = address(looks);
        prizes[11].prizeAmount = 500e18;
        prizes[11].winnersCount = 100;

        console2.logBytes(
            abi.encodeCall(
                IRaffle.createRaffle,
                (
                    IRaffle.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 1 days + 10 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 69_000,
                        maximumEntriesPerParticipant: 14_000,
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
