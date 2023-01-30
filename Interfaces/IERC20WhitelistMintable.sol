// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20WhitelistMintable {
    
    function whitelistMint(address _addr,uint256 amount) external;
    function whitelistTrimAmountWithMaxSupply(uint256 toMintAmount) external view returns (uint256);
}