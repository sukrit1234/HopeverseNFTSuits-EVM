// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces/IERC721TokenContract.sol";
import "./Interfaces/IERC721WhitelistMintable.sol";
import "./base/WhitelistMintableTokenBase.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Interfaces/IERC721Whitelist.sol";

/* Required Interface
    + ownedTokenOf(_addr_) => Get list of TokenId that owned by _addr_.
    + tokenURI(tokenId) => Get link to metadata for Token Id.
    + updateTokenURI(tokenId,URI) => Set link to metadata for Token Id.
    + totalSupply() => Get current total supply.
    + maxSupply() => Get max supply for ERC20 token.
*/

contract ERC721Token is ERC721URIStorage, Pausable, WhitelistMintableTokenBase , IERC721TokenContract,IERC721WhitelistMintable 
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    Counters.Counter private _tokenIds;
 
    string private _contractURI;
    uint256 private _max_supply;
    uint256 private _token_id_interleave_count = 0;

    string private _unreveal_name;
    string private _unreveal_token_uri;

    //Event when NFT updated.
    event TokenURIUpdated(uint256 tokenId,string tokenURI);
    event TokenMinted(address indexed addr,uint256 tokenId,string tokenURI);
    event TokenBurnt(address indexed addr,uint256 tokenId);
 
    constructor(string memory name_, string memory symbol_,uint256 max_supply_,string memory unreveal_name_,string memory unreveal_token_uri_) 
        ERC721(name_, symbol_){
        _max_supply = max_supply_;
        _unreveal_name = bytes(unreveal_name_).length > 0 ? unreveal_name_ : name_;
        _unreveal_token_uri = unreveal_token_uri_;
    }
    
    function contractURI() public view returns (string memory) {return _contractURI;}
    function setContractURI(string memory contractURI_) external virtual override onlyOwner {
        _contractURI = contractURI_;
    }
    function updateMaxSupply(uint256 max_supply_) external onlyOwner {
        uint256 lastTokenID = _tokenIds.current();
        _max_supply = (max_supply_ <= lastTokenID) ?  lastTokenID : max_supply_;
    }
    function maxSupply() public view virtual returns (uint256) {
        return _max_supply;
    }
    function totalSupply() public view returns (uint) {
        //Get current total supply.
        return (_tokenIds.current() - _token_id_interleave_count);
    }
    //Get Token Ids that owned by _addr
    function ownedTokenOf(address _addr) external virtual override view returns(uint256[] memory){
    
        require(_addr != address(0), "Null address");
    
        //Get item amount of address
        uint256 ownedItemAmount = balanceOf(_addr);
        
        //Allocation owned item buffer as memory to return.
        uint256[] memory outTokenIds = new uint256[](ownedItemAmount);
        
        //If addr owned one of token.
        if(ownedItemAmount > 0)
        {
            //Get last id - lastest id that NFT minted.
            uint256 lastId = _tokenIds.current();

            //Prepare counter.
            uint256 counter = 0;
            for (uint256 tId = 1; tId <= lastId; tId++) 
            {
                //If owner of token same as address.
                if(_ownerOf(tId) == _addr)
                {
                    outTokenIds[counter] = tId;
                    counter++;
                }
            }
        } 
        return outTokenIds;
    }
    function isOwnedToken(address _addr,uint256 tokenId) external virtual override view returns(bool){
        require(_addr != address(0),"Null address");
        return _ownerOf(tokenId) == _addr;
    }
    function isTokenExists(uint256 tokenId) external view returns(bool){
        return _exists(tokenId);
    }
    
    function updateUnrevealName(string memory name) external virtual onlyOwner{ _unreveal_name = name;}   
    
    function updateUnrevealTokenUri(string memory token_uri) external virtual onlyOwner{_unreveal_token_uri = token_uri;}
    
    function getUnrevealName() external view virtual override returns (string memory){return _unreveal_name;}
    
    function getUnrevealTokenUri() external view virtual override returns (string memory){return _unreveal_token_uri;}

    function getUnrevealMetadata() external view returns (string memory,string memory){return (_unreveal_name,_unreveal_token_uri);}

    function updateTokenURI(uint256 tokenId,string memory tokenURI) external virtual override onlyOwner {
        //Edit new tokenURI for token id.
        _setTokenURI(tokenId, tokenURI);

        //Emit token URI updated.
        emit TokenURIUpdated(tokenId,tokenURI);
    }
    function mintNFTsFor(address addr,uint256 amount) external virtual override onlyOwnerAndOperatableTemplate{
        for(uint256 i = 0; i < amount; i++){
            uint256 token_id = _mintNewNFT(addr,_unreveal_token_uri);
            emit TokenMinted(addr,token_id,_unreveal_token_uri); 
        }
    }
    function mintNFTFor(address addr,string memory tokenUri) external virtual override onlyOwnerAndOperatableTemplate {
        bytes memory uri_as_bytes = bytes(tokenUri);
        string memory _uri = (uri_as_bytes.length > 0) ? _unreveal_token_uri : tokenUri;
        uint256 token_id = _mintNewNFT(addr,_uri);
        emit TokenMinted(addr,token_id,_uri);        
    }
    function burnNFTFor(address addr,uint256 tokenId) external virtual override onlyOwnerAndOperatableTemplate {
        require(addr != address(0),"NULL_ADDR");
        require(_ownerOf(tokenId) == addr,"NOT_OWNER");
        _burn(tokenId);
        emit TokenBurnt(addr,tokenId);
    }
    function whitelistMint(address addr,uint256 amount) external virtual override onlyOwnerOrWLContract returns (uint256[] memory) {
        uint256[] memory _minted_ids = new uint256[](amount);
        for(uint256 i = 0; i < amount; i++){
           _minted_ids[i] = _mintNewNFT(addr,_unreveal_token_uri);
        }
        return _minted_ids;
    }

    //First of all try to reuse burnt or not exist id.
    function find_unused_token_id() internal view returns (uint256){ 
        if(_token_id_interleave_count == 0)
            return 0;
        uint256 last_id = _tokenIds.current();
        for(uint256 i = 1; i <= last_id; i++){
            if(!_exists(i))
                return i;
        }
        return 0;
    }
    function _mintNewNFT(address _addr,string memory tokenUri) internal returns (uint256){
        
        require(_isPassMaxSupply(1),"OVERFLOW");
        
       uint256 newTokenId = 0;
       
       //Try to find unuse (burnt) token id for reuse.
       uint256 to_recycle_id = find_unused_token_id();
        if(to_recycle_id > 0) //If found - use it.
            newTokenId = to_recycle_id;
        else{
            //Increase to next token id.
            _tokenIds.increment();
            //Now got new token id.
            newTokenId = _tokenIds.current();
        }
        
        require(newTokenId > 0,"INVALID_ID");

         //Mint token to minter as newItemId.
        _safeMint(_addr, newTokenId);

        //Set metadata tokenURI new token id.
        _setTokenURI(newTokenId, tokenUri);
        
        if(to_recycle_id > 0) //Reduce interleave if recycle burnt token id.
            _token_id_interleave_count.sub(1);

        //return token id.
        return newTokenId;
    }
    function _isPassMaxSupply(uint256 toMintAmount) internal view returns (bool){
        return totalSupply().add(toMintAmount) <= _max_supply;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId,batchSize);
        require(!paused(), "Is Paused!");
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721TokenContract).interfaceId ||
            interfaceId == type(IERC721WhitelistMintable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function getTokenIds(uint256 page_index,uint256 per_page) external view returns (uint256[] memory){
        
        uint256 last_id = _tokenIds.current();
        uint256 start_offset_counter = 1;
        uint256 start_offset = page_index.mul(per_page).add(1);
        
        uint256 start_id = 1;
        while((start_offset_counter < start_offset) && (start_id <= last_id)){
            if(_exists(start_id))
                start_offset_counter = start_offset_counter.add(1);
            start_id = start_id.add(1);
        }
        
        if(start_id <= last_id){
            uint256 _counter = 0;
            uint256[] memory out_ids = new uint256[](per_page);
            uint256 _next_id = start_id;
            while(_next_id <= last_id && (_counter < per_page)){
                while(!_exists(_next_id) && (_next_id <= last_id)){
                    _next_id = _next_id.add(1);
                }
                if(_next_id <= last_id)
                out_ids[_counter] = _next_id;
                _next_id = _next_id.add(1);
                _counter = _counter.add(1);
            }
            return out_ids;
        }
        return new uint256[](0);
    }
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _token_id_interleave_count = _token_id_interleave_count.add(1);
    }
}
