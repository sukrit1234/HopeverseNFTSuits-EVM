// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./base/WhitelistMintableTokenBase.sol";
import "./Interfaces/IERC1155TokenContract.sol";
import "./Interfaces/IERC1155WhitelistMintable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Interfaces/IERC1155Whitelist.sol";

/* Required Interface for Gaming SDK.
    + ownedTokenOf(_addr_) => Get list of TokenIds and Amounts that owned by _addr_.
    + tokenURI(tokenId) => Get link to metadata for Token Id.
    + updateTokenURI(tokenId,URI) => Set link to metadata for Token Id.
    + totalSupply(tokenId) => Get current total supply for tokenId.
    + maxSupply(tokenId) => Get max supply for tokenId.
*/

contract ERC1155Token is  ERC1155Supply , Pausable , WhitelistMintableTokenBase , IERC1155TokenContract , IERC1155WhitelistMintable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    Counters.Counter private _tokenIds;
    string private _contractURI;
    string private _name;
    string private _symbol;


    mapping(uint256 => string) private _token_uris;

    constructor(string memory name_,string memory symbol_ ,string memory main_uri_) 
        ERC1155(main_uri_){
            _name = name_;
            _symbol = symbol_;
        }

    //Token id => max supply.
    mapping (uint256 => uint256) private _token_maxsupply;

    //On Token base URI updated.
    event OnBaseURIUpdated(string tokenUri);
    
    //On Token base URI updated.
    event OnTokenURIUpdated(uint256 tokenId,string tokenUri);

    //On Token Max Supply updated.
    event OnTokenMaxSupplyUpdated(uint256 tokenId,uint256 maxSupply);

    function contractURI() public view returns (string memory) {return _contractURI;}
    function setContractURI(string memory contractURI_) external virtual override onlyOwner {
        _contractURI = contractURI_;
    }
    function maxSupply(uint256 id) public view virtual returns (uint256) {
        return _token_maxsupply[id];
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(!paused(), "PAUSED");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
       bytes memory uri_as_bytes = bytes(_token_uris[tokenId]); // Uses memory
       return (uri_as_bytes.length > 0) ? _token_uris[tokenId] : super.uri(tokenId);
    }
    function lastTokenIds() external view virtual override returns (uint256){return _tokenIds.current();}
    
    function isTokenDefineForWhitelist(uint256 token_id) external view override returns (bool){return (maxSupply(token_id) > 0);}
 
    function is_token_defined(uint256 token_id) external view returns (bool){return (maxSupply(token_id) > 0);}
 
    /*Whitelist mint call by owner or Whitelist contract*/
    function whitelistMint(address _addr,uint256 tokenId,uint256 amount) external virtual override onlyOwnerOrWLContract {
        require(totalSupply(tokenId).add(amount) <= _token_maxsupply[tokenId],"Max Supply Overflow");
        _mint(_addr, tokenId, amount, "");
    }
    function mintNFTsFor(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external virtual override onlyOwnerAndOperatableTemplate {
        require(_isAllPassMaxSupply(tokenIds,amounts),"OVERFLOW");
        _mintBatch(_addr, tokenIds, amounts, "");
    }
    function burnNFTsFor(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external virtual override onlyOwnerAndOperatableTemplate {
        require(_isAllPassBalanceOf(_addr,tokenIds,amounts),"INSUFFICIENT");
        _burnBatch(_addr, tokenIds, amounts);
    }
    function mintNFTFor(address _addr,uint256 tokenId,uint256 amount) external virtual override onlyOwnerAndOperatableTemplate {
        require(totalSupply(tokenId).add(amount) <= _token_maxsupply[tokenId],"OVERFLOW");
        _mint(_addr, tokenId, amount, "");
    }
    function burnNFTFor(address _addr,uint256 tokenId,uint256 amount) external virtual override onlyOwnerAndOperatableTemplate {
        require(amount <= balanceOf(_addr, tokenId),"INSUFFICIENT");
        _burn(_addr, tokenId, amount);
    }
    function updateTokenURI(uint256 tokenId,string memory newTokenUri) external virtual onlyOwner {
       
       _token_uris[tokenId] = newTokenUri;
       emit OnTokenURIUpdated(tokenId,newTokenUri);
    }
    function updateMaxSupply(uint256 tokenId,uint256 newMaxSupply) external onlyOwner{

        uint256 _curSupply = totalSupply(tokenId);
        _token_maxsupply[tokenId] = (newMaxSupply >= _curSupply) ? newMaxSupply : _curSupply;
        emit OnTokenMaxSupplyUpdated(tokenId,newMaxSupply);
    }
    function defineTokens(uint256[] memory maxSupplies,string[] memory tokenUris) external onlyOwner returns (uint256[] memory){
        require(tokenUris.length == maxSupplies.length,"PARAM_DIM_MISMATCH");
        uint256[] memory _outIds = new uint256[](maxSupplies.length);
        for(uint256 i = 0; i < maxSupplies.length; i++){
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _token_maxsupply[newTokenId] = maxSupplies[i];
            _token_uris[newTokenId] = tokenUris[i];
            _outIds[i] = newTokenId;
            emit OnTokenMaxSupplyUpdated(newTokenId,maxSupplies[i]);
        }
        return _outIds;
    }
    function setTokenUri(string memory tokenUri) external onlyOwner{
        _setURI(tokenUri);
        emit OnBaseURIUpdated(tokenUri);
    }
    function ownedTokenOf(address _addr) external view virtual override returns(uint256[] memory,uint256[] memory){
        uint256 counter = 0;
        uint256 lastTokenId = _tokenIds.current();
        uint256[] memory _outIds = new uint256[](lastTokenId);
        uint256[] memory _outBalances = new uint256[](lastTokenId);
        for(uint256 tId = 1; tId <= lastTokenId; tId++){
            if(balanceOf(_addr,tId) > 0){
                _outIds[counter] = tId;
                _outBalances[counter] = balanceOf(_addr,tId);
                counter++;
            }
        }
        return (_outIds,_outBalances);
    }
    function canMintForAmount(uint256 tokenId,uint256 tokmentAmount) external view returns(bool){
        return _isPassMaxSupply(tokenId,tokmentAmount);
    }
    function canMintBulkForAmount(uint256[] memory tokenIds,uint256[] memory tokmentAmounts) external view returns(bool){
        return _isAllPassMaxSupply(tokenIds,tokmentAmounts);
    }
    function _isPassMaxSupply(uint256 tokenId,uint256 toMintAmount) internal view returns (bool){
        return totalSupply(tokenId).add(toMintAmount) <= _token_maxsupply[tokenId];
    }
    function _isAllPassMaxSupply(uint256[] memory tokenIds,uint256[] memory toMintAMounts) internal view returns (bool){
        for(uint256 i = 0; i < tokenIds.length; i++){
            if(totalSupply(tokenIds[i]).add(toMintAMounts[i]) > _token_maxsupply[tokenIds[i]])
                return false;
        }
        return true;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155TokenContract).interfaceId ||
            interfaceId == type(IERC1155WhitelistMintable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function _isAllPassBalanceOf(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) internal view returns(bool){
        for(uint256 i = 0; i < tokenIds.length; i++){
            if(amounts[i] > balanceOf(_addr, tokenIds[i]))
                return false;
        }
        return true;
    }
    function getTokenIds(uint256 page_index,uint256 per_page) external view virtual override returns (uint256[] memory){
        
        uint256 start = page_index.mul(per_page).add(1);
        uint256 end = start.add(per_page);

        if(start <= _tokenIds.current()){
            uint256[] memory _outIds = new uint256[](per_page);
            end = (_tokenIds.current() < end) ? _tokenIds.current() : end;
            uint256 counter = 0;
            for(uint256 i = start; i <= end; i++){
                _outIds[counter] = i;
                counter++;
            }
            return _outIds;
        }
        return new uint256[](0);
    }
}