// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../base/TokenOperatableTemplateContract.sol";
import "../Interfaces/IERC1155TokenContract.sol";
import "../Interfaces/IERC1155ForgeTemplates.sol";

contract ERC1155Forges is TokenOperatableTemplateContract,IERC1155ForgeTemplates
{
    using SafeMath for uint256;
    struct ForgeFormula {
        uint256 input_token_id;
        uint256 input_amount;
        uint256 output_token_id;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _templateIds;

    mapping(uint256 => ForgeFormula) private templates;
    event OnForgeFormulaDefined(uint256 template_id,ForgeFormula formula);
    event OnForgeFormulaUpdated(uint256 template_id,ForgeFormula formula);

    constructor(string memory name_,string memory description_,address token_contract_,address price_currency_contract_)
    TokenOperatableTemplateContract(name_,description_,token_contract_,price_currency_contract_) {
        
    }
    
    function fetch_token_contract_interface_id() internal virtual override returns(bytes4) {
       return type(IERC1155TokenContract).interfaceId;
    }
    function get_last_template_id() internal view virtual override returns (uint256) {return _templateIds.current();}

    function define_template(string memory name,string memory desc,uint256 input_token_id,uint256 input_amount,uint256 output_token_id,uint256 op_price,bool start_enabled,address merchant) external onlyOwner returns (uint256){
       return _define_template(name,desc,input_token_id,input_amount,output_token_id,op_price,start_enabled,merchant);
    }
    function define_templates(string[] memory names,string[] memory descs,uint256[] memory input_token_ids,uint256[] memory input_amounts,uint256[] memory output_token_ids,uint256[] memory op_prices,bool[] memory start_enabled,address[] memory merchants) external onlyOwner returns (uint256[] memory){
        uint256 tplcount = names.length;
        require((tplcount == descs.length) && (tplcount == input_token_ids.length) && (tplcount == input_amounts.length) && (tplcount == output_token_ids.length) && 
            (tplcount == op_prices.length) && (tplcount == start_enabled.length) && (tplcount == merchants.length),"PARAMS_DIM_MISMATCH");
        
        uint256[] memory tpl_ids = new uint256[](tplcount);
        for(uint256 i = 0; i < tplcount; i++)
            tpl_ids[i] = _define_template(names[i],descs[i],input_token_ids[i],input_amounts[i],output_token_ids[i],op_prices[i],start_enabled[i],merchants[i]);
        return tpl_ids;
    }    

    function forge(uint256 template_id,uint256 applyCount) external payable{
       require(applyCount > 0,"ZERO_APPLY_COUNT");
       address token_contract = get_token_contract_address();
       require(token_contract != address(0),"NO_TOKEN_CONTRACT");
       require(is_enabled(template_id),"TEMPLATE_DISABLED");
       require(_is_template_valid(templates[template_id],token_contract),"INVALID_TEMPLATE");

       ForgeFormula memory template = templates[template_id];
       IERC1155TokenContract(token_contract).burnNFTFor(msg.sender, template.input_token_id,template.input_amount.mul(applyCount));
       IERC1155TokenContract(token_contract).mintNFTFor(msg.sender, template.output_token_id, applyCount);
       consume_operation_cost(template_id,applyCount);
    }
    function _define_template(string memory name,string memory desc,uint256 input_token_id,uint256 input_amount,uint256 output_token_id,uint256 op_price,bool start_enabled,address merchant) internal returns (uint256){
        require(bytes(name).length > 0,"NO_TPL_NAME");        
        _templateIds.increment();
        uint256 tpl_id = _templateIds.current();
        _fill_template_metadata(tpl_id,name,desc,op_price,start_enabled,merchant);
        templates[tpl_id] = ForgeFormula(input_token_id,input_amount,output_token_id);
        emit OnForgeFormulaDefined(tpl_id,templates[tpl_id]);
        return tpl_id;
    }
    function onUndefineTemplate(uint256 template_id) internal virtual override{
        delete templates[template_id];
    }
    function udpate_template_formula(uint256 template_id,uint256 input_token_id,uint256 input_amount,uint256 output_token_id) external onlyOwner{
       _udpate_template_formula(template_id,input_token_id,input_amount,output_token_id);
    }
    function udpate_template_formulas(uint256[] memory template_ids,uint256[] memory input_token_ids,uint256[] memory input_amounts,uint256[] memory output_token_ids) external onlyOwner{
       uint256 tplcount = template_ids.length;
       require((tplcount == input_token_ids.length) && (tplcount == input_amounts.length) && (tplcount == output_token_ids.length) ,"PARAMS_DIM_MISMATCH");
       for(uint256 i = 0; i < tplcount; i++)
           _udpate_template_formula(template_ids[i],input_token_ids[i],input_amounts[i],output_token_ids[i]);
    }

    function udpate_template_input(uint256 template_id,uint256 input_token_id,uint256 input_amount) external onlyOwner{
       _update_template_input(template_id,input_token_id,input_amount);
    }
    function udpate_template_inputs(uint256[] memory template_ids,uint256[] memory input_token_ids,uint256[] memory input_amounts) external onlyOwner{
       uint256 tplcount = template_ids.length;
       require((tplcount == input_token_ids.length) && (tplcount == input_amounts.length) ,"PARAMS_DIM_MISMATCH");
       for(uint256 i = 0; i < tplcount; i++)
           _update_template_input(template_ids[i],input_token_ids[i],input_amounts[i]);
    }

    function udpate_template_output(uint256 template_id,uint256 output_token_id) external onlyOwner{
       _update_template_output(template_id,output_token_id);
    }
    function udpate_template_outputs(uint256[] memory template_ids,uint256[] memory output_token_ids) external onlyOwner{
       require(template_ids.length == output_token_ids.length,"PARAMS_DIM_MISMATCH");
       for(uint256 i = 0; i < template_ids.length; i++)
           _update_template_output(template_ids[i],output_token_ids[i]);
    }


    function _udpate_template_formula(uint256 template_id,uint256 input_token_id,uint256 input_amount,uint256 output_token_id) internal{
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        templates[template_id] = ForgeFormula(input_token_id,input_amount,output_token_id);
        emit OnForgeFormulaDefined(template_id,templates[template_id]);
    } 
    function _update_template_input(uint256 template_id,uint256 input_token_id,uint256 input_amount) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        require(input_amount > 0,"ZERO_AMOUNT");
        require(input_token_id > 0,"ZERO_TOKEN_ID");
        templates[template_id].input_token_id = input_token_id;
        templates[template_id].input_amount = input_amount;
    }
    function _update_template_output(uint256 template_id,uint256 output_token_id) internal {
        require(is_defined(template_id),"NO_TPL_DEFINED");        
        require(output_token_id > 0,"ZERO_TOKEN_ID");   
        templates[template_id].output_token_id = output_token_id;
    }

    function _is_template_valid(ForgeFormula memory template,address token_caddr) internal view returns(bool){
        if(template.input_amount == 0 || template.input_token_id == 0 || template.output_token_id == 0)
            return false;

        IERC1155TokenContract asCraftable = IERC1155TokenContract(token_caddr);
        return asCraftable.is_token_defined(template.input_token_id) && asCraftable.is_token_defined(template.output_token_id);
    }
    function get_template_formula(uint256 template_id) external view returns (uint256,uint256,uint256){
        return (templates[template_id].input_token_id,templates[template_id].input_amount,templates[template_id].output_token_id);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155ForgeTemplates).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}