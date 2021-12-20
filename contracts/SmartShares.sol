// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22;

contract SmartShares {
  address public owner;
  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(
      msg.sender == owner, "Only owner is allowed."
    );
    _;
  }

  struct Share {
    uint percentageOwned;
    uint percentageSelling;
  }

  struct Asset {
    string name;
    mapping (address => Share) shareHolders;
    uint sharePrice; // price of 1 unit
    address ttp; // ttp to change the unitPrice
    bool isTtpSet;
    // to make mapping iterable
    address[] addresses;
  }

  Asset[] public assets;

  function addAsset(string memory name, uint sharePrice, uint[] memory percentages, address[] memory addresses) public onlyOwner {

    assets.push();
    Asset storage asset = assets[assets.length - 1];

    asset.name = name;
    asset.sharePrice = sharePrice;
    asset.ttp = address(0);
    asset.isTtpSet = false;

    require(percentages.length == addresses.length);

    uint total = 0; // to validate share percentage
    for (uint i = 0; i < addresses.length; i++) {
      asset.shareHolders[addresses[i]].percentageOwned = percentages[i];
      asset.shareHolders[addresses[i]].percentageSelling = 0;
      asset.addresses.push(addresses[i]);
      total += percentages[i];
    }

    require (
      total == 100, "Total of Share Percentages must equal 100."
    );
  }

  function listAssets() public view returns (string[] memory, uint[] memory){
    string[] memory names = new string[](assets.length);
    uint[] memory sharePrices = new uint[](assets.length);
    for(uint i = 0; i < assets.length; i++) {
      names[i] = assets[i].name;
      sharePrices[i] = assets[i].sharePrice;
    }

    return (names, sharePrices);
  }

  function listShareHolders(string memory name) public view returns(address[] memory){
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");
    return assets[i].addresses;
  }


  function searchAssetByName(string memory name) internal view returns (uint, bool){
    bool isFound = false;
    uint i;
    for(i = 0; i < assets.length; i++) {
      if( keccak256(abi.encodePacked(assets[i].name)) == keccak256(abi.encodePacked(name))) {
        isFound = true;
        break;
      }
    }
    return (i, isFound);
  }

  function getSharePrice(string memory name) public view returns (uint){
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");
    return assets[i].sharePrice;
  }

  function changeSharePrice(string memory name, uint newSharePrice) public {
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");
    require(
      assets[i].ttp == msg.sender, "Only ttp can set share price of an Asset."
    );
    assets[i].sharePrice = newSharePrice;
  }

  function addTTP(string memory name, address ttp) public onlyOwner {
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");
    require(assets[i].isTtpSet == false, "TTP already set");

    assets[i].ttp = ttp;
    assets[i].isTtpSet = true;
  }

  function getMyShares(string memory name) external view returns (uint)
  {
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");

    return assets[i].shareHolders[msg.sender].percentageOwned + assets[i].shareHolders[msg.sender].percentageSelling;
  }

  function percentageSelling(string memory name) public view returns(uint){
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");
    return assets[i].shareHolders[msg.sender].percentageSelling;
  }

  function sellShares(string memory name, uint percentageSelling) public
  {
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");

    require(assets[i].shareHolders[msg.sender].percentageOwned >= assets[i].shareHolders[msg.sender].percentageSelling, "You do not have that much shares to sell.");
    require(assets[i].shareHolders[msg.sender].percentageOwned != 0,"You are not in shareholders list of this asset." );

    assets[i].shareHolders[msg.sender].percentageSelling = percentageSelling;
    assets[i].shareHolders[msg.sender].percentageOwned -= percentageSelling;
  }

  function getShareSellers(string memory name) public view returns(address[] memory, uint){
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");

    uint size = 0;
    address[] memory shareSellers = new address[](assets[i].addresses.length);
    for (uint j = 0; j < assets[i].addresses.length; j++) {
      if (assets[i].shareHolders[assets[i].addresses[j]].percentageSelling > 0) {
        shareSellers[size++] = assets[i].addresses[j];
      }
    }
    return (shareSellers, size);
  }

  function transferShares(string memory name, uint percentage, address seller) external payable {
    (uint i, bool isFound) = searchAssetByName(name);
    require(isFound == true , "Asset does not exist.");

    require(msg.value >= assets[i].sharePrice * 1000000000000000000 * percentage, "You did not send enough ethers.");

    require(assets[i].shareHolders[seller].percentageSelling > percentage, "This seller is not selling that much shares.");

    // Transfer shares from owner [Debit]
    assets[i].shareHolders[seller].percentageSelling -= percentage;
    payable(seller).transfer(msg.value);
    // Transfer shares to buyer [Credit]
    assets[i].shareHolders[msg.sender].percentageOwned = percentage;
    assets[i].shareHolders[msg.sender].percentageSelling = 0;
    assets[i].addresses.push(msg.sender);
    }
}
