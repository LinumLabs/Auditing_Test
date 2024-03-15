// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MobsterNFT is ERC721, Ownable {
    uint256 public tokenId;
    uint256 public requiredTokensForMobsterNFT;

    // it is better to store contract address instance instead of address
    address public rewardToken;

    constructor(address _rewardToken) ERC721("MonsterNFT", "MonNFT") Ownable(msg.sender) {
        // need to add validation for _rewardToken
        rewardToken = _rewardToken;
    }

    // Allow a user with enough tokens to mint a soulbound token
    function claimNft() external {
        require(IERC20(rewardToken).balanceOf(msg.sender) >= requiredTokensForMobsterNFT, "Not enough tokens");

        // add this variable to the local variable for gas optimization
        // double read storage variable
        // it is also can be putted in unchecked block
        // for example:
        // uint256 newTokenId = tokenId;
        // unchecked {
        //     tokenId++;
        // }

        tokenId++;
        _safeMint(msg.sender, tokenId, "");

        // use safeTransferFrom instead of transferFrom
        IERC20(rewardToken).transferFrom(msg.sender, address(this), requiredTokensForMobsterNFT);
    }

    // use safeTransferFrom instead of transferFrom
    // Override the transfer function
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    ) public override(ERC721) {
        require(msg.sender == address(0), "SOULBOUND TOKEN");
        super.transferFrom(_from, _to, _tokenID);
    }

    // Allow owner to set the number of reward tokens a user should have to claim an NFT
    function setRequiredTokensForMobsterNFT(uint256 _requiredAmount) external onlyOwner {
        // add validation for _requiredAmount
        requiredTokensForMobsterNFT = _requiredAmount;
    }
}