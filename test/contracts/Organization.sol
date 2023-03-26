pragma solidity ^0.8.0;
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
    Marketplace public marketplaceInstance;
    Patient public patientInstance;
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

    constructor() public {
        marketplaceInstance = Marketplace(msg.sender);
        profileId++;
        organizationProfileMap[address(this)] = Profile(
            profileId,
            address(0),
            OrganizationType.Hospital,
            "Singapore",
            "NUH"
        );
    }

    /********************MODIFIERS *****/
    modifier verifiedOnly() {
        require(
            organizationProfileMap[msg.sender].profileId > 0,
            "Verified organization only!"
        );

        _;
    }

    modifier patientOnly(address patient) {
        require(patientInstance.isPatient(patient), "Patient only!");

        _;
    }

    modifier marketplaceOnly(address marketplace) {
        require(marketplace == address(marketplaceInstance), "Marketplace only!");

        _;
    }

    /********************APIs *****/

    function setPatientInstance(
        address newPatientInstance
    ) public marketplaceOnly(msg.sender) {
        patientInstance = Patient(newPatientInstance);
    }

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
        string memory location,
        string memory organizationName
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

        emit OrganizationAdded(msg.sender, newOrg);
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

    function addNewMedicalRecord(address patientAddress) public verifiedOnly {
        //FIXME: need to create medical record, and passed address of created record
        // patientInstance.addNewMedicalRecord(
        //     patientAddress,
        //     medicalRecordAddress
        // );

        // emit MedicalRecordAdded(msg.sender, patientAddress, filePointer);
    }

    // returns true if the user is a verified organization
    function isVerifiedOrganization(address userAddress) public returns (bool) {
        return organizationProfileMap[msg.sender].profileId > 0;
    }

    function getOrgProfile(
        address org
    ) public marketplaceOnly(msg.sender) returns (Profile memory) {
        return organizationProfileMap[org];
    }
}
