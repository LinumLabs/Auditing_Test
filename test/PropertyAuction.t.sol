// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";
import "../src/contracts/Core.sol";
import "../src/contracts/Escrow.sol";
import "../src/contracts/MobsterNFT.sol";
import "../src/contracts/RewardToken.sol";
import "../src/contracts/PropertyAuction.sol";

contract PropertyAuctionTest is Test {

    Treasury public treasury;
    Core public core;
    MobsterNFT public mobsterNFT;
    RewardToken public rewardToken;

    address owner = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);
    address chad = vm.addr(4);
    address dan = vm.addr(5);
    address elvis = vm.addr(6);
    address greg = vm.addr(7);

    PropertyAuction public auction;

    function beforeEach() public {
        vm.startPrank(owner);

        rewardToken = new RewardToken();
        mobsterNFT = new MobsterNFT(address(rewardToken));
        treasury = new Treasury(address(mobsterNFT));
        core = new Core(address(treasury), address(rewardToken));

        treasury.setProtocolFee(5000);

        vm.stopPrank();

        vm.prank(bob);
        address auctionContract = core.listSaleForAuction("Bob", 10 ether, 7 days);
        auction = PropertyAuction(auctionContract);
    }

    function test_BidWithETH() public {
        beforeEach();
        vm.startPrank(elvis);
        vm.deal(elvis, 100 ether);

        assertEq(address(auction).balance, 0);
        assertEq(rewardToken.balanceOf(elvis), 0);
        
        auction.bidWithETH{value: 10.01 ether}();
        
        assertEq(rewardToken.balanceOf(elvis), 0.005005 ether);
        assertEq(address(auction).balance, 10.01 ether);
        assertEq(auction.currentWinningBidAmount(), 10.01 ether);
        assertEq(auction.currentWinningBidder(), elvis);
        vm.stopPrank();
    }

    function bidWithCredit() public {
        beforeEach();
        
        vm.prank(elvis);
        vm.deal(elvis, 100 ether);
        auction.bidWithETH{value: 12 ether}();
        
        vm.warp(100);

        vm.prank(bob);
        auction.closeAuction();

        vm.startPrank(elvis);
        auction.bailOutOfPurchase();
        
        assertEq(address(auction).balance, 0);

        auction.bidWithCredit(1 ether);

        assertEq(address(auction).balance, 0.0005 ether);
        assertEq(address(auction).balance, 12 ether);
        assertEq(auction.userCredit(elvis), 11 ether);
        assertEq(auction.currentWinningBidAmount(), 1 ether);
        assertEq(auction.currentWinningBidder(), elvis);
    }

    function test_CloseAuction() public {
        beforeEach();
        
        vm.prank(elvis);
        vm.deal(elvis, 100 ether);
        auction.bidWithETH{value: 12 ether}();
        
        assertEq(auction.auctionStillOpen(), true);
        assertEq(auction.auctionClosedTime(), 0);

        vm.warp(100);

        vm.prank(bob);
        auction.closeAuction();
        
        (,,,,, Core.Listing_Status status,,) = core.listings(1);

        assertEq(uint256(status), 1);               
        assertEq(auction.auctionStillOpen(), false);
        assertEq(auction.auctionClosedTime(), 100);
    }

    function test_BailOutOfPurchase() public {
        beforeEach();
        
        vm.prank(elvis);
        vm.deal(elvis, 100 ether);
        auction.bidWithETH{value: 12 ether}();
        
        vm.warp(100);

        vm.prank(bob);
        auction.closeAuction();

        vm.prank(elvis);
        auction.bailOutOfPurchase();

        (,,,,, Core.Listing_Status status,,) = core.listings(1);

        assertEq(uint256(status), 0);               
        assertEq(auction.userCredit(elvis), 12 ether);
        assertEq(auction.auctionStillOpen(), true);
    }

    function test_SettleAuction() public {
        beforeEach();
        
        vm.prank(elvis);
        vm.deal(elvis, 100 ether);
        auction.bidWithETH{value: 12 ether}();
        
        vm.warp(100);

        vm.prank(bob);
        auction.closeAuction();

        vm.warp(8 days);

        vm.prank(bob);
        auction.settleAuction();

        (,,, address finalizedBuyer ,, Core.Listing_Status status,,) = core.listings(1);

        assertEq(uint256(status), 2);   
        assertEq(finalizedBuyer, elvis);            
        assertEq(address(treasury).balance, 6 ether);
        assertEq(address(auction).balance, 6 ether);
        assertEq(auction.userCredit(bob), 6 ether);

        assertEq(rewardToken.balanceOf(bob), 0.85 ether);
        assertEq(rewardToken.balanceOf(elvis), 1.206 ether);
    }
    
    function test_WithdrawFunds() public {
        beforeEach();
        
        vm.prank(elvis);
        vm.deal(elvis, 100 ether);
        auction.bidWithETH{value: 12 ether}();
        
        vm.warp(100);

        vm.prank(bob);
        auction.closeAuction();

        vm.startPrank(elvis);
        auction.bailOutOfPurchase();
        auction.withdrawFunds(9 ether);

        assertEq(address(auction).balance, 3 ether);
        assertEq(elvis.balance, 97 ether);
        assertEq(auction.userCredit(elvis), 3 ether);
    }
}
