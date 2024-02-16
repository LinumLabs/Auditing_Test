# System Overview

## General Overview

This system has been developed to facilitate buying and selling of properties. It is built to help the end users control their finances and have a way to trust that they wont lose their money.

## In-Depth Overview

The system can be divided into three parts and 6 contracts. Most of the functionality happens in the Core.sol contract. However, other breakouts from core functionality happen in other contracts.

### Standard Listings (Part 1)

You will often see us referring to 'standard listings'. These refer to the normal type of property sale where a user puts a property up for sale and potential buyers may put in offers. If at any point the seller would like to accept the offer, they may do so and the listing will close. While the transfer of ownership happens in the real world. the funds sit in an escrow contract (Escrow.sol) which will then allow the system owner to succeed or reject the sale when needed.

### Auctions (Part 2)

Another way for a user to sell a property would be to put the property up for auction. They create an auction (PropertyAuction.sol) and give it a starting bid. Potential buyers may then auction for the property until the seller is happy, in which case they will then close the auction. There is a buyers remorse period which allows the highest bidder to pull out of the sale after the auction has closed, but only during this period. The seller may settle the auction anytime after the buyers remorse period is complete and the buyer will then lose their funds.

### Giveaways (Part 3)

A most definitely smaller part of the system but one we would still like to include are giveaways. Sellers are able to list their properties as a form of lucky draw. They specify a entry amount (needs to be small) and after some period they will close the giveaway and the system will randomly select a winner from the entrants. The seller may cancel the giveaway but only before an entries have been received.

## Main Focus of the System

The main focus of the system is to facilitate the transferring of funds. The system does not cater for the title deeds and ownership transfer of the property. It simply allows a way for users to buy and sell property with trust over the funds not being stolen or mis used. 

## Reward System

The system has a built in rewards module. The RewardToken.sol is an ERC20 token which gets minted to users as rewards for certain actions in the system. Everytime someone creates a listing, makes an offer, purchases a property or sells a property, they are rewarded with a relative amount of ERC20s.

Once they have enough ERC20's, they may mint themselves a MobsterNFT (MobsterNFT.sol), which is an ERC721 NFT contract. This allows them to now receive a portion of all funds made by the protocol.

## Protocol Fees

The protocol takes a percentage of all successful sales in the system. These funds are stored in the Treasury.sol and used to keep the protocol running and are also distributed to the holders of the MobsterNFTs.

