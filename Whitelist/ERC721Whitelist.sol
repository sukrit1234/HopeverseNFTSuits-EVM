// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../base/ERC721WhitelistContractBase.sol";
import "../base/WalletEligibedOnlyContract.sol";

contract ERC721Whitelist is  ERC721WhitelistContractBase ,WalletEligibedOnlyContract 
{
    using SafeMath for uint256;

    constructor(string memory name_,string memory description_,uint256 individual_cap_,uint256 max_addresses,address token_contract_,address price_currency_) 
        ERC721WhitelistContractBase(name_,description_,individual_cap_,token_contract_,price_currency_)
        WalletEligibedOnlyContract(max_addresses){
    }
    function add_whitelist_wallets(address[] memory wallets) external onlyOwner {_add_whitelist_wallets(wallets);}
    function add_whitelist_wallet(address wallet) external onlyOwner {_add_whitelist_wallet(wallet);}
    
    function onWhitelistWalletAdded(address addr) internal virtual override {
        super.onWhitelistWalletAdded(addr);
        init_wallet_remain(addr);
    }
    function onWhitelistWalletRemoved(address addr) internal virtual override {
        super.onWhitelistWalletRemoved(addr);
        clear_wallet_remain(addr);
    }
    function consume_mint_quota(address addr,uint256 amount) internal virtual override {
        
        require(has_wallet(addr),"NOT_WHITELIST");
        require(get_wallet_remain(addr) >= amount,"OUT_OF_QUOTA"); 
        require(get_item_remain() >= amount,"OUT_OF_SUPPLY");

        deduct_wallet_remain(addr, amount);
        deduct_token_remain(amount);
    }
    function is_public_whitelist() external view virtual override returns (bool){return false;}
    
    function get_wallet_remain(address addr) public view virtual override returns(uint256){
        return has_wallet(addr) ? super.get_wallet_remain(addr) : get_individual_cap();
    }
    function get_all_wallets() external view virtual override returns (address[] memory){return get_wallets();}
}