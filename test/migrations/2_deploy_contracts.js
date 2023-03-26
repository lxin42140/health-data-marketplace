const Marketplace = artifacts.require("Marketplace");

module.exports = (deployer, network, accounts) => {
    deployer.deploy(Marketplace).then(function () {
        console.log("Deployed marketplace")
    });
}