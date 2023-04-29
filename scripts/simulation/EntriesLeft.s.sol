// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";

// Core contracts
import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import "forge-std/console2.sol";

contract EntriesLeft is Script {
    error ChainIdInvalid(uint256 chainId);

    function run() external view {
        IRaffle raffle = IRaffle(0xCBD1922cD0789365ebCa9464073b678019869630);
        IRaffle.Entry[] memory entries = raffle.getEntries(0);
        IRaffle.Entry memory lastEntry = entries[entries.length - 1];
        console2.logUint(lastEntry.currentEntryIndex);
    }
}
