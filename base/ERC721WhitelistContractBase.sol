// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IERC721Whitelist.sol";
import "../base/WhitelistContractBase.sol";
import "../Interfaces/IERC721WhitelistMintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721WhitelistContractBase is  IERC721Whitelist ,WhitelistContractBase 
{
    using SafeMath for uint256;

    //Quota allow to mint.
    uint256 private _item_quota;

    //Price of token.
    uint256 private _item_price;

    //Remain item can mint.
    uint256 private _item_remain;


    constructor(string memory name_,string memory description_,uint256 individual_cap_,address token_contract_,address price_currency_) 
        WhitelistContractBase(name_,description_,individual_cap_,token_contract_,price_currency_){
    }
    function get_item_quota() public view returns(uint256) {return _item_quota;}
    function get_item_price() public view returns(uint256) {return _item_price;}
    function get_item_remain() public view returns(uint256) {return _item_remain;}
    function deduct_token_remain(uint256 deduct_amount) internal {
         _item_remain = _item_remain.sub(deduct_amount);
    }

    function fetch_token_contract_interface_id() internal virtual override view returns(bytes4){return type(IERC721WhitelistMintable).interfaceId;}
    function mint(uint256 amount) external virtual override payable {
        address _token_addr = get_token_contract_address();
        require(_token_addr != address(0),"TOKEN_UNDEFINED");
        consume_mint_quota(msg.sender,amount);
        consume_mint_fee(_item_price,amount);
        IERC721WhitelistMintable(_token_addr).whitelistMint(msg.sender, amount);
    }
    function init_minter(uint256 quota,uint256 price) external onlyOwner{
        require(quota > 0,"ZERO_QUOTA");
        _item_quota = quota;
        _item_remain = quota;
        _item_price = price;
    }
    function update_token_price(uint256 price_per_token) external onlyOwner {
       _item_price = price_per_token;
    }
    function update_token_quota(uint256 token_quota) external onlyOwner{
        _item_quota = token_quota;
        if(token_quota < _item_remain)
            _item_remain = token_quota;
    }
    function update_token_remain(uint256 token_remain) external onlyOwner{
        if(token_remain > _item_quota)
            _item_remain = _item_quota;
        else
           _item_remain = token_remain;
    }
    function update_mint_quota(uint256 token_quota,uint256 token_remain) external onlyOwner{
        require((token_quota > 0) && (token_remain > 0),"ZERO_AMOUNT");
        require(token_remain <= token_quota,"SUPPLY_OVERFLOW");
        _item_quota = token_quota;
        _item_remain = token_remain;
    }
    function consume_mint_quota(address,uint256) internal virtual {
        require(false,"MINT_CONSUME_UNIMPLEMENT");
    }
    
    /*Return mintable (minted amount,quota,price)*/
    function get_mintable_state() external view override returns (uint256,uint256,uint256){
        return (_item_quota - _item_remain,_item_quota,_item_price);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Whitelist).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}