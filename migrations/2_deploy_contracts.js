const ethup = artifacts.require("./EthUp.sol")

module.exports = function(deployer) {
	deployer.deploy(ethup);
};
