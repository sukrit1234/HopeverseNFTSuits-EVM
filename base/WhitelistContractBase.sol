// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Interfaces/IWhitelistContract.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract WhitelistContractBase is Ownable,IWhitelistContract,ERC165{

    using ERC165Checker for address;
    using SafeMath for uint256;
    using Address for address;

    string private name;
    string private description;
    address private merchant_address;
    
    uint256 private individual_cap;

    //NFT or Token to mint
    address private token_contract = address(0);
    //Interface id of token or NFT.
    bytes4 private token_constract_interface_id = 0xffffffff;

    address private price_currency_contract = address(0);
    bytes4 constant price_currency_interface_id = type(IERC20).interfaceId;

    mapping(address => uint256) private _wallet_remains;

    event OnMerchantChanged(address indexed previousMerchant, address indexed newMerchant);
    event OnWhitelistMetadataUpdated(string name,string desc,uint256 individual_cap);

    constructor(string memory name_,string memory description_,uint256 individual_cap_,address token_contract_,address price_currency_) {
        name = name_;
        description = description_;
        individual_cap = individual_cap_;
        merchant_address = msg.sender;
        token_constract_interface_id = fetch_token_contract_interface_id();

        _set_token_contract_internal(token_contract_);
        _set_price_currency_internal(price_currency_);
    }

    function get_individual_cap() public view returns (uint256){return individual_cap;}
    function get_merchant_adddress() public view returns (address){return merchant_address;}
    function get_token_contract_address() public view returns(address) {return token_contract;}
    function fetch_token_contract_interface_id() internal virtual view returns(bytes4){return 0xffffffff;}
    function get_wallet_remain(address addr) public view virtual returns(uint256){return _wallet_remains[addr];}
    function init_wallet_remain(address addr) internal virtual { _wallet_remains[addr] = individual_cap;}
    function clear_wallet_remain(address addr) internal virtual {delete _wallet_remains[addr];}
    function deduct_wallet_remain(address addr,uint256 deduct_amount) internal {
        _wallet_remains[addr] = _wallet_remains[addr].sub(deduct_amount);
    }

    function _set_token_contract_internal(address addr) internal {
        require(addr.supportsInterface(token_constract_interface_id),"UNSUPPORT_TOKEN");
        token_contract = addr;
    }
    function _set_price_currency_internal(address addr) internal {
        require(addr == address(0) || addr.supportsInterface(price_currency_interface_id),"UNSUPPORT_CURRENCY");
        price_currency_contract = addr;
    }
    function set_token_contract(address addr) external onlyOwner {
        _set_token_contract_internal(addr);
    }
    function set_price_currency_contract(address addr) external onlyOwner{
        _set_price_currency_internal(addr);
    }
    function consume_mint_fee(uint256 price_per_token,uint256 amount) internal{
        
        require(amount > 0,"ZERO_AMOUNT");
        //free operation just skip.
        if(price_per_token == 0)
            return;

        require(merchant_address != address(0),"NO_MERCHANT_ADDR");

        uint256 total_mint_fee = price_per_token.mul(amount);
        if(price_currency_contract != address(0)){
           uint256 available_balance = IERC20(price_currency_contract).balanceOf(msg.sender);
           require(available_balance >= total_mint_fee,"UNSUFFICIENT_BALANCE");
           IERC20(price_currency_contract).transferFrom(msg.sender, merchant_address, total_mint_fee);
           if(msg.value > 0) //In-case accident has value from sender , just return back.
              payable(msg.sender).transfer(msg.value);
        }
        else{
            require(msg.value >= total_mint_fee,"UNSUFFICIENT_BALANCE");
            uint256 remain_value = msg.value.sub(total_mint_fee);
            payable(merchant_address).transfer(total_mint_fee);
            //Send back changes
            payable(msg.sender).transfer(remain_value);
        }
    }
    function change_owner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }
    function set_name(string memory newName) external onlyOwner {
        name = newName;
        emit OnWhitelistMetadataUpdated(name,description,individual_cap);
    }
    function set_description(string memory newDesc) external onlyOwner{
        description = newDesc;
        emit OnWhitelistMetadataUpdated(name,description,individual_cap);
    }
    function set_individual_cap(uint256 newCap) external onlyOwner{
        individual_cap = newCap;
        emit OnWhitelistMetadataUpdated(name,description,individual_cap);
    }
    function set_merchant(address newMerchant) external virtual onlyOwner{
        require((merchant_address != newMerchant) && (newMerchant != address(0)),"INVALID_MERCHANT");
        require(!newMerchant.isContract(),"MERCHANT_CANNOT_CONTRACT");       
        
        address _old_merchant = merchant_address;
        merchant_address = newMerchant;
        emit OnMerchantChanged(_old_merchant,merchant_address);
    }
    function get_metadata() external view virtual override returns (string memory,string memory,uint256,address,address){
        return (name,description,individual_cap,token_contract,price_currency_contract);
    }   
    function get_minted_amount(address addr) external view returns (uint256){
         return individual_cap.sub(get_wallet_remain(addr));
    }
    
    function get_minted_state(address addr) external view returns (uint256,uint256){
        return (individual_cap.sub(get_wallet_remain(addr)),individual_cap);
    }

    function get_quota_amount(address) external view virtual override returns (uint256){return individual_cap;}

    function get_all_wallets() external view virtual override returns (address[] memory){return new address[](0);}

    function get_token_contract() external view virtual override returns (address){return get_token_contract_address();}

    function get_price_currency_contract() external view virtual override returns (address){return price_currency_contract;}

    function is_public_whitelist() external view virtual override returns (bool){return true;}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IWhitelistContract).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}