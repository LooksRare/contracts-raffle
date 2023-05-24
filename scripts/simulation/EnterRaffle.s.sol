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
        uint256 deployerPrivateKey = vm.envUint("OPERATION_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = getRaffle(block.chainid);

        uint256 count = 0;
        uint256 raffleId = 0;
        uint256 price = 0;
        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](count);
        for (uint256 i; i < count; i++) {
            entries[i] = IRaffle.EntryCalldata({raffleId: raffleId, pricingOptionIndex: 0, count: 1});
        }

        raffle.enterRaffles{value: price * count}(entries, address(0));

        vm.stopBroadcast();
    }
}
