// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenContract {

     //Get Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external view returns (string memory);
    
    //Set Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory contractURI_) external;

    function lastTokenIds() external view returns (uint256);
    
    //Return token ids and amount.
    function ownedTokenOf(address _addr) external view returns(uint256[] memory,uint256[] memory);

    function canMintForAmount(uint256 tokenId,uint256 tokmentAmount) external view returns(bool);

    function canMintBulkForAmount(uint256[] memory tokenIds,uint256[] memory tokmentAmounts) external view returns(bool);
    
    function is_token_defined(uint256 token_id) external view returns (bool);

    //Mint nft for some user by contact owner. use for bleeding/crafting or mint NFT from App
    function mintNFTsFor(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external;

    //Burn nft for some user by contact owner. use for crafting or burn NFT from App
    function burnNFTsFor(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external;

    //Mint nft for some user by contact owner. use for bleeding/crafting or mint NFT from App
    function mintNFTFor(address _addr,uint256 tokenId,uint256 amount) external;

    //Burn nft for some user by contact owner. use for crafting or burn NFT from App
    function burnNFTFor(address _addr,uint256 tokenId,uint256 amount) external;

    function getTokenIds(uint256 page_index,uint256 per_page) external view returns (uint256[] memory);
}