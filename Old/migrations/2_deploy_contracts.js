var Token = artifacts.require("./MobuToken.sol");
var Crowdsale = artifacts.require("./MobuCrowdsale.sol");

module.exports = function(deployer) {
  deployer.then(async () => {
  	await deployer.deploy(Token, web3.eth.accounts[0]);
  	await deployer.deploy(Crowdsale, Token.address, web3.eth.accounts[0], 15000);
  })
};
