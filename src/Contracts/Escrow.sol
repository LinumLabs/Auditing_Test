// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Core.sol";
import "./Treasury.sol";


contract Escrow is Ownable {

    uint256 public listingId;
    uint256 public offerId;
    address public sellerAddress;
    address public buyerAddress;
    address public USDC;
    address public coreContract;
    address public treasury;

    constructor(
        uint256 _listingId, 
        uint256 _offerId,
        address _protocolAdmin, 
        address _seller,
        address _buyer,
        address _USDC,
        address _coreContract,
        address _treasury
    ) Ownable(_protocolAdmin) {
        listingId = _listingId;
        offerId = _offerId;
        sellerAddress = _seller;
        USDC = _USDC;
        coreContract = _coreContract;
        buyerAddress = _buyer;
        treasury = _treasury;
    }

    function completeSale() external onlyOwner {
        uint256 sellFee = Treasury(payable(treasury)).protocolFee();

        uint256 commission = IERC20(USDC).balanceOf(address(this)) * sellFee / 10000;

        IERC20(USDC).transfer(sellerAddress, IERC20(USDC).balanceOf(address(this)) - commission);
        IERC20(USDC).transfer(payable(treasury), commission);

        Core(coreContract).markOfferComplete(offerId);

    }

    function rejectSale() external onlyOwner {
        IERC20(USDC).transfer(buyerAddress, IERC20(USDC).balanceOf(address(this)));
        Core(coreContract).markOfferFailed(offerId);
    }

    
}