// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721WhitelistMintable {
    function whitelistMint(address addr,uint256 amount) external returns (uint256[] memory);
}