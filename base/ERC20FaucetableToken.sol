
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/IERC20FaucetableToken.sol";
import "../Interfaces/IFaucetable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC20FaucetableToken is  Ownable , IERC20FaucetableToken,ERC165
{
    using ERC165Checker for address;

    modifier onlyOwnerOrFaucetable(){
        bool _as_owner = (owner() == msg.sender);
        bool _as_faucetable = msg.sender.supportsInterface(type(IFaucetable).interfaceId) && IFaucetable(msg.sender).get_token_contract() == address(this) && allow_as_faucetable_contract(msg.sender);
        require(_as_owner || _as_faucetable,"NOT_FAUCETABLE");
        _;
    }
    function allow_as_faucetable_contract(address) internal view virtual returns (bool){return false;}
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20FaucetableToken).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
