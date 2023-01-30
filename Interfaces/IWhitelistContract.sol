// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
interface IWhitelistContract {

    /*Retreive metada for whitelist
        + name , description,individual cap,token address,price currency address.
    */
    function get_metadata() external view returns (string memory,string memory,uint256,address,address);

    /*Return minted amount of address*/
    function get_minted_amount(address addr) external view returns (uint256);

    /*Return mint quota of address*/
    function get_quota_amount(address addr) external view returns (uint256);
    
    /*Return (minted and total) amount for address */
    function get_minted_state(address addr) external view returns (uint256,uint256);

    /* Address from one of these interfaces 
        + IERC721WhitelistMintable
        + IERC1155WhitelistMintable
    */
    function get_token_contract() external view returns (address);

    /*Address from IERC20 Interface*/
    function get_price_currency_contract() external view returns (address);

    /*Return all whitelist wallet*/
    function get_all_wallets() external view returns (address[] memory);

    /*Return true if public whitelist otherwise false*/
    function is_public_whitelist() external view returns (bool);
}