// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Whitelist {
    
    /*Mint funcitons*/
    function mint(uint256 amount) external payable;

    /*Return mintable (minted amount,quota,price)*/
    function get_mintable_state() external view returns (uint256,uint256,uint256);
}