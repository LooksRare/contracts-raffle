// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev These are Sepolia parameters.
 */
abstract contract TestParameters {
    bytes32 internal constant KEY_HASH = hex"474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c";
    uint64 internal constant SUBSCRIPTION_ID = 1_122;
    address internal constant VRF_COORDINATOR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    address internal constant SUBSCRIPTION_ADMIN = 0xF332533bF5d0aC462DC8511067A8122b4DcE2B57;

    // TODO: Deploy ProtocolFeeRecipient locally and use that address
    address internal constant PROTOCOL_FEE_RECIPIENT = address(69_420);

    uint256 internal constant FULFILL_RANDOM_WORDS_REQUEST_ID =
        28189936613108082032912937814055130193651564991612570029372040097433016992289;
}
