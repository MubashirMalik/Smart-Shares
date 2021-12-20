const SmartShares = artifacts.require("SmartShares");

module.exports = function (deployer) {
  deployer.deploy(SmartShares);
};
