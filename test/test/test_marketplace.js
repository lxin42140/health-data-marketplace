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

    const SEED_ORG = accounts[0]; // HOSPITAL
    const VERIFIED_ORG_1 = accounts[1]; // RESEARCH
    const VERIFIED_ORG_2 = accounts[2]; // Pharmacy,
    const PATIENT = accounts[3];
    const INVALID = accounts[4];

    it("set up", async () => {
        // add patient
        await patientInstance.addNewPatient(PATIENT, 10, "male", "singapore", {
            from: SEED_ORG,
        });

        // add new org
        await orgInstance.addNewOrganization(VERIFIED_ORG_1, 1, "Singapore", "TTS")
        await orgInstance.addNewOrganization(VERIFIED_ORG_2, 2, "Singapore", "KK")

        // organization add medical record
        await patientInstance.addNewMedicalRecord(
            SEED_ORG,
            PATIENT,
            0,
            "www.0.com",
            {
                from: SEED_ORG
            }
        )

        // patient add medical record
        await patientInstance.addNewMedicalRecord(
            VERIFIED_ORG_1,
            PATIENT,
            1,
            "www.1.com",
            {
                from: PATIENT
            }
        )
    });

    it("Get and check MT", async () => {
        await truffleAssert.reverts(marketplaceInstance.getMT({
            from: INVALID,
            value: oneEth
        }), "Only patient, owner and organization can perform this action!");

        await marketplaceInstance.getMT({
            from: SEED_ORG,
            value: oneEth
        });

        await marketplaceInstance.getMT({
            from: VERIFIED_ORG_1,
            value: oneEth
        });

        await marketplaceInstance.getMT({
            from: PATIENT,
            value: oneEth
        });

        const verifiedOrgCredit = await marketplaceInstance.checkMT({
            from: VERIFIED_ORG_1
        });

        const seedOrgCredit = await marketplaceInstance.checkMT({
            from: SEED_ORG
        });

        const patientCredit = await marketplaceInstance.checkMT({
            from: PATIENT
        });

        const expectedMT = new BigNumber(100);

        assert(expectedMT.isEqualTo(seedOrgCredit), "Incorrect MT given");
        assert(expectedMT.isEqualTo(verifiedOrgCredit), "Incorrect MT given");
        assert(expectedMT.isEqualTo(patientCredit), "Incorrect MT given");
    });

    it("return MT", async () => {
        await truffleAssert.reverts(marketplaceInstance.returnMT({
            from: INVALID
        }), "Only patient, owner and organization can perform this action!");

        await truffleAssert.reverts(marketplaceInstance.returnMT({
            from: VERIFIED_ORG_2
        }), "No MT!");

        // get credit
        await marketplaceInstance.getMT({
            from: VERIFIED_ORG_2,
            value: oneEth
        });

        // check credit
        let verifiedOrgCredit = await marketplaceInstance.checkMT({
            from: VERIFIED_ORG_2
        });
        assert((new BigNumber(100)).isEqualTo(verifiedOrgCredit), "Incorrect MT given");

        // return credit
        await marketplaceInstance.returnMT({
            from: VERIFIED_ORG_2
        })

        // check org credit
        verifiedOrgCredit = await marketplaceInstance.checkMT({
            from: VERIFIED_ORG_2
        });
        assert((new BigNumber(0)).isEqualTo(verifiedOrgCredit), "Incorrect MT withdrawn");

        // check marketplace credit
        const marketCredit = await marketplaceInstance.checkMT({
            from: marketplaceInstance.address
        });
        assert((new BigNumber(10)).isEqualTo(marketCredit), "Incorrect MT fee");
    })

    it("add listing", async () => {
        await truffleAssert.reverts(marketplaceInstance.addListing(1, [0], [0], {
            from: INVALID
        }), "Patient only!");

        await truffleAssert.reverts(marketplaceInstance.addListing(1, [], [0], {
            from: PATIENT
        }), "Provide min 1 type of record that you wish to sell!");

        await truffleAssert.reverts(marketplaceInstance.addListing(1, [4], [0], {
            from: PATIENT
        }), "No medical records of matching types to sell!");

        const listing1 = await marketplaceInstance.addListing(1, [0], [0], {
            from: PATIENT
        });

        truffleAssert.eventEmitted(listing1, "ListingAdded");
    });

    it("get listing", async () => {
        const addedListing = await marketplaceInstance.getListingDetails.call(1);

        assert.equal(addedListing.id, 1, "Wrong listing id");
        assert.equal(addedListing.listingOwner, PATIENT, "Wrong listing owner");
        assert.equal(addedListing.pricePerDay, 1, "Wrong listing price");
        assert.deepEqual(addedListing.recordTypes, ['0'], "Wrong listing record types");
        assert.deepEqual(addedListing.allowOrganizationTypes, ['0'], "Wrong listing allowed organization");
    });

    it("remove listing", async () => {
        await truffleAssert.reverts(marketplaceInstance.removeListing(2, {
            from: INVALID
        }), "Listing does not exists!");

        await truffleAssert.reverts(marketplaceInstance.removeListing(1, {
            from: INVALID
        }), "Only listing owner can perform this action!");

        const removeListing = await marketplaceInstance.removeListing(1, {
            from: PATIENT
        });

        truffleAssert.eventEmitted(removeListing, "ListingRemoved");

        await truffleAssert.reverts(marketplaceInstance.removeListing(1, {
            from: INVALID
        }), "Listing does not exists!");
    });


    it("buy listing", async () => {

    });
});
