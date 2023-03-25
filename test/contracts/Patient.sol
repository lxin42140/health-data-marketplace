pragma solidity ^0.5.0;
import "./MedicalRecord.sol";
import "./Organization.sol";
import "./MedToken.sol";

contract Patient {
    /** STRUCTS */
    struct Profile {
        uint256 profileId;
        address issuedBy; // organization that add this user as patient
        address patientAddress;
        uint8 age;
        string gender;
        string country;
    }

    /** PROPERTIES */
    Organization public orgInstance;
    Marketplace public marketplaceInstance;
    uint256 profileId;
    mapping(address => Profile) profileMap;
    mapping(address => MedicalRecord[]) patientRecordMap; // list of medical records associated with each patient

    /** EVENTS */
    event PatientProfileAdded(address addedBy, address newPatientAddress);
    event MedicalRecordAdded(address patient, address medicalRecord);

    constructor() public {
        marketplaceInstance = Marketplace(msg.sender);
    }

    /********************MODIFIERS *****/

    modifier marketplaceOnly(address marketplace) {
        require(marketplace == address(marketplaceInstance), "Marketplace only!");

        _;
    }

    modifier organisationOnly(address organization) {
        require(
            orgInstance.isVerifiedOrganization(organization),
            "Verified organization only!"
        );

        _;
    }

    modifier newPatientOnly(address patientAddress) {
        require(
            profileMap[patientAddress].profileId == 0,
            "Patient profile already eixsts!"
        );

        _;
    }

    modifier patientOnly(address patient) {
        require(profileMap[patient].profileId >= 0, "Patient only!");

        _;
    }

    /********************APIs *****/

    function setOrgInstance(
        address newOrgInstance
    ) public marketplaceOnly(msg.sender) {
        orgInstance = Organization(newOrgInstance);
    }

    function addUserAsPatient(
        address patientAddress,
        uint8 age,
        string memory gender,
        string memory country
    ) public organisationOnly(msg.sender) newPatientOnly(patientAddress) {
        require(gender == "M" || gender == "F", "Gender input wrong format");

        profileId++;

        //new patient object
        Profile memory newProfile = Profile(
            profileId,
            msg.sender,
            patientAddress,
            age,
            gender,
            country
        );

        profileMap[patientAddress] = newProfile;

        emit PatientProfileAdded(msg.sender, patientAddress);
    }

    function addNewMedicalRecord(
        address patientAddress,
        address medicalRecordAddress
    ) public organisationOnly(msg.sender) patientOnly(patientAddress) {
        patientRecordMap[patientAddress].push(medicalRecordAddress);

        emit MedicalRecordAdded(patientAddress, medicalRecordAddress);
    }

    function getMedicalRecords(
        address patientAddress
    ) public view patientOnly(patientAddress) returns (MedicalRecord[] memory) {
        require(
            msg.sender == marketplaceInstance ||
                msg.sender == profileMap[patientAddress].patientAddress,
            "Only associatd patient or marketplace can access the personal mpedical records"
        );

        return patientRecordMap[patientAddress];
    }

    function isPatient(address patientAddress) public {
        return profileMap[patientAddress].profileId > 0;
    }
}
