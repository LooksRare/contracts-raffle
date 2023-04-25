// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Scripting tool
import {Script} from "../../lib/forge-std/src/Script.sol";

// Core contracts
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import "forge-std/console2.sol";

contract ClaimPrizes is Script {
    error ChainIdInvalid(uint256 chainId);

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey = vm.envUint("GOERLI_KEY");

        if (chainId != 5) {
            revert ChainIdInvalid(chainId);
        }

        vm.startBroadcast(deployerPrivateKey);

        IRaffle raffle = IRaffle(0x3B3D3CF2000ed76F0a268E4FC4DeA900A3410ace);

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
