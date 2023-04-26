// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";

// Core contracts
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import "forge-std/console2.sol";

contract SelectWinners is Script {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey = vm.envUint("GOERLI_KEY");

        if (chainId != 5) {
            revert ChainIdInvalid(chainId);
        }

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = IRaffle(0xB0a43B88a814CD40155caf50Fb7aBD0f771663a0);

        uint256 requestId = 63782518079213451294665608781594247048257182247985383962686159275093895347290;

        raffle.selectWinners(requestId);

        vm.stopBroadcast();
    }
}
