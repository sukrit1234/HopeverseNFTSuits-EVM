// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../Interfaces/ITokenOperatableTemplate.sol";

contract TokenOperatableTemplateContract is Ownable,ITokenOperatableTemplate,ERC165 {
    using SafeMath for uint256;
    using ERC165Checker for address;
    using Address for address;

    string private name;
    string private description;

    mapping(uint256 => string) private template_names;
    mapping(uint256 => string) private template_descs;
    mapping(uint256 => uint256) private operation_prices;
    mapping(uint256 => bool) private template_enabled;

    //For some reason in marketing we have template specific merchant if not set just use merchant address.
    mapping(uint256 => address) private template_merchants;

    address private merchant_address;

    //NFT or Token to mint
    address private token_contract = address(0);

    //Interface id of token or NFT.
    bytes4 private token_constract_interface_id = 0xffffffff;

    address private price_currency_contract = address(0);
    bytes4 constant price_currency_interface_id = type(IERC20).interfaceId;

    constructor(string memory name_,string memory description_,address token_contract_,address price_currency_contract_) {
        name = name_;
        description = description_;
        merchant_address = msg.sender;
        token_constract_interface_id = fetch_token_contract_interface_id();
        _set_token_contract_internal(token_contract_);
        _set_price_currency_contract_internal(price_currency_contract_);
    }
    event OnTemplateUndefined(uint256 template_id);

    function fetch_token_contract_interface_id() internal virtual returns(bytes4) {return 0xffffffff;}
    
    function _set_token_contract_internal(address addr) internal{
        require(addr.supportsInterface(token_constract_interface_id),"UNSUPPORT_TOKEN");
        token_contract = addr;
    }
    function _set_price_currency_contract_internal(address addr) internal {
        require(addr == address(0) || addr.supportsInterface(price_currency_interface_id),"UNSUPPORT_CURRENCY");
        price_currency_contract = addr;
    }
    
    
    function set_token_contract(address addr) external onlyOwner{
        _set_token_contract_internal(addr);
    }
    function set_price_currency_contract(address addr) external onlyOwner {
        _set_price_currency_contract_internal(addr);
    }
    function set_merchant(address merchant) external onlyOwner {
        require((merchant_address != merchant) && (merchant != address(0)),"INVALID_MERCHANT");
        require(!merchant.isContract(),"MERCHANT_CANNOT_CONTRACT");
        merchant_address = merchant;
    }
    function get_token_contract() external view virtual override returns (address){return token_contract;}
    function get_token_contract_address() public view returns (address){return token_contract;}
    function get_price_currency_contract_address() public view returns (address){return price_currency_contract;}
    function get_last_template_id() internal view virtual returns (uint256) {return 0;}
    function get_merchant_address(uint256 template_id) internal view returns(address){
       address addr = template_merchants[template_id];
       return addr != address(0) ? addr : merchant_address;
    }
    function undefine_template(uint256 template_id) external onlyOwner {
        _undefine_template(template_id);
    }
    function undefine_templates(uint256[] memory template_ids) external onlyOwner {
         for(uint256 i = 0; i < template_ids.length; i++)
           _undefine_template(template_ids[i]);    
    }

    function update_template_name(uint256 template_id,string memory template_name_) external onlyOwner{
        _udpate_template_name(template_id,template_name_);
    }
    function update_template_names(uint256[] memory template_ids,string[] memory template_names_) external onlyOwner {
        require(template_ids.length == template_names_.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _udpate_template_name(template_ids[i],template_names_[i]);    
    }

    function update_template_desc(uint256 template_id,string memory desc) external onlyOwner{
        _update_template_desc(template_id,desc);
    }
    function update_template_descs(uint256[] memory template_ids,string[] memory descs) external onlyOwner {
        require(template_ids.length == descs.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _update_template_desc(template_ids[i],descs[i]);    
    }

    function update_operation_price(uint256 template_id,uint256 price) external onlyOwner{
        _update_operation_price(template_id,price);
    }
    function update_operation_prices(uint256[] memory template_ids,uint256[] memory prices) external onlyOwner {
        require(template_ids.length == prices.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _update_operation_price(template_ids[i],prices[i]);    
    }

    function update_template_merchant(uint256 template_id,address merchant) external onlyOwner{
        _update_template_merchant(template_id,merchant);
    }
    function update_template_merchants(uint256[] memory template_ids,address[] memory merchants) external onlyOwner {
        require(template_ids.length == merchants.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _update_template_merchant(template_ids[i],merchants[i]);    
    }

    function is_defined(uint256 template_id) public view returns(bool) {return (bytes(template_names[template_id]).length > 0);}
   
    function is_enabled(uint256 template_id) public view returns(bool) {return template_enabled[template_id];}
    
    function enable_template(uint256 template_id,bool enabled) external onlyOwner {
        _enable_template(template_id,enabled);
    }
    function enable_templates(uint256[] memory template_ids,bool[] memory enables) external onlyOwner {
        require(template_ids.length == enables.length,"PARAM_DIM_MISMATCH");
        for(uint256 i = 0; i < template_ids.length; i++)
           _enable_template(template_ids[i],enables[i]);
    }
    
    function _undefine_template(uint256 template_id) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");
        _clear_template_metadata(template_id);
        onUndefineTemplate(template_id);
        emit OnTemplateUndefined(template_id);
    }
  
    function _fill_template_metadata(uint256 template_id,string memory name_,string memory desc,uint256 op_price,bool start_enabled,address merchant) internal{
        template_names[template_id] = name_;
        template_descs[template_id] = desc;
        operation_prices[template_id] = op_price;
        template_enabled[template_id] = start_enabled;
        template_merchants[template_id] = merchant;
    }
    function _clear_template_metadata(uint256 template_id) internal{
        delete template_names[template_id];
        delete template_descs[template_id];
        delete operation_prices[template_id];
        delete template_enabled[template_id];
        delete template_merchants[template_id];
    }
    function _udpate_template_name(uint256 template_id,string memory name_) internal{
        require(bytes(template_names[template_id]).length > 0,"NO_TPL_DEFINED");        
        require(bytes(name_).length > 0,"NO_TPL_NAME");        
        template_names[template_id] = name_;
    }
    function _update_template_desc(uint256 template_id,string memory desc) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        template_descs[template_id] = desc;
    }
    function _update_operation_price(uint256 template_id,uint256 price) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        operation_prices[template_id] = price;
    }
    function _update_template_merchant(uint256 template_id,address merchant) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");
        require(merchant != address(0),"NULL_ADDRESS");
        require(!merchant.isContract(),"MERCHANT_CANNOT_CONTRACT");       
        template_merchants[template_id] = merchant;
    }
    function _enable_template(uint256 template_id,bool enabled) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        template_enabled[template_id] = enabled;
    }
    function consume_operation_cost(uint256 template_id,uint256 applyCount) internal {
        require(applyCount > 0,"ZERO_APPLYCOUNT");
        uint256 op_price = operation_prices[template_id];
        if(op_price == 0)
            return;

        address _merchant_addr = get_merchant_address(template_id);
        require(_merchant_addr != address(0),"NO_MERCHANT_ADDR");

        uint256 total_op_cost = op_price.mul(applyCount);
        if(price_currency_contract != address(0)){
           uint256 available_balance = IERC20(price_currency_contract).balanceOf(msg.sender);
           require(available_balance >= total_op_cost,"UNSUFFICIENT_BALANCE");
           IERC20(price_currency_contract).transferFrom(msg.sender, _merchant_addr, total_op_cost);
           if(msg.value > 0)
              payable(msg.sender).transfer(msg.value);
        }
        else{
            require(msg.value >= total_op_cost,"UNSUFFICIENT_BALANCE");
            uint256 remain_value = msg.value.sub(total_op_cost);
            payable(_merchant_addr).transfer(total_op_cost);
            payable(msg.sender).transfer(remain_value);
        }
    }
    function get_template_ids(uint256 page_index,uint256 per_page) external view virtual override returns (uint256[] memory){
        
        uint256 last_id = get_last_template_id();
        uint256 start_offset_counter = 1;
        uint256 start_offset = page_index.mul(per_page).add(1);
        
        uint256 start_id = 1;
        while((start_offset_counter < start_offset) && (start_id <= last_id)){
            if(is_defined(start_id))
                start_offset_counter = start_offset_counter.add(1);
            start_id = start_id.add(1);
        }
        
        if(start_id <= last_id){
            uint256 _counter = 0;
            uint256[] memory out_ids = new uint256[](per_page);
            uint256 _next_id = start_id;
            while(_next_id <= last_id && (_counter < per_page)){
                while(!is_defined(_next_id) && (_next_id <= last_id)){
                    _next_id = _next_id.add(1);
                }
                if(_next_id <= last_id)
                out_ids[_counter] = _next_id;
                _next_id = _next_id.add(1);
                _counter = _counter.add(1);
            }
            return out_ids;
        }
        return new uint256[](0);
    }
    function isTemplateValid(uint256) internal virtual returns (bool) {return false;}
    function onUndefineTemplate(uint256) internal virtual {}

    function get_template_metadata(uint256 template_id) external view virtual override returns (string memory,string memory,uint256,bool,address){
        return (template_names[template_id],template_descs[template_id],operation_prices[template_id],template_enabled[template_id],get_merchant_address(template_id));
    }
    function is_template_defined(uint256 template_id) external view virtual override returns (bool){return is_defined(template_id);}

    function is_template_enabled(uint256 template_id) external view virtual override returns (bool){return template_enabled[template_id];}

    function get_name() external view virtual override returns (string memory){return name;}

    function get_description() external view virtual override returns (string memory){return description;}

     function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ITokenOperatableTemplate).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}