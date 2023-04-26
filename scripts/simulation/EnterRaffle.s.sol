// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";

// Core contracts
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

contract EnterRaffle is Script {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey = vm.envUint("GOERLI_KEY");

        if (chainId != 5) {
            revert ChainIdInvalid(chainId);
        }

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = IRaffle(0xA321A39ADd58E9dDe4aE7b4316DcDcA4a99A1513);

        IRaffle.EntryCalldata[] memory entries = new IRaffle.EntryCalldata[](2);
        entries[0] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 0});
        entries[1] = IRaffle.EntryCalldata({raffleId: 1, pricingOptionIndex: 1});

        raffle.enterRaffles{value: 0.000022 ether + 0.0000025 ether}(entries);

        vm.stopBroadcast();
    }
}
