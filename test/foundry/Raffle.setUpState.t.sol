// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Raffle} from "../../contracts/Raffle.sol";
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";
import {TestHelpers} from "./TestHelpers.sol";

import {MockERC721} from "./mock/MockERC721.sol";

contract Raffle_SetUpState_Test is TestHelpers {
    Raffle public looksRareRaffle;

    function setUp() public {
        looksRareRaffle = _deployRaffle();
    }

    function test_setUpState() public {
        assertEq(looksRareRaffle.KEY_HASH(), hex"474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c");
        assertEq(address(looksRareRaffle.VRF_COORDINATOR()), 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625);
        assertEq(looksRareRaffle.SUBSCRIPTION_ID(), 1_122);
    }
}
