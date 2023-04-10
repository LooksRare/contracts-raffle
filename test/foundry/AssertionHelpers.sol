// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "../../lib/forge-std/src/Test.sol";

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

import {MockERC20} from "./mock/MockERC20.sol";
import {MockERC721} from "./mock/MockERC721.sol";

abstract contract AssertionHelpers is Test {
    function assertRaffleStatus(
        Raffle looksRareRaffle,
        uint256 raffleId,
        IRaffle.RaffleStatus expectedStatus
    ) internal {
        (, IRaffle.RaffleStatus status, , , , , , ) = looksRareRaffle.raffles(raffleId);
        assertEq(uint8(status), uint8(expectedStatus));
    }
}
