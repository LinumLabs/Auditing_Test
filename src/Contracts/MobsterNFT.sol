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

    function claimNft() external {
        require(IERC20(rewardToken).balanceOf(msg.sender) >= requiredTokensForMobsterNFT, "Not enough tokens");

        tokenId++;
        _safeMint(msg.sender, tokenId, "");

        IERC20(rewardToken).transferFrom(msg.sender, address(this), requiredTokensForMobsterNFT);
    }

    function setRequiredTokensForMobsterNFT(uint256 _requiredAmount) external onlyOwner {
        requiredTokensForMobsterNFT = _requiredAmount;
    }
}