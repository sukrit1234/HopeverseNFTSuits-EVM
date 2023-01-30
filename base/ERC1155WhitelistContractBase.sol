// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IERC1155Whitelist.sol";
import "../base/WhitelistContractBase.sol";
import "../Interfaces/IERC1155WhitelistMintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC1155WhitelistContractBase is  IERC1155Whitelist ,WhitelistContractBase 
{
    using SafeMath for uint256;

    mapping(uint256 => uint256) private _item_quotas;
    mapping(uint256 => uint256) private _item_remains;
    mapping(uint256 => uint256) private _item_prices;

    uint256 private max_token_id = 0;

    constructor(string memory name_,string memory description_,uint256 individual_cap_,address token_contract_,address price_currency_) 
        WhitelistContractBase(name_,description_,individual_cap_,token_contract_,price_currency_){
    }
    
    function get_item_quota(uint256 token_id) internal view returns(uint256) {return _item_quotas[token_id];}
    function get_item_remains(uint256 token_id) internal view returns(uint256) {return _item_remains[token_id];}
    function get_item_prices(uint256 token_id) internal view returns(uint256) {return _item_prices[token_id];}
    function get_max_token_id() internal view returns (uint256) {return max_token_id;}

    function deduct_token_remain(uint256 token_id,uint256 deduct_amount) internal {
         _item_remains[token_id] = _item_remains[token_id].sub(deduct_amount);
    }

    function fetch_token_contract_interface_id() internal virtual override view returns(bytes4){return type(IERC1155WhitelistMintable).interfaceId;}
    function define_mint_item(uint256 token_id,uint256 quota ,uint256 per_wallet_quota,uint256 price_per_token) external onlyOwner {
        address _token_address = get_token_contract_address();
        require(_token_address != address(0) && IERC1155WhitelistMintable(_token_address).isTokenDefineForWhitelist(token_id),"NO_MINTABLE_TOKEN");
        _define_mint_item(token_id,quota ,per_wallet_quota,price_per_token);
    }
    function undefine_mint_item(uint256 token_id) external onlyOwner {
        _undefine_mint_item(token_id);
    }
    function define_mint_item_batch(uint256[] memory token_ids,uint256[] memory quotas ,uint256[] memory per_wallet_quotas,uint256[] memory price_per_tokens) external onlyOwner{
        address _token_address = get_token_contract_address();
        require(_token_address != address(0),"NO_MINTABLE_TOKEN");
        
        IERC1155WhitelistMintable asMintable = IERC1155WhitelistMintable(_token_address);
        
        uint256 token_count = token_ids.length;
        require((token_count == quotas.length) && (token_count == per_wallet_quotas.length) && (token_count == price_per_tokens.length),"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < token_count; i++){
            require(asMintable.isTokenDefineForWhitelist(token_ids[i]),"NO_MINTABLE_TOKEN");
            _define_mint_item(token_ids[i],quotas[i],per_wallet_quotas[i],price_per_tokens[i]);
        }
    }
    function mint(uint256 token_id,uint256 amount) external payable {
        address _token_addr = get_token_contract_address();
        require(_token_addr != address(0),"TOKEN_UNDEFINED");
        consume_mint_quota(msg.sender,token_id,amount);
        consume_mint_fee(_item_prices[token_id],amount);
        IERC1155WhitelistMintable(_token_addr).whitelistMint(msg.sender, token_id, amount);
    }
    function _define_mint_item(uint256 token_id,uint256 quota,uint256 per_wallet_quota,uint256 price) internal{
        /*Check it's already defined*/
        require((quota > 0) && (per_wallet_quota > 0),"ZERO_AMOUNT");
        if(_item_quotas[token_id] == 0){
            _item_quotas[token_id] = quota;
            _item_remains[token_id] = quota;
            _item_prices[token_id] = price;
            onMintItemDefined(token_id,per_wallet_quota);
            if(token_id > max_token_id)
                max_token_id = token_id;
        }
    }
    function _undefine_mint_item(uint256 token_id) internal{
        if(_item_quotas[token_id] > 0){
            delete _item_quotas[token_id];
            delete _item_remains[token_id];
            delete _item_prices[token_id];
            onMintItemUndefined(token_id);
        }
    }
    function update_token_price(uint256 token_id ,uint256 price_per_token) external onlyOwner {
        require(_item_quotas[token_id] > 0,"TOKEN_UNDEFINED");
        _item_prices[token_id] = price_per_token;
    }
    function update_token_quota(uint256 token_id , uint256 token_quota) external onlyOwner{
        require(_item_quotas[token_id] > 0,"TOKEN_UNDEFINED");
        _item_quotas[token_id] = token_quota;
        if(token_quota < _item_remains[token_id]){
            _item_remains[token_id] = token_quota;
            onClampPerWalletItem(token_id);
        }
        onUpdateTokenQuota(token_id,token_quota);
    }
    function update_token_remain(uint256 token_id ,uint256 token_remain) external onlyOwner{
        require(_item_quotas[token_id] > 0,"TOKEN_UNDEFINED");
        if(token_remain > _item_quotas[token_id])
            _item_remains[token_id] = _item_quotas[token_id];
        else
            _item_remains[token_id] = token_remain;
        onClampPerWalletItem(token_id);
    }
    function update_mint_quota(uint256 token_id,uint256 token_quota,uint256 token_remain) external onlyOwner{
        require((token_quota > 0) && (token_remain > 0),"ZERO_AMOUNT");
        require(token_remain <= token_quota,"SUPPLY_OVERFLOW");
        require(_item_quotas[token_id] > 0,"TOKEN_UNDEFINED");
        _item_quotas[token_id] = token_quota;
        _item_remains[token_id] = token_remain;
        onUpdateMintQuota(token_id,token_quota,token_remain);
        onClampPerWalletItem(token_id);
    }
    
    function onClampPerWalletItem(uint256) internal virtual {}
    function onMintItemDefined(uint256,uint256) internal virtual {}
    function onMintItemUndefined(uint256) internal virtual {}

    function onUpdateTokenQuota(uint256 token_id , uint256 token_quota) internal virtual {}
    function onUpdateMintQuota(uint256 token_id,uint256 token_quota,uint256 token_remain) internal virtual {}

    function consume_mint_quota(address,uint256,uint256) internal virtual {
        require(false,"MINT_CONSUME_UNIMPLEMENT");
    }
    function get_mintable_items() external view virtual override returns (uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        uint256 mintable_item_count = 0;
        for(uint256 tId = 1; tId <= max_token_id; tId++){
            if(_item_quotas[tId] > 0)
                mintable_item_count = mintable_item_count.add(1);
        }

        uint256 counter = 0;
        uint256[] memory token_ids = new uint256[](mintable_item_count);
        uint256[] memory total_minted = new uint256[](mintable_item_count);
        uint256[] memory total_quotas = new uint256[](mintable_item_count);
        uint256[] memory token_prices = new uint256[](mintable_item_count);
        for(uint256 tId = 1; tId <= max_token_id; tId++){
            if(_item_quotas[tId] > 0)
            {
                token_ids[counter] = tId;
                total_quotas[counter] = _item_quotas[tId];
                total_minted[counter] = _item_quotas[tId] - _item_remains[tId];
                token_prices[counter] = _item_prices[tId];
                counter = counter.add(1);
            }
        }
        return (token_ids,total_minted,total_quotas,token_prices);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155Whitelist).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}