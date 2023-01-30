// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Util/Cooperatable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../Interfaces/IWhitelistContract.sol";

abstract contract WhitelistMintableTokenBase is Cooperatable 
{
    using ERC165Checker for address;

    modifier onlyOwnerOrWLContract(){
        bool _as_owner = (owner() == msg.sender);
        bool _as_whitelist = msg.sender.supportsInterface(type(IWhitelistContract).interfaceId) && IWhitelistContract(msg.sender).get_token_contract() == address(this) && is_cooperative_contract(msg.sender);
        require(_as_owner || _as_whitelist,"NOT_WHITELIST");
        _;
    }
    
}
