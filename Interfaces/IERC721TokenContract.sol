// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IERC721TokenContract {
   
    //Get Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external view returns (string memory);
    
    //Set Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory contractURI_) external;

    //Get all of items for address.
    function ownedTokenOf(address _addr) external view returns (uint256[] memory);

    //Check address is really own item.
    function isOwnedToken(address _addr,uint256 tokenId) external view returns(bool);

    //Update token URI for token Id
    function updateTokenURI(uint256 tokenId,string memory tokenURI) external;

    //Mint nft (unreveal only) for some user by contact owner. use for bleeding or mint NFT from App
    function mintNFTsFor(address addr,uint256 amount) external;

    //Mint nft for some user by contact owner. use for bleeding or mint NFT from App
    function mintNFTFor(address addr,string memory tokenURI) external;

    //Mint nft for some user by contact owner. use for bleeding or mint NFT from App
    function burnNFTFor(address addr,uint256 tokenId) external;

    //Update display name of token when unreveal.
    function getUnrevealName() external view returns (string memory);

    //Update token uri of token when unreveal.
    function getUnrevealTokenUri() external view returns (string memory);

    function getUnrevealMetadata() external view returns (string memory,string memory);    

    function getTokenIds(uint256 page_index,uint256 per_page) external view returns (uint256[] memory);
}