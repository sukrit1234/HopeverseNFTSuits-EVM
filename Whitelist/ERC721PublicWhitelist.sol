// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/ERC721WhitelistContractBase.sol";

contract ERC721PublicWhitelist is  ERC721WhitelistContractBase
{
    mapping(address => bool) private _wallet_registered;

    constructor(string memory name_,string memory description_,uint256 individual_cap_,address token_contract_,address price_currency_) 
        ERC721WhitelistContractBase(name_,description_,individual_cap_,token_contract_,price_currency_){
    }
    function consume_mint_quota(address addr,uint256 amount) internal virtual override {
        /*If Wallet not registered just register first.*/
        if(!_wallet_registered[addr]){
            init_wallet_remain(addr);
            _wallet_registered[addr] = true;
        }
        
        require(get_wallet_remain(addr) >= amount,"OUT_OF_QUOTA"); 
        require(get_item_remain() >= amount,"OUT_OF_SUPPLY");
        
        deduct_wallet_remain(addr, amount);
        deduct_token_remain(amount);
    }
    function get_wallet_remain(address addr) public view virtual override returns(uint256){
        uint256 _individual_cap_= get_individual_cap();
        return _wallet_registered[addr] ? super.get_wallet_remain(addr) : _individual_cap_;
    }
    function is_public_whitelist() external view virtual override returns (bool){return true;}
    
}