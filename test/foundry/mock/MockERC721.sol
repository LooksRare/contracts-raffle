// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721("MockERC721", "MockERC721") {
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function batchMint(address to, uint256 count) public {
        for (uint256 i; i < count; i++) {
            _mint(to, i);
        }
    }
}