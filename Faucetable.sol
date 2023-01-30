// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces/IERC20FaucetableToken.sol";
import "./Interfaces/IFaucetable.sol";
import "./Interfaces/IERC20TokenContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract Faucetable is Ownable,IFaucetable,ERC165  {

    using ERC165Checker for address;
    using SafeMath for uint256;

    string private name;
    uint256 private fauncet_remain_amount;
    uint256 private amount_per_request;
    address private token_contract = address(0);
    bytes4 constant private token_constract_interface_id = type(IERC20FaucetableToken).interfaceId;


    constructor(string memory name_,uint256 amount_per_request_,uint256 init_amount,address token_contract_) {
        name = name_;
        amount_per_request = amount_per_request_;
        fauncet_remain_amount = init_amount;
        _set_token_contract_internal(token_contract_);
    }

    function _set_token_contract_internal(address addr) internal{
        require(addr.supportsInterface(token_constract_interface_id),"UNSUPPORT_FAUCET");
        token_contract = addr;
    }
    function set_token_contract(address addr) external onlyOwner {
        _set_token_contract_internal(addr);
    }
    function set_amount_per_request(uint256 amount) external onlyOwner {amount_per_request = amount;}
    
    function get_token_contract_address() public view returns (address) {  return token_contract;}

    function get_token_contract() external view override returns (address){return token_contract;}
    
    function get_amount_per_request() external view returns (uint256){return amount_per_request;}

    function get_remain_faucet_amount() external view returns (uint256){return fauncet_remain_amount;}

    //Refill faucet.
    function refill_faucet(uint256 amount) external virtual override onlyOwner{
        require(token_contract != address(0),"NO_TOKEN");
        require(token_contract.supportsInterface(type(IERC20).interfaceId),"NOT_IERC20");
        require(token_contract.supportsInterface(type(IERC20TokenContract).interfaceId),"NOT_IERC20TokenContract");
        require(IERC20(token_contract).totalSupply().add(amount) <= IERC20TokenContract(token_contract).maxSupply(),"OVERFLOW_MAXSUPPLY");
        fauncet_remain_amount = fauncet_remain_amount.add(amount);
    }
    function request_faucet() external virtual override {
        require(amount_per_request > 0,"NO_AMOUNT_PER_REQUEST");
        require(fauncet_remain_amount >= amount_per_request,"NO_FAUCET_REMAIN");
        require(token_contract != address(0),"NO_TOKEN");
        IERC20FaucetableToken(token_contract).request_faucet_for(msg.sender, amount_per_request);
        fauncet_remain_amount = fauncet_remain_amount.sub(amount_per_request);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IFaucetable).interfaceId || super.supportsInterface(interfaceId);
    }
}