// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Core.sol";
import "./Treasury.sol";


contract Escrow is Ownable {

    uint256 public listingId;
    uint256 public offerId;
    address public sellerAddress;
    address public buyerAddress;
    address public coreContract;
    address public treasury;

    constructor(
        uint256 _listingId, 
        uint256 _offerId,
        address _protocolAdmin, 
        address _seller,
        address _buyer,
        address _coreContract,
        address _treasury
    ) Ownable(_protocolAdmin) {
        listingId = _listingId;
        offerId = _offerId;
        sellerAddress = _seller;
        coreContract = _coreContract;
        buyerAddress = _buyer;
        treasury = _treasury;
    }

    // The owner of the escrow contract can complete the sale once off-chain verification is complete
    function completeSale() external onlyOwner {
        uint256 sellFee = Treasury(payable(treasury)).protocolFee();
        uint256 commission = address(this).balance * sellFee / 10000;
        
        Core(payable(coreContract)).markOfferComplete(listingId, offerId);

        (bool sent, ) = sellerAddress.call{value: address(this).balance - commission}("");
        require(sent, "Failed to send Ether");

        (sent, ) = payable(treasury).call{value: commission}("");
        require(sent, "Failed to send Ether");
    }

    // The owner of the escrow contract can reject the sale 
    function rejectSale() external onlyOwner {
        
        Core(payable(coreContract)).markOfferFailed(listingId, offerId);

        (bool sent, ) = buyerAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    //Allows ether to be sent to this contract
    receive() external payable {}
}