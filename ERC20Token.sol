// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces/IERC20TokenContract.sol";
import "./Interfaces/IERC20WhitelistMintable.sol";
import "./base/WhitelistMintableTokenBase.sol";
import "./base/ERC20FaucetableToken.sol";
contract ERC20Token is ERC20 , WhitelistMintableTokenBase , IERC20TokenContract,IERC20WhitelistMintable , ERC20FaucetableToken , Pausable {
   
    using SafeMath for uint256;
    uint256 private _maxSupply;
    uint8 private _decimals;
    event OnMaxSupplyChange(uint256 newMaxSupply);

    constructor(string memory name_,string memory symbol_,uint8 decimals_,uint256 initialSupply_,uint256 maxSupply_)
        ERC20(name_, symbol_) {
        _maxSupply = maxSupply_;
        _decimals = decimals_;
        if(initialSupply_ > 0){
            require(canMintForAmount(initialSupply_),"Reach Max Supply Limit");
            _mint(msg.sender, initialSupply_);
        }
    }
    function whitelistMint(address _addr,uint256 amount) external virtual override onlyOwnerOrWLContract{
        _mint(_addr, amount);
    }
    function whitelistTrimAmountWithMaxSupply(uint256 toMintAmount) external view virtual override returns (uint256){
        uint256 curSupply = totalSupply();
        return (curSupply.add(toMintAmount) > _maxSupply) ? (_maxSupply.sub(curSupply)) : toMintAmount;
    }

    function _mint_for(address _addr,uint256 _amount) internal {
        require(_amount > 0,"Zero mint amount");
        require(canMintForAmount(_amount),"Reach Max Supply Limit");
        _mint(_addr, _amount);
    }
    function _burn_for(address _addr,uint256 _amount) internal{
         require(_amount > 0,"Zero burnt amount");
        _burn(_addr,_amount);
    }

    function mintFor(address _addr,uint256 _amount) external virtual override onlyOwnerAndOperatableTemplate{
       _mint_for(_addr,_amount);
    }
    function burnFor(address _addr,uint256 _amount) external virtual override onlyOwnerAndOperatableTemplate{
        _burn_for(_addr,_amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    function maxSupply() public view virtual override returns (uint256){
        return _maxSupply;
    }
    function changeMaxSupply(uint256 _newMaxSupply) external onlyOwner{
        _maxSupply = _newMaxSupply;
        emit OnMaxSupplyChange(_maxSupply);
    }
    function canMintForAmount(uint256 toMintAmount) public view virtual override returns(bool){
        uint256 newTotalSupply = totalSupply().add(toMintAmount);
        return newTotalSupply <= _maxSupply;
    }
    function remainFromMaxSupply() external view virtual override returns (uint256){
        return (totalSupply() < _maxSupply) ? _maxSupply.sub(totalSupply()) : 0;
    }
    function getMetadata() external view virtual override  returns (uint256,uint256,uint8,string memory){
        return (totalSupply(),_maxSupply,_decimals,symbol());
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "Is Paused!");
    }

    function request_faucet_for(address to_address,uint256 amount) external onlyOwnerOrFaucetable{
        _mint_for(to_address,amount);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20TokenContract).interfaceId ||
            interfaceId == type(IERC20WhitelistMintable).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function allow_as_faucetable_contract(address _addr_) internal view virtual override returns (bool){
        return is_cooperative_contract(_addr_);
    }
}