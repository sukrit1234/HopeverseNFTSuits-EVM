// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155Whitelist {
    
    /*Mint funcitons*/
    function mint(uint256 token_id,uint256 amount) external payable;

    /*Return mintable (token_ids,minted amount,quotas,prices)*/
    function get_mintable_items() external view returns (uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory);

    /*Return token (remain and total) amount for address */
    function get_token_minted_state(address addr,uint256 token_id) external view returns (uint256,uint256);
}