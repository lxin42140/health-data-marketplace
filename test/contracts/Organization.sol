pragma solidity ^0.5.0;
import "./Marketplace.sol";
import "./Patient.sol";
import "./MedicalRecord.sol";

contract Organization {
    /** CONSTANTS */
    enum OrganizationType {
        Hospital,
        Research,
        Pharmacy
    }

    /** STRUCTS */
    struct Profile {
        uint256 profileId;
        address verifiedBy; // the address of org that verified this organization
        OrganizationType organizationType;
        string location;
        string organizationName;
    }

    /** PROPERTIES */
    uint256 profileId;
    Marketplace marketplaceInstance;
    Patient patientInstance;
    mapping(address => Profile) organizationProfileMap;

    /** EVENTS */
    event PatientAdded(address addedBy, address newPatientAddress);
    event OrganizationAdded(address addedBy, address newOrgAddress);
    event OrganizationRemoved(address removedBy, address deletedOrgAddress);
    event MedicalRecordAdded(
        address addedBy,
        address patient,
        string filePointer
    );

    constructor(address marketplace, address patient) public {
        marketplaceInstance = Marketplace(marketplace);
        patientInstance = Patient(patient);
        //TODO: hardcode some values to the organizationProfileMap
        // organizationProfileMap[address(this)] = Profile(
        //     OrganizationType.Hospital,
        //     "Singapore",
        //     "NUH",
        //     address(0)
        // );
    }

    /********************MODIFIERS *****/
    modifier verifiedOnly() {
        require(
            organizationProfileMap[msg.sender].profileId > 0,
            "Only verified organization can perform this action!"
        );

        _;
    }

    modifier patientOnly(address user) {
        //TODO: check that msg.sender is in patient smart contract

        _;
    }

    modifier marketplaceOnly() {
        require(
            msg.sender == marketplaceInstance,
            "Only marketplace can only this!"
        );

        _;
    }

    /********************APIs *****/

    function addNewPatient(
        address patientAddress,
        uint8 age,
        string memory gender,
        string memory country
    ) public verifiedOnly {
        patientInstance.addUserAsPatient(patientAddress, age, gender, country);

        emit PatientAdded(msg.sender, patientAddress);
    }

    function addNewOrganisation(
        address newOrg,
        OrganizationType organizationType,
        string location,
        string organizationName
    ) public verifiedOnly {
        // check if new org already is verified
        require(
            organizationProfileMap[newOrg].profileId == 0,
            "Organization already added!"
        );

        // incre id
        profileId++;

        // create profile
        Profile memory newProfile = Profile(
            profileId,
            msg.sender, //verified by
            organizationType,
            location,
            organizationName
        );

        organizationProfileMap[newOrg] = newProfile;

        emit OrganizationAdded(msg.sender, userAddress);
    }

    function removeOrganization(address orgAddress) public verifiedOnly {
        require(
            organizationProfileMap[orgAddress].profileId > 0,
            "User to delete is not verified organization!"
        );

        require(
            msg.sender == organizationProfileMap[orgAddress].verifiedBy,
            "Caller not eligible to remove organization!"
        );

        delete organizationProfileMap[orgAddress];

        emit OrganizationRemoved(msg.sender, orgAddress);
    }

    function addNewMedicalRecord(
        uint256 filePointer,
        address patientAddress
    ) public verifiedOnly patientOnly(patientAddress) {
        // TODO: call patient API to make add medical record

        emit MedicalRecordAdded(msg.sender, patientAddress, filePointer);
    }

    // returns true if the user is a verified organization
    function isVerifiedOrganization(address userAddress) public {
        return organizationProfileMap[msg.sender].profileId > 0;
    }

    function getOrgProfile(
        address org
    ) public marketplaceOnly returns (Profile memory) {
        return organizationProfileMap[org];
    }

}
