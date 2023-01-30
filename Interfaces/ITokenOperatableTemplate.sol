// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenOperatableTemplate {
    
    function get_name() external view returns (string memory);

    function get_description() external view returns (string memory);

    function get_template_ids(uint256 page_index,uint256 per_page) external view returns (uint256[] memory);

    function get_template_metadata(uint256 template_id) external view returns (string memory,string memory,uint256,bool,address);

    function is_template_defined(uint256 template_id) external view returns (bool);

    function is_template_enabled(uint256 template_id) external view returns (bool);

    function get_token_contract() external view returns (address);
}