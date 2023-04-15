// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";

// Core contracts
import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import {IERC20} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC20.sol";

interface ITestERC721 {
    function mint(address to, uint256 amount) external;

    function setApprovalForAll(address operator, bool approved) external;

    function totalSupply() external returns (uint256);
}

contract CreateRaffle is Script {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey = vm.envUint("GOERLI_KEY");

        if (chainId != 5) {
            revert ChainIdInvalid(chainId);
        }

        vm.startBroadcast(deployerPrivateKey);

        Raffle raffle = Raffle(0x9314FA83876e603642Cbd002AB71b5Afb3E6Df04);

        IRaffle.PricingOption[5] memory pricingOptions;
        pricingOptions[0] = IRaffle.PricingOption({entriesCount: 1, price: 0.025 ether});
        pricingOptions[1] = IRaffle.PricingOption({entriesCount: 10, price: 0.22 ether});
        pricingOptions[2] = IRaffle.PricingOption({entriesCount: 25, price: 0.5 ether});
        pricingOptions[3] = IRaffle.PricingOption({entriesCount: 50, price: 0.75 ether});
        pricingOptions[4] = IRaffle.PricingOption({entriesCount: 100, price: 0.95 ether});

        ITestERC721 nft = ITestERC721(0x77566D540d1E207dFf8DA205ed78750F9a1e7c55);
        uint256 totalSupply = nft.totalSupply();
        nft.mint(0xF332533bF5d0aC462DC8511067A8122b4DcE2B57, 6);
        nft.setApprovalForAll(address(raffle), true);

        IERC20 looks = IERC20(0x20A5A36ded0E4101C3688CBC405bBAAE58fE9eeC);

        looks.approve(address(raffle), 10_000e18);

        IRaffle.Prize[] memory prizes = new IRaffle.Prize[](7);
        for (uint256 i; i < 6; ) {
            prizes[i].prizeType = IRaffle.TokenType.ERC721;
            prizes[i].prizeAddress = address(nft);
            prizes[i].prizeId = totalSupply + i;
            prizes[i].prizeAmount = 1;
            prizes[i].winnersCount = 1;

            unchecked {
                i++;
            }
        }
        prizes[6].prizeType = IRaffle.TokenType.ERC20;
        prizes[6].prizeAddress = address(looks);
        prizes[6].prizeAmount = 1_000e18;
        prizes[6].winnersCount = 10;

        uint256 raffleId = raffle.createRaffle({
            cutoffTime: block.timestamp + 5 days,
            minimumEntries: 100,
            maximumEntries: 101,
            maximumEntriesPerParticipant: 20,
            prizesTotalValue: 1 ether,
            minimumProfitBp: 500,
            feeTokenAddress: address(0),
            prizes: prizes,
            pricingOptions: pricingOptions
        });

        raffle.depositPrizes(raffleId);

        vm.stopBroadcast();
    }
}
