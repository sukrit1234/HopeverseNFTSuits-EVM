// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../base/TokenOperatableTemplateContract.sol";
import "../Interfaces/IERC1155TokenContract.sol";
import "../Interfaces/IERC1155CraftTemplates.sol";

contract ERC1155Crafts is TokenOperatableTemplateContract,IERC1155CraftTemplates {
    using SafeMath for uint256;

    struct CraftElement{
        uint256 token_id;
        uint256 amount;
    }
    
    struct CraftFormula {
        CraftElement[] inputs;
        CraftElement[] outputs;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _templateIds;

    mapping(uint256 => CraftFormula) private templates;
    event OnCraftFoumulaDefined(uint256 template_id,CraftFormula formula);
    event OnCraftFormulaUpdated(uint256 template_id,CraftFormula formula);

    constructor(string memory name_,string memory description_,address token_contract_,address price_currency_contract_)
    TokenOperatableTemplateContract(name_,description_,token_contract_,price_currency_contract_) {
        
    }

    function fetch_token_contract_interface_id() internal virtual override returns(bytes4) {
       return type(IERC1155TokenContract).interfaceId;
    }
    function get_last_template_id() internal view virtual override returns (uint256) {return _templateIds.current();}

    function define_template(string memory name,string memory desc,uint256 op_price,bool start_enabled,address merchant,uint256[] memory input_token_ids,uint256[] memory input_amounts,uint256[] memory output_token_ids,uint256[] memory output_amounts) external onlyOwner returns (uint256){        
        require(bytes(name).length > 0,"NO_NAME");

        uint256 input_count = input_token_ids.length;
        require(input_count > 0,"NO_INPUTS");
        require(input_count == input_amounts.length,"INPUT_DIM_MISMATCH");

        uint256 output_count = output_token_ids.length;
        require(output_count > 0,"NO_OUTPUT");
        require(output_count == output_amounts.length,"OUTPUT_DIM_MISMATCH");

        _templateIds.increment();
        uint256 tpl_id = _templateIds.current();
        _fill_template_metadata(tpl_id,name,desc,op_price,start_enabled,merchant);
        
        for(uint256 i = 0; i < input_count; i++)
            templates[tpl_id].inputs.push(CraftElement(input_token_ids[i],input_amounts[i]));
       
        for(uint256 i = 0; i < output_count; i++)
            templates[tpl_id].outputs.push(CraftElement(output_token_ids[i],output_amounts[i]));
        
        emit OnCraftFoumulaDefined(tpl_id,templates[tpl_id]);
        return tpl_id;
    }
    function udpate_template_formula(uint256 template_id,uint256[] memory input_token_ids,uint256[] memory input_amounts,uint256[] memory output_token_ids,uint256[] memory output_amounts) external onlyOwner {
        require(is_defined(template_id),"NOT_DEFINED");

        uint256 input_count = input_token_ids.length;
        require((input_count > 0) && (input_count == input_amounts.length),"INPUT_DIM_MISMATCH");

        uint256 output_count = output_token_ids.length;
        require((output_count > 0) && (output_count == output_amounts.length),"OUTPUT_DIM_MISMATCH");

        delete templates[template_id].inputs;
        delete templates[template_id].outputs;

        for(uint256 i = 0; i < input_count; i++)
            templates[template_id].inputs.push(CraftElement(input_token_ids[i],input_amounts[i]));
        
        for(uint256 i = 0; i < output_count; i++)
            templates[template_id].outputs.push(CraftElement(output_token_ids[i],output_amounts[i]));
            
        emit OnCraftFormulaUpdated(template_id,templates[template_id]);
    }

    function update_template_input(uint256 template_id,uint256 input_token_id,uint256 input_amount) external onlyOwner{
        require(is_defined(template_id),"NOT_DEFINED");
        _update_template_input(template_id,input_token_id,input_amount);
    }
    function update_template_output(uint256 template_id,uint256 output_token_id,uint256 output_amount) external onlyOwner{
        require(is_defined(template_id),"NOT_DEFINED");
        _update_template_output(template_id,output_token_id,output_amount);
    }

    function update_template_inputs(uint256 template_id,uint256[] memory input_token_ids,uint256[] memory input_amounts) external onlyOwner{
        require(is_defined(template_id),"NOT_DEFINED");
        uint256 input_count = input_token_ids.length;
        require(input_count == input_amounts.length,"INPUT_DIM_MISMATCH");
        for(uint256 i = 0; i < input_count; i++)
           _update_template_input(template_id,input_token_ids[i],input_amounts[i]);
    }
    function update_template_outputs(uint256 template_id,uint256[] memory output_token_ids,uint256[] memory output_amounts) external onlyOwner{
        require(is_defined(template_id),"NOT_DEFINED");
        uint256 output_count = output_token_ids.length;
        require(output_count == output_amounts.length,"OUTPUT_DIM_MISMATCH");
        for(uint256 i = 0; i < output_count; i++)
           _update_template_output(template_id,output_token_ids[i],output_amounts[i]);
    }
    function craft(uint256 template_id,uint256 applyCount) external payable{
       require((applyCount > 0),"ZERO_APPLY_COUNT");
       address token_contract = get_token_contract_address();
       require((token_contract != address(0)),"NO_TOKEN_CONTRACT");
       require(is_enabled(template_id),"TEMPLATE_DISABLED");
       require(_is_template_valid(templates[template_id],token_contract),"INVALID_TEMPLATE");

       IERC1155TokenContract asCraftable = IERC1155TokenContract(token_contract);
       CraftFormula memory template = templates[template_id];
       for(uint8 i = 0; i < template.inputs.length; i++)
            asCraftable.burnNFTFor(msg.sender, template.inputs[i].token_id,template.inputs[i].amount.mul(applyCount));
       for(uint8 i = 0; i < template.outputs.length; i++)
            asCraftable.mintNFTFor(msg.sender, template.outputs[i].token_id,template.outputs[i].amount.mul(applyCount));       
        consume_operation_cost(template_id,applyCount);
    }
    function _update_template_input(uint256 template_id,uint256 input_token_id,uint256 input_amount) internal {
        require((input_amount > 0) && (input_token_id > 0),"INVALID_INPUT");
        uint256 input_count = templates[template_id].inputs.length;
        for(uint256 i = 0; i < input_count; i++){
            if(templates[template_id].inputs[i].token_id == input_token_id){
                templates[template_id].inputs[i].amount = input_amount;
                return;
            }
        }
        templates[template_id].inputs.push(CraftElement(input_token_id,input_amount));
    }
    function _update_template_output(uint256 template_id,uint256 output_token_id,uint256 output_amount) internal {
        require((output_amount > 0) && (output_token_id > 0),"INVALID_OUTPUT");
        uint256 output_count = templates[template_id].outputs.length;
        for(uint256 i = 0; i < output_count; i++){
            if(templates[template_id].outputs[i].token_id == output_token_id){
                templates[template_id].outputs[i].amount = output_amount;
                return;
            }
        }
        templates[template_id].outputs.push(CraftElement(output_token_id,output_amount));
    }
    function onUndefineTemplate(uint256 template_id) internal virtual override{
        delete templates[template_id];
    }
    function _is_template_valid(CraftFormula memory template,address token_caddr) internal view returns(bool){
        if(template.inputs.length == 0 || template.outputs.length == 0)
            return false;

        IERC1155TokenContract asCraftable = IERC1155TokenContract(token_caddr);
        for(uint8 i = 0; i < template.inputs.length; i++){
            if(template.inputs[i].amount == 0 || (!asCraftable.is_token_defined(template.inputs[i].token_id)))
                return false;
        }
         for(uint8 i = 0; i < template.outputs.length; i++){
            if(template.outputs[i].amount == 0 || (!asCraftable.is_token_defined(template.outputs[i].token_id)))
                return false;
        }
        return true;
    }
    function get_template_formula(uint256 template_id) external view returns (uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
       CraftFormula memory template = templates[template_id];
       uint256 input_count = template.inputs.length;
       uint256[] memory _input_token_ids = new uint256[](input_count);
       uint256[] memory _input_amounts = new uint256[](input_count);
       for(uint8 i = 0; i < input_count; i++){
            _input_token_ids[i] = template.inputs[i].token_id;
            _input_amounts[i] = template.inputs[i].amount;
       }

       uint256 output_count = template.outputs.length;
       uint256[] memory _output_token_ids = new uint256[](output_count);
       uint256[] memory _output_amounts = new uint256[](output_count);
       for(uint8 i = 0; i < output_count; i++){
            _output_token_ids[i] = template.outputs[i].token_id;
            _output_amounts[i] = template.outputs[i].amount;
       }
       return (_input_token_ids,_input_amounts,_output_token_ids,_output_amounts);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155CraftTemplates).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}