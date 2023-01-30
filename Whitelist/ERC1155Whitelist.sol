// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../base/ERC1155WhitelistContractBase.sol";
import "../base/WalletEligibedOnlyContract.sol";

contract ERC1155Whitelist is  ERC1155WhitelistContractBase ,WalletEligibedOnlyContract 
{
    using SafeMath for uint256;

    mapping(address => mapping(uint256 => uint256)) private _item_per_wallet_remains;
    
    mapping(uint256 => uint256) private _item_per_wallet_quotas;
    
    constructor(string memory name_,string memory description_,uint256 individual_cap_,uint256 max_addresses,address token_contract_,address price_currency_) 
        ERC1155WhitelistContractBase(name_,description_,individual_cap_,token_contract_,price_currency_)
        WalletEligibedOnlyContract(max_addresses){
    }
    function add_whitelist_wallets(address[] memory wallets) external onlyOwner {_add_whitelist_wallets(wallets);}
    function add_whitelist_wallet(address wallet) external onlyOwner {_add_whitelist_wallet(wallet);}
    
    function get_item_per_wallet_quota(uint256 token_id) internal view returns(uint256) {return _item_per_wallet_quotas[token_id];}
    function get_item_per_wallet_remain(address addr,uint256 token_id) internal view returns(uint256) {return _item_per_wallet_remains[addr][token_id];}
    
    function init_wallet_remain(address addr) internal virtual override{ 
        super.init_wallet_remain(addr);
        uint256 _max_token_id = get_max_token_id();
        for(uint256 id=1; id <= _max_token_id; id++){
            if((get_item_quota(id) > 0) && (_item_per_wallet_remains[addr][id] == 0)){
                _item_per_wallet_remains[addr][id] =_item_per_wallet_quotas[id];
            }
        }
    }
    function clear_wallet_remain(address addr) internal virtual override {
        super.clear_wallet_remain(addr);
        uint256 _max_token_id = get_max_token_id();
        for(uint256 id=1; id <= _max_token_id; id++){
            if((get_item_quota(id) > 0) && (_item_per_wallet_remains[addr][id] > 0)){
                _item_per_wallet_remains[addr][id];
            }
        }
    }
    function clamp_item_per_wallet_quota(uint256 token_id , uint256 token_quota) internal{
        if(token_quota < _item_per_wallet_quotas[token_id])
            _item_per_wallet_quotas[token_id] = token_quota;
    }
    function onUpdateTokenQuota(uint256 token_id , uint256 token_quota) internal virtual override{
        clamp_item_per_wallet_quota(token_id,token_quota);   
    }
    function onUpdateMintQuota(uint256 token_id,uint256 token_quota,uint256) internal virtual override{
        clamp_item_per_wallet_quota(token_id,token_quota);   
    }
    function onWhitelistWalletAdded(address addr) internal virtual override {
        super.onWhitelistWalletAdded(addr);
        init_wallet_remain(addr);
    }
    function onWhitelistWalletRemoved(address addr) internal virtual override {
        super.onWhitelistWalletRemoved(addr);
        clear_wallet_remain(addr);
    }
    function onClampPerWalletItem(uint256 token_id) internal virtual override{
        super.onClampPerWalletItem(token_id);
        uint256 wallet_count = get_wallet_count();
        uint256 _item_remain = get_item_remains(token_id);
        for(uint256 i; i <= wallet_count; i++){
            address wallet = get_wallet_address(i);
            if(_item_remain < _item_per_wallet_remains[wallet][token_id])
                _item_per_wallet_remains[wallet][token_id] = _item_remain;   
        }
    }
    function onMintItemDefined(uint256 token_id,uint256 per_wallet_quota) internal virtual override {
        super.onMintItemDefined(token_id,per_wallet_quota);
        _item_per_wallet_quotas[token_id] = per_wallet_quota;
        uint256 wallet_count = get_wallet_count(); 
        for(uint256 i = 0; i < wallet_count; i++){
            address _wallet_adddr = get_wallet_address(i);
            _item_per_wallet_remains[_wallet_adddr][token_id] = per_wallet_quota;
        }
    }
    function onMintItemUndefined(uint256 token_id) internal virtual override {
        super.onMintItemUndefined(token_id);
        delete _item_per_wallet_quotas[token_id];
        uint256 wallet_count = get_wallet_count();
        for(uint256 i = 0; i < wallet_count; i++){
            delete _item_per_wallet_remains[get_wallet_address(i)][token_id];
        }
    }
    function deduct_item_per_wallet_remain(address addr,uint256 token_id,uint256 deduct_amount) internal{
        _item_per_wallet_remains[addr][token_id] = _item_per_wallet_remains[addr][token_id].sub(deduct_amount);
    }
    function consume_mint_quota(address addr,uint256 token_id,uint256 amount) internal virtual override {
        
        require(has_wallet(addr),"NOT_WHITELIST");
        require(get_wallet_remain(addr) >= amount,"OUT_OF_QUOTA"); 
        require(_item_per_wallet_remains[addr][token_id] >= amount,"OUT_OF_QUOTA");
        require(get_item_remains(token_id) >= amount,"OUT_OF_SUPPLY");

        deduct_wallet_remain(addr, amount);
        deduct_item_per_wallet_remain(addr,token_id,amount);
        deduct_token_remain(token_id,amount);
    }
    function is_public_whitelist() external view virtual override returns (bool){return false;}

    function get_token_minted_state(address addr,uint256 token_id) external view virtual override returns (uint256,uint256){
        uint256 _quota = get_item_per_wallet_quota(token_id);
        uint256 _remain = has_wallet(addr) ? _item_per_wallet_remains[addr][token_id] : _quota;
        return (_quota - _remain,_quota);
    }
    function get_wallet_remain(address addr) public view virtual override returns(uint256){
        return has_wallet(addr) ? super.get_wallet_remain(addr) : get_individual_cap();
    }
    function get_all_wallets() external view virtual override returns (address[] memory){return get_wallets();}
}