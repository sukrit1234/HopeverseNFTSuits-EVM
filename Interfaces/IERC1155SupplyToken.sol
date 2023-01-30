// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IERC1155SupplyToken {
   
    function totalSupplyOf(uint256 tokenId) external view returns (uint256);
}