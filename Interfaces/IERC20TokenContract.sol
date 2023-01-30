// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of erc20 token
 */
interface IERC20TokenContract {
   
    function mintFor(address _addr,uint256 toMintAmount) external;
    function burnFor(address _addr,uint256 toBurnAmount) external;
    function maxSupply() external view returns (uint256);
    function canMintForAmount(uint256 toMintAmount) external view returns(bool);  
    function remainFromMaxSupply() external view returns (uint256);      
    function getMetadata() external view returns (uint256,uint256,uint8,string memory);      
}