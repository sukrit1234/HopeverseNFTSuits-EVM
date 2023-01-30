// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155WhitelistMintable {
    
    function whitelistMint(address _addr,uint256 tokenId,uint256 amount) external;

    function isTokenDefineForWhitelist(uint256 tokenId) external view returns (bool);
}