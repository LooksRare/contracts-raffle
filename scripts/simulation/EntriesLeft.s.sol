// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

contract EntriesLeft is Script, SimulationBase {
    function run() external view {
        IRaffle raffle = getRaffle(block.chainid);
        IRaffle.Entry[] memory entries = raffle.getEntries(0);
        IRaffle.Entry memory lastEntry = entries[entries.length - 1];
        console2.logUint(lastEntry.currentEntryIndex);
    }
}
