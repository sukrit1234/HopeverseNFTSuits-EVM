// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IAccountVault {
   
    //Get real personal address by in-app address.
    function linkedAddressOf(address _inDappAddr) external view returns (address);

    //Check in-dapp address has any address linked with.
    function hasLinkAddressOf(address _inDappAddr) external view returns (bool);
   
    //Check in-dapp address has any address linked with.
    function isAccountLinked(address _inDappAddr,address _personalAddr) external view returns (bool);
   
    //Link sender address with _inDappAddr
    function linkToAddress(address _inDappAddr) external;

    //Unlink sender address fomr _inDappAddr
    function unlinkFromAddress(address _inDappAddr) external;

    //Get Vault name
    function getVaultName() external view returns (string memory);
}