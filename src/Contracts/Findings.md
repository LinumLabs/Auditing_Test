Title: RewardToken
Author: Ihor Antsupov (i.antsupov@gmail.com)
Date: 2021-09-29

======================================================================================================================================================
======================================================================================================================================================
======================================================================================================================================================

# contract name: Core

Info:
- require is cost more gas than custom error messages. Recommend to use custom error messages
- no events for any actions, it is important to have events for any changes in the contract
- magic numbers should be fixed or added to constants

###  Enumerable:
High:
- enum Reward_Action should contain a default value to avoid index mismatch
examplanation: if the enum is used as an array index, it is important to have a default value to avoid index mismatch
- mappings
examplanation: new version pragma 0.8.0 has a new feature to use mappings with existing keys
for example: mapping(uint256 listingId ###  Listing listing) public listings;
- addresses 
examplanation: it is better to use the address of the contract instead of the address of the interface

###  constructor:
Medium:
- need to add validation for _treasury and _rewardToken

###  function listSale:
Medium:
- need add validation for _price and _uri
Gas:
- unchecked block for numberOfListings saving some gas 

###  function makeOffer:
Medium:
- no check for msg.value
- incorrect check in require(listings[_listingId].listingId != 0, "Listing does not exist");
explanation: if listingId = 100 but there are only 10 listings
recommend to check if numberOfListings < _listingId
- incorrect check  require(listings[_listingId].status == Listing_Status.LISTED || 
explanation: in reason contract does not contain default value for Listing_Status
it is always listed

###  function cancelOffer:
Medium:
- need add validation for _listingId and _offerId

###   function markOfferComplete:
Gas:
- it is better to execute mint function once
- just need to add a new function to the RewardToken contract
explanation: mintBatch or mintMultiple with values as arrays or structs

###   function listSaleForAuction:
Medium:
- need add validation for _uri, _startingPrice, _buyersRemorsePeriod
Gas:
- unchecked block for numberOfListings saving some gas

###   function updateAuctionWinner:
Medium:
- need add validation for _listingId and _winner
there is no validation  or status change for auction 
explanation: it is need to test in deep this function for more protection and validation


======================================================================================================================================================
======================================================================================================================================================
======================================================================================================================================================


# contract name: Escrow

Info:
- require is cost more gas than custom error messages. Recommend to use custom error messages
- no events for any actions, it is important to have events for any changes in the contract
- magic numbers should be fixed or added to constants

###  constructor:
Medium:
- need to add validation for _treasury and _rewardToken

###  function listSale:
Medium:
- need add validation for _price and _uri
Gas:
- unchecked block for numberOfListings saving some gas 

###  function makeOffer:
Medium:
- no check for msg.value
- incorrect check in require(listings[_listingId].listingId != 0, "Listing does not exist");
explanation: if listingId = 100 but there are only 10 listings
recommend to check if numberOfListings < _listingId
- incorrect check  require(listings[_listingId].status == Listing_Status.LISTED || 
explanation: in reason contract does not contain default value for Listing_Status
it is always listed

###  function cancelOffer:
Medium:
- need add validation for _listingId and _offerId

###   function markOfferComplete:
Gas:
- it is better to execute mint function once
- just need to add a new function to the RewardToken contract
explanation: mintBatch or mintMultiple with values as arrays or structs

###   function listSaleForAuction:
Medium:
- need add validation for _uri, _startingPrice, _buyersRemorsePeriod
Gas:
- unchecked block for numberOfListings saving some gas

###   function updateAuctionWinner:
Medium:
- need add validation for _listingId and _winner
there is no validation  or status change for auction 
explanation: it is need to test in deep this function for more protection and validation


======================================================================================================================================================
======================================================================================================================================================
======================================================================================================================================================


# contract name: MobsterNFT

Info:
- require is cost more gas than custom error messages. Recommend to use custom error messages

it is recommended to add events for any changes in the contract
it is recomendet to use safeTransferFrom instead of transferFrom

###  constructor:
Medium:
- need to add validation for _rewardToken

###  function claimNft:
Low:
add this variable to the local variable for gas optimization
double read storage variable
it is also can be putted in unchecked block
for example:
uint256 newTokenId = tokenId;
unchecked {
    tokenId++;
}

###  function makeOffer:
Medium:
- no check for msg.value
- incorrect check in require(listings[_listingId].listingId != 0, "Listing does not exist");
explanation: if listingId = 100 but there are only 10 listings
recommend to check if numberOfListings < _listingId
- incorrect check  require(listings[_listingId].status == Listing_Status.LISTED ||
explanation: in reason contract does not contain default value for Listing_Status
it is always listed

###  function cancelOffer:
Medium:
- need add validation for _listingId and _offerId

###   function markOfferComplete:
Gas:
- it is better to execute mint function once
- just need to add a new function to the RewardToken contract
explanation: mintBatch or mintMultiple with values as arrays or structs

###   function listSaleForAuction:
Medium:
- need add validation for _uri, _startingPrice, _buyersRemorsePeriod
Gas:
- unchecked block for numberOfListings saving some gas

###   function updateAuctionWinner:
Medium:
- need add validation for _listingId and _winner
there is no validation  or status change for auction
explanation: it is need to test in deep this function for more protection and validation

======================================================================================================================================================
======================================================================================================================================================
======================================================================================================================================================



# contract name: PropertyAuction

Info:
- require is cost more gas than custom error messages. Recommend to use custom error messages
- no events for any actions, it is important to have events for any changes in the contract
- magic numbers should be fixed or added to constants

###  Variables:
Low:
- it is bette to store contract address instead of interface address

###  constructor:
Medium:
- need to add validation for all parameters

###   function bidWithETH
high:
- need to add validation for msg.value

###  function closeAuction
Low:
-    (,,,,, Core.Listing_Status status,,) = Core(payable(core)).listings(listingId);
explanation: if you need just one parameter from the struct, it is better to create a separate function for this

======================================================================================================================================================
======================================================================================================================================================
======================================================================================================================================================


# contract name: RewardToken

###  In RewardToken contract general:
Info:
- require is cost more gas than custom error messages. Recommend to use custom error messages
- no events for any actions, it is important to have events for any changes in the contract
- magic numbers should be fixed or added to constants

###  Enumerable:
High:
- enum Reward_Action should contain a default value to avoid index mismatch
examplanation: if the enum is used as an array index, it is important to have a default value to avoid index mismatch


###  function mint:
Critical: 
 - need to add validation for _value in case it is low value can create overflow

###  function setRewardForAction:
High:
- add validation for _percentage values
examplanation: it is important to have validation for the _percentage values
f.e. if _percentage is 10001 it will be accepted and it is not correct

###  function batchSetRewardForAction:
High:
- add validation for _percentage values
examplanation: it is important to have validation for the _percentage values
f.e. if _percentage is 0 it will be accepted and it is not correct
Gas:
- in loop ++x is more efficient than x++

======================================================================================================================================================
======================================================================================================================================================
======================================================================================================================================================

# contract name: Treasury

###  In Treasury contract general:
Info:
- require is cost more gas than custom error messages. Recommend to use custom error messages
- no events for any actions, it is important to have events for any changes in the contract
- magic numbers should be fixed or added to constants

###  Variables:
Info:
- it is better to use the address of the contract instead of the address of the interface

###  constructor:
Medium:
- need to add validation for _mobsterNFT

###  function distributeRewards:
High:
- double loop for holders
explanation: it is not clear why there is a double loop for holders
and it need to calculate and check total cost for this tx 
and after passed transaction 
- add validation for _holders array length
explanation: it is important to have validation for the _holders array length
f.e. if _holders.length == 1000 then it will be out of gas
Info:
- need to add some additional actions after the distribution with monsterHoldersPercentage variable
explanation: after the distribution, the contract should have 0 balance
monsterHoldersPercentage should be decresed to 0 after distribution
this is a good practice to avoid melicious actions if function will be called multiple times
Gas:
- use ++x instead of x++ for gas optimization



