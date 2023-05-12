// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

interface ITestERC721 {
    function setApprovalForAll(address operator, bool approved) external;
}

interface ITestERC20 {
    function approve(address operator, uint256 amount) external;
}

contract CreateRaffleMainnet is Script, SimulationBase {
    function run() external {
        uint256 chainId = 1;
        uint256 deployerPrivateKey = vm.envUint("MAINNET_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = getRaffle(chainId);

        IRaffle.PricingOption[5] memory pricingOptions;
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.0000025 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 10, price: 0.000022 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 25, price: 0.00005 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 50, price: 0.000075 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 100, price: 0.000095 ether});

        ITestERC721 nft = ITestERC721(getERC721(chainId));
        // nft.setApprovalForAll(address(raffle), true);

        ITestERC721 nftB = ITestERC721(getERC721B(chainId));
        // nftB.setApprovalForAll(address(raffle), true);

        ITestERC20 looks = ITestERC20(getERC20(chainId));

        // uint256 totalPrizeInLooks = 3 ether;
        // looks.approve(address(raffle), totalPrizeInLooks);

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](7);

        prizes[0].prizeTier = 0;
        prizes[0].prizeType = IRaffle.TokenType.ERC721;
        prizes[0].prizeAddress = address(nft);
        prizes[0].prizeId = 1;
        prizes[0].prizeAmount = 1;
        prizes[0].winnersCount = 1;

        for (uint256 i = 1; i < 6; ) {
            prizes[i].prizeTier = 1;
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = address(nftB);
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                ++i;
            }
        }
        prizes[1].prizeId = 1;
        prizes[2].prizeId = 2;
        prizes[3].prizeId = 3;
        prizes[4].prizeId = 5;
        prizes[5].prizeId = 7;

        prizes[6].prizeTier = 2;
        prizes[6].prizeType = IRaffle.TokenType.ERC20;
        prizes[6].prizeAddress = address(looks);
        prizes[6].prizeAmount = 1 ether;
        prizes[6].winnersCount = 3;

        uint256 raffleId = raffle.createRaffle(
            IRaffle.CreateRaffleCalldata({
                cutoffTime: uint40(block.timestamp + 5 days),
                isMinimumEntriesFixed: true,
                minimumEntries: 15,
                maximumEntriesPerParticipant: 15,
                protocolFeeBp: 0,
                feeTokenAddress: address(0),
                prizes: prizes,
                pricingOptions: pricingOptions
            })
        );

        raffle.depositPrizes(raffleId);

        vm.stopBroadcast();
    }
}
