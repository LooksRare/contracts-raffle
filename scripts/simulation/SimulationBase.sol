// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Core contracts
import {IRaffle} from "../../contracts/interfaces/IRaffle.sol";

contract SimulationBase {
    address public constant SEPOLIA_ERC_721 = 0x61AAEcdbe9C2502a72fec63F2Ff510bE1b95DD97;
    address public constant SEPOLIA_ERC_20 = 0xa68c2CaA3D45fa6EBB95aA706c70f49D3356824E;
    address public constant SEPOLIA_ERC_1155 = 0xE29BcBb8145B8A281BaBDd956e1595b1b76ddAfb;
    address public constant SEPOLIA_RAFFLE = 0xb0C8a1a0569F7302d36e380755f1835C3e59aCB9;

    address public constant GOERLI_ERC_721 = 0x77566D540d1E207dFf8DA205ed78750F9a1e7c55;
    address public constant GOERLI_ERC_20 = 0x20A5A36ded0E4101C3688CBC405bBAAE58fE9eeC;
    address public constant GOERLI_ERC_1155 = 0x58c3c2547084CC1C94130D6fd750A3877c7Ca5D2;
    address public constant GOERLI_RAFFLE = 0xC5F7FCde87e30Aa339d3d61B4fe3c1C261f6EEe2;

    address public constant RAFFLE_OWNER = 0xF332533bF5d0aC462DC8511067A8122b4DcE2B57;

    function getRaffle(uint256 chainId) internal pure returns (IRaffle raffle) {
        if (chainId != 5 && chainId != 11155111) {
            revert("Invalid chain ID");
        }
        raffle = IRaffle(chainId == 5 ? GOERLI_RAFFLE : SEPOLIA_RAFFLE);
    }

    function getERC20(uint256 chainId) internal pure returns (address) {
        return chainId == 5 ? GOERLI_ERC_20 : SEPOLIA_ERC_20;
    }

    function getERC1155(uint256 chainId) internal pure returns (address) {
        return chainId == 5 ? GOERLI_ERC_1155 : SEPOLIA_ERC_1155;
    }
}
