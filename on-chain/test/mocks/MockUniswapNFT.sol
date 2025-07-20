///SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockUniswapNFT is ERC721{

    uint256 s_tokenId;
    constructor(string memory _name, string memory _symbol) ERC721 (_name, _symbol){}

    function mint(address _account) external {
        uint256 tokenId = s_tokenId;
        s_tokenId = s_tokenId + 1;
        _mint(_account, tokenId);
    }

    function safeMint(address _account) external {
        uint256 tokenId = s_tokenId;
        s_tokenId = s_tokenId + 1;
        _safeMint(_account, tokenId);
    }
}