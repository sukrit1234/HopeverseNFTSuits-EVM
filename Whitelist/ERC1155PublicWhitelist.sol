// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/ERC1155WhitelistContractBase.sol";

contract ERC1155PublicWhitelist is  ERC1155WhitelistContractBase
{
    using SafeMath for uint256;
    mapping(address => bool) private _wallet_registered;

    constructor(string memory name_,string memory description_,uint256 individual_cap_,address token_contract_,address price_currency_) 
        ERC1155WhitelistContractBase(name_,description_,individual_cap_,token_contract_,price_currency_){
    }
    function consume_mint_quota(address addr,uint256 token_id,uint256 amount) internal virtual override {
        
        /*If Wallet not registered just register first.*/
        if(!_wallet_registered[addr]){
            init_wallet_remain(addr);
            _wallet_registered[addr] = true;
        }

        require(get_wallet_remain(addr) >= amount,"OUT_OF_QUOTA"); 
        require(get_item_remains(token_id) >= amount,"OUT_OF_SUPPLY");

        deduct_wallet_remain(addr, amount);
        deduct_token_remain(token_id,amount);
    }
    function is_public_whitelist() external view virtual override returns (bool){return true;}
    
    function get_token_minted_state(address addr,uint256) external view virtual override returns (uint256,uint256){
       uint256 _individual_cap_= get_individual_cap();
       return (_individual_cap_.sub(get_wallet_remain(addr)),_individual_cap_);
    }
    function get_wallet_remain(address addr) public view virtual override returns(uint256){
        uint256 _individual_cap_= get_individual_cap();
        return _wallet_registered[addr] ? super.get_wallet_remain(addr) : _individual_cap_;
    }
}