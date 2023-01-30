// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/ITokenOperatableTemplate.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

abstract contract Cooperatable is Ownable 
{
    using ERC165Checker for address;
    
    mapping (address => bool) cooperative_contracts;

    function add_cooperative(address contract_addr) external onlyOwner{
        cooperative_contracts[contract_addr] = true;
    }
    function add_cooperatives(address[] memory contract_addrs) external onlyOwner {
        for(uint256 i = 0; i < contract_addrs.length; i++)
            cooperative_contracts[contract_addrs[i]] = true;
    }

    function remove_cooperative(address contract_addr) external onlyOwner {
        delete cooperative_contracts[contract_addr];
    }
    function remove_cooperatives(address[] memory contract_addrs) external onlyOwner{
        for(uint256 i = 0; i < contract_addrs.length; i++)
           delete cooperative_contracts[contract_addrs[i]];
    }
    function is_cooperative_contract(address _addr) internal view returns (bool){return cooperative_contracts[_addr];}
    modifier onlyOwnerAndOperatableTemplate(){
        bool _as_owner = owner() == msg.sender;
        bool _as_operatable_template = msg.sender.supportsInterface(type(ITokenOperatableTemplate).interfaceId) && ITokenOperatableTemplate(msg.sender).get_token_contract() == address(this) && is_cooperative_contract(msg.sender);
        require(_as_owner || _as_operatable_template,"NOT_OPERATABLE_TEMPLATE");
        _;
    }
}
