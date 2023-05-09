// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";
import "forge-std/console2.sol";
import {SimulationBase} from "./SimulationBase.sol";

// Core contracts
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

contract ClaimPrizes is Script, SimulationBase {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey = vm.envUint("TESTNET_KEY");

        if (chainId != 5 && chainId != 11155111) {
            revert ChainIdInvalid(chainId);
        }

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = getRaffle(block.chainid);

        // IRaffle.Winner[] memory winners = raffle.getWinners(1);
        // for (uint256 i; i < winners.length; i++) {
        //     console2.log(i);
        //     console2.log(winners[i].participant);
        // }

        uint256[] memory winnerIndices = new uint256[](3);

        winnerIndices[0] = 0;
        winnerIndices[1] = 3;
        winnerIndices[2] = 5;

        IRaffle.ClaimPrizesCalldata[] memory claimPrizesCalldata = new IRaffle.ClaimPrizesCalldata[](1);
        claimPrizesCalldata[0].raffleId = 1;
        claimPrizesCalldata[0].winnerIndices = winnerIndices;

        raffle.claimPrizes(claimPrizesCalldata);

        vm.stopBroadcast();
    }
}
