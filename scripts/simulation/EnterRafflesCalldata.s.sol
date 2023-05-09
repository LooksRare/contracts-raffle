// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

contract EnterRafflesCalldata is Script, SimulationBase {
    function run() external view {
        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](1);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0});

        bytes memory data = abi.encodeCall(IRaffle.enterRaffles, entries);
        console2.logBytes(data);
    }
}
