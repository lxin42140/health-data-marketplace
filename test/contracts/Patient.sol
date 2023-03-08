pragma solidity ^0.5.0;
import "./Organization.sol";
import "./MedicalRecord.sol";

contract Patient {

    struct profile {
        address issuedBy; // organization that add this user as patient
        address patientAddress;
        uint8 age;
        patientGender gender;
        string country;
    }

    Organization organizationContract;
    MedicalRecord medicalRecordContract;
    address marketPlace;
    mapping(address => profile) public profileMap;
    mapping(address => address[]) public recordMap; // list of medical records associated with each patient

    function addUserAsPatient(address patientAddress, uint8 age, string memory gender, string memory country) public { 
        //Only verified organizations can add user
        require(organizationContract.checkIsVerifiedOrganization(msg.sender), "Only verified organizations can add user");
        require(gender == "M" || gender == "F", "Gender input wrong format");

        //new patient object
        profile newProfile = profile(
            msg.sender,
            patientAddress,
            age,
            gender,
            country
        );

        profileMap[patientAddress] = newProfile; 
    }

    function addNewMedicalRecord(address patientAddress, address medicalRecordAddress) public {
        require(medicalRecordContract.checkIsIssuedBy(msg.sender), "Only the organization that issued the record can add it to the patient");
        require(medicalRecordContract.checkIsValid(medicalRecordAddress), "Medical record is not valid");

        recordMap[patientAddress].push(medicalRecordAddress);        
    }

    function getMedicalRecords(address patientAddress) public view returns(address[]) {
        require(msg.sender == patientAddress || msg.sender == marketPlace, "Only patients themselves and marketplace can access the call");
        return recordMap[patientAddress];
    }

    function addMarketPlace(address marketAddress) public {
        marketPlace = marketAddress;
    }
}