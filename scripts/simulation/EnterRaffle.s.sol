// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {IRaffleV2} from "../../contracts/interfaces/IRaffleV2.sol";

contract EnterRaffle is Script, SimulationBase {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("OPERATION_KEY");

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = getRaffle(block.chainid);

        uint256 count = 0;
        uint256 raffleId = 0;
        uint256 price = 0;
        IRaffleV2.EntryCalldata[] memory entries = new IRaffleV2.EntryCalldata[](count);
        for (uint256 i; i < count; i++) {
            entries[i] = IRaffleV2.EntryCalldata({raffleId: raffleId, pricingOptionIndex: 0, count: 1});
        }

        raffle.enterRaffles{value: price * count}(entries, address(0));

        vm.stopBroadcast();
    }
}
