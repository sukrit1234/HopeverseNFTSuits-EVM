// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/IAccountVault.sol";

contract AccountVault is Ownable ,IAccountVault {

    mapping (address => address) private _links;
    string private _VaultName;

    //Event when personal account link to game account.
    event OnAccountLinked(address indexed inDappAddress, address indexed personalAddress);

    //Event when personal account unlink from game account.
    event OnAccountUnlinked(address indexed inDappAddress, address indexed personalAddress);

    constructor(string memory _name) {
        _VaultName = _name;
    }
    function getVaultName() external view virtual override returns (string memory) {
        return _VaultName;
    }
    function linkedAddressOf(address _inDappAddr) external view virtual override returns (address){
        return _links[_inDappAddr];
    }
    function hasLinkAddressOf(address _inDappAddr) external view virtual override returns (bool){
         return _links[_inDappAddr] != address(0);
    }
    function isAccountLinked(address _inDappAddr,address _personalAddr) external view virtual override returns (bool){
        return _links[_inDappAddr] == _personalAddr && (_personalAddr != address(0));
    }

    function linkToAddress(address _inDappAddr) external virtual override {
        require(_links[_inDappAddr] == address(0),"Account already linked");
        require(msg.sender != address(0),"Zero or Null address is not allowed.");
        _links[_inDappAddr] = msg.sender;
         emit OnAccountLinked(_inDappAddr,msg.sender);
    }

    function unlinkFromAddress(address _inDappAddr) external virtual override {
        require(_links[_inDappAddr] == msg.sender,"Linked account mismatch can't unlink");
        require(msg.sender != address(0),"Zero or Null address is not allowed.");
        _links[_inDappAddr] = address(0);
        emit OnAccountUnlinked(_inDappAddr,msg.sender);
    }
}