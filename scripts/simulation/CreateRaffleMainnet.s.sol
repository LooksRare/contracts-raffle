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
        pricingOptions[0] = IRaffleV2.PricingOption({entriesCount: 10, price: 0.1 ether});
        pricingOptions[1] = IRaffleV2.PricingOption({entriesCount: 100, price: 1 ether});
        pricingOptions[2] = IRaffleV2.PricingOption({entriesCount: 500, price: 5 ether});
        pricingOptions[3] = IRaffleV2.PricingOption({entriesCount: 1_000, price: 10 ether});

        address nftOne = 0xa589d2bb4FE9B371291C7Ef177A6076Ed1Fb2de8;
        address nftTwo = 0xee726929543222D755145B1063c38eFba87bE601;
        address looks = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

        IRaffleV2.Prize[] memory prizes = new IRaffleV2.Prize[](6);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[0].prizeAddress = nftOne;
        prizes[0].prizeId = 4;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        prizes[1].prizeTier = 1;
        prizes[1].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[1].prizeAddress = nftTwo;
        prizes[1].prizeId = 2;
        prizes[1].prizeAmount = 1;
        prizes[1].winnersCount = 1;

        prizes[2].prizeTier = 1;
        prizes[2].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[2].prizeAddress = nftTwo;
        prizes[2].prizeId = 4;
        prizes[2].prizeAmount = 1;
        prizes[2].winnersCount = 1;

        prizes[3].prizeTier = 1;
        prizes[3].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[3].prizeAddress = nftTwo;
        prizes[3].prizeId = 5;
        prizes[3].prizeAmount = 1;
        prizes[3].winnersCount = 1;

        prizes[4].prizeTier = 1;
        prizes[4].prizeType = IRaffleV2.TokenType.ERC721;
        prizes[4].prizeAddress = nftTwo;
        prizes[4].prizeId = 7;
        prizes[4].prizeAmount = 1;
        prizes[4].winnersCount = 1;

        prizes[5].prizeTier = 2;
        prizes[5].prizeType = IRaffleV2.TokenType.ERC20;
        prizes[5].prizeAddress = looks;
        prizes[5].prizeId = 0;
        prizes[5].prizeAmount = 1 ether;
        prizes[5].winnersCount = 100;

        console2.logBytes(
            abi.encodeCall(
                IRaffleV2.createRaffle,
                (
                    IRaffleV2.CreateRaffleCalldata({
                        cutoffTime: uint40(block.timestamp + 5 days + 6 hours + 2 minutes),
                        isMinimumEntriesFixed: true,
                        minimumEntries: 250,
                        maximumEntriesPerParticipant: 250,
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
