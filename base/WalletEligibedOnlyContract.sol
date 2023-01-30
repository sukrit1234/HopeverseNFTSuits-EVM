// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Util/Cooperatable.sol";
import "./WhitelistContractBase.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

abstract contract WalletEligibedOnlyContract {
    
    address[] private _wallets;
    uint256 private wallet_count = 0;
    mapping(address => uint256) private _wallet_indics;

    constructor(uint256 max_addresses) {
        _wallets = new address[](max_addresses);
    }
    
    function _add_whitelist_wallets(address[] memory wallets) internal {
        for(uint256 i = 0; i < wallets.length;i++){
           _add_whitelist_wallet(wallets[i]);
        }
    }
    function _add_whitelist_wallet(address addr) internal {
        if(_add_wallet(addr)){
            onWhitelistWalletAdded(addr);
        }
    }
    function _remove_whitelist_wallet(address addr) internal {
        if(_remove_wallet(addr)){
           onWhitelistWalletRemoved(addr);
        }
    }
    function _add_wallet(address addr) internal returns (bool){
        if(_wallet_indics[addr] == 0){
            _wallets[wallet_count] = addr;
            wallet_count++;
            _wallet_indics[addr] =wallet_count;
            return true;
        }
        return false;
    }
    //Use remove swap to prevent hold (address(0)) wallet in array.
    function _remove_wallet(address addr) internal returns (bool){
        if(_wallet_indics[addr] > 0){
            
            uint256 index = _wallet_indics[addr];
            _wallet_indics[addr] = 0;
            _wallets[index - 1] = address(0);

            if(wallet_count > 0){
                address _last_wallet = _wallets[wallet_count - 1];
                _wallets[index - 1] = _last_wallet;
                _wallet_indics[_last_wallet] = index;
                _wallets[wallet_count - 1] = address(0);
                wallet_count--;
            }
            return true;
        }
        return false;
    }

    function get_wallet_count() public view returns(uint256) {return wallet_count;}
    function get_wallet_address(uint256 index) public view returns(address){return _wallets[index];}
    function has_wallet(address addr) public view returns(bool){return (_wallet_indics[addr] > 0);}
    function get_wallets() public view returns (address[] memory){return _wallets;}
    
    //Invoke after whitelist wallet added
    function onWhitelistWalletAdded(address addr) internal virtual {}

    //Invoke after whitelist wallet removed
    function onWhitelistWalletRemoved(address addr) internal virtual {}

}