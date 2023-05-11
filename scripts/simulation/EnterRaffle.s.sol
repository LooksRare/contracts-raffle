// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

contract EnterRaffle is Script, SimulationBase {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("TESTNET_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = getRaffle(block.chainid);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1});

        raffle.enterRaffles{value: 0.000022 ether + 0.0000025 ether}(entries);

        vm.stopBroadcast();
    }
}
