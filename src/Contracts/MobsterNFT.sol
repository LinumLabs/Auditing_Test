// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MobsterNFT is ERC721, Ownable {

    uint256 public tokenId;
    uint256 public requiredTokensForMobsterNFT;

    address public rewardToken;


    constructor(address _rewardToken) ERC721("MonsterNFT", "MonNFT") Ownable(msg.sender) {
        rewardToken = _rewardToken;
    }

    // Allow a user with enough tokens to mint a soulbound token
    function claimNft() external {
        require(IERC20(rewardToken).balanceOf(msg.sender) >= requiredTokensForMobsterNFT, "Not enough tokens");

        tokenId++;
        _safeMint(msg.sender, tokenId, "");

        IERC20(rewardToken).transferFrom(msg.sender, address(this), requiredTokensForMobsterNFT);
    }

    // Override the transfer function
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    ) public payable override(ERC721) {
        require(msg.sender == address(0), "SOULBOUND TOKEN");
        super.transferFrom(_from, _to, _tokenID);
    }

    // Allow owner to set the number of reward tokens a user should have to claim an NFT
    function setRequiredTokensForMobsterNFT(uint256 _requiredAmount) external onlyOwner {
        requiredTokensForMobsterNFT = _requiredAmount;
    }
}