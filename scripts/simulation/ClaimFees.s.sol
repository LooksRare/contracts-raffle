// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

contract ClaimFees is Script, SimulationBase {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey = vm.envUint("TESTNET_KEY");

        if (chainId != 5 && chainId != 11155111) {
            revert ChainIdInvalid(chainId);
        }

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = getRaffle(block.chainid);

        raffle.claimFees(1);

        vm.stopBroadcast();
    }
}
