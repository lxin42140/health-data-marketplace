const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions"); // npm truffle-assertions
const BigNumber = require("bignumber.js"); // npm install bignumber.js
var assert = require("assert");

var Marketplace = artifacts.require("../contracts/Marketplace.sol");
// var MedicalRecord = artifacts.require("../contracts/MedicalRecord.sol");
// var Organization = artifacts.require("../contracts/Organization.sol");
// var Patient = artifacts.require("../contracts/Patient.sol");

const oneEth = new BigNumber(1000000000000000000); // 1 eth
// =============================     Useful concepts       =============================:
// To get the Eth Account Balance = new BigNumber(await web3.eth.getBalance(accounts[1]));
// Get Latest Dice ID => (await diceInstance.getLatestDiceId()).toNumber() => becomes 1,2,3...
// Calculations with bignumer.js: oneEth.dividedBy(2), oneEth.multipliedBy(10) etc..
// Address of contracts in truffle can be obtain with: diceCasinoInstance.address
// =============================     Useful concepts       =============================:

contract("Organization", function (accounts) {
    before(async () => {
        marketplaceInstance = await Marketplace.deployed();
        patientInstance = await marketplaceInstance.patientInstance();
        orgInstance = await marketplaceInstance.orgInstance();
        medTokenInstance = await marketplaceInstance.medTokenInstance();
    });

    console.log("Testing Organization contract");

});
