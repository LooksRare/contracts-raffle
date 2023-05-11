// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

contract ClaimProtocolFees is Script, SimulationBase {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("TESTNET_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = getRaffle(block.chainid);

        raffle.claimProtocolFees(address(0));

        vm.stopBroadcast();
    }
}
