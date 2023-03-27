// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
    address public owner = msg.sender;
    Organization public orgInstance;
    Marketplace public marketplaceInstance;

    uint256 profileId;
    mapping(address => Profile) profileMap;
    mapping(address => MedicalRecord[]) patientRecordMap; // list of medical records associated with each patient

    /** EVENTS */
    event PatientAdded(address addedBy, address newPatientAddress);
    event MedicalRecordAdded(address patient, address medicalRecord);

    constructor() {}

    /********************MODIFIERS *****/

    modifier ownerOnly() {
        require(msg.sender == owner, "Owner only!");

        _;
    }

    modifier marketplaceOnly(address marketplace) {
        require(
            marketplace == address(marketplaceInstance),
            "Marketplace only!"
        );

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

    function setMarketplace(address market) public ownerOnly {
        marketplaceInstance = Marketplace(market);
    }

    function setOrganization(address org) public ownerOnly {
        orgInstance = Organization(org);
    }

    // TESTED
    function addNewPatient(
        address patientAddress,
        uint8 age,
        string memory gender,
        string memory country
    ) public organisationOnly(msg.sender) newPatientOnly(patientAddress) {
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

        emit PatientAdded(msg.sender, patientAddress);
    }

    // TESTED
    function getPatientProfile(
        address patientAddress
    ) public view returns (Profile memory) {
        require(
            msg.sender == address(marketplaceInstance) ||
                msg.sender == profileMap[patientAddress].patientAddress ||
                msg.sender == profileMap[patientAddress].issuedBy,
            "Only patient, issued by organization and marketplace can access!"
        );

        return profileMap[patientAddress];
    }

    function addNewMedicalRecord(
        address patientAddress,
        address medicalRecordAddress
    ) public organisationOnly(msg.sender) patientOnly(patientAddress) {
        patientRecordMap[patientAddress].push(
            MedicalRecord(medicalRecordAddress)
        );

        emit MedicalRecordAdded(patientAddress, medicalRecordAddress);
    }

    function getMedicalRecords(
        address patientAddress,
        MedicalRecord.MedicalRecordType[] memory recordTypes
    ) public view patientOnly(patientAddress) returns (address[] memory) {
        require(
            msg.sender == address(marketplaceInstance) ||
                msg.sender ==
                address(profileMap[patientAddress].patientAddress),
            "Only patient or marketplace can access!"
        );

        // get patient medical records
        MedicalRecord[] memory patientRecords = patientRecordMap[
            patientAddress
        ];
        address[] memory response = new address[](patientRecords.length);
        uint index = 0;

        // if no record type, return all
        if (recordTypes.length > 0) {
            for (uint i = 0; i < patientRecords.length; i++) {
                response[index++] = address(patientRecords[i]);
            }
        } else {
            // filter records base on record type
            for (uint i = 0; i < patientRecords.length; i++) {
                MedicalRecord.MedicalRecordType recordType = patientRecords[i]
                    .getRecordType();

                for (uint j = 0; j < recordTypes.length; j++) {
                    if (recordType == recordTypes[j]) {
                        response[index++] = address(patientRecords[i]);
                        break;
                    }
                }
            }
        }

        return response;
    }

    function isPatient(address patientAddress) public view returns (bool) {
        return profileMap[patientAddress].profileId > 0;
    }
}
