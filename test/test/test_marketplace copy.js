const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions"); // npm truffle-assertions
const BigNumber = require("bignumber.js"); // npm install bignumber.js
var assert = require("assert");

var Marketplace = artifacts.require("../contracts/Marketplace.sol");
var Organization = artifacts.require("../contracts/Organization.sol");
var Patient = artifacts.require("../contracts/Patient.sol");
var MedToken = artifacts.require("../contracts/MedToken.sol");
var MedicalRecord = artifacts.require("../contracts/MedicalRecord.sol");

const oneEth = new BigNumber(1000000000000000000); // 1 eth

// =============================     Useful concepts       =============================:
// To get the Eth Account Balance = new BigNumber(await web3.eth.getBalance(accounts[1]));
// Get Latest Dice ID => (await diceInstance.getLatestDiceId()).toNumber() => becomes 1,2,3...
// Calculations with bignumer.js: oneEth.dividedBy(2), oneEth.multipliedBy(10) etc..
// Address of contracts in truffle can be obtain with: diceCasinoInstance.address
// =============================     Useful concepts       =============================:

contract("Marketplace", function (accounts) {
    before(async () => {
        marketplaceInstance = await Marketplace.deployed();
        medTokenInstance = await MedToken.deployed();
        patientInstance = await Patient.deployed();
        orgInstance = await Organization.deployed();

        // set up marketplace dependency
        await marketplaceInstance.setOrganization(orgInstance.address);
        await marketplaceInstance.setPatient(patientInstance.address);
        await marketplaceInstance.setMedToken(medTokenInstance.address);

        // set up token dependency
        await medTokenInstance.setOrganization(orgInstance.address);
        await medTokenInstance.setPatient(patientInstance.address);
        await medTokenInstance.setMarketplace(marketplaceInstance.address);

        // set up org dependency
        await orgInstance.setPatient(patientInstance.address);
        await orgInstance.setMarketplace(marketplaceInstance.address);

        // set up patient dependency
        await patientInstance.setMarketplace(marketplaceInstance.address);
        await patientInstance.setOrganization(orgInstance.address);
    });

    console.log("Testing Marketplace contract");


});