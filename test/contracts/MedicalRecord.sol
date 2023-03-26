// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Marketplace.sol";
import "./Patient.sol";
import "./Organization.sol";

contract MedicalRecord {
    /** CONSTANTS */
    enum MedicalRecordType {
        Prescription,
        Diagnoses,
        Procedure,
        Test,
        TreatmentPlan
    }

    /** STRUCTS */
    // struct Metadata {
    //     MedicalRecordType medicalRecordType;
    //     uint dateCreated;
    //     address issuedBy; //organizationAddress
    //     address owner; //ownerAddress
    //     string filePointer; //URI of file
    // }

    /** PROPERTIES */
    Marketplace public marketplaceInstance;
    Patient public patientInstance;
    Organization public orgInstance;
    // Metadata metadata;
    MedicalRecordType medicalRecordType;
    uint dateCreated;
    address issuedBy; //organizationAddress
    address owner; //ownerAddress
    string filePointer; //URI of file

    /** SWITCH */
    bool public contractStopped;
    bool public isValid;

    /** EVENTS */
    event MedicalRecordAdded(address newMedicalRecord);
    event ContractStopped();
    event ContractResumed();
    event RecordInvalidated();
    event RecordValidated();

    constructor(
        MedicalRecordType typeOfRecord,
        uint createdDate,
        address issuedByOrg,
        address patient,
        string memory uri,
        address marketplaceAddress,
        address patientAddress,
        address orgAddress
    ) {
        // metadata = Metadata(typeOfRecord, dateCreated, issuedBy, owner, uri);
        medicalRecordType = typeOfRecord;
        dateCreated = createdDate;
        issuedBy = issuedByOrg;
        owner = patient;
        filePointer = uri;

        marketplaceInstance = Marketplace(marketplaceAddress);
        orgInstance = Organization(orgAddress);
        patientInstance = Patient(patientAddress);
    }

    /********************MODIFIERS *****/
    modifier marketplaceOnly() {
        require(
            address(marketplaceInstance) == msg.sender,
            "Marketplace only!"
        );

        _;
    }

    modifier ownerOnly() {
        require(owner == msg.sender, "Owner only!");

        _;
    }

    modifier issuedByOnly() {
        require(
            issuedBy == msg.sender,
            "Organization that issued the record only!"
        );

        _;
    }

    /********************APIS *****/

    function checkIsIssuedBy(
        address organizationAddress
    ) public view returns (bool) {
        require(
            msg.sender == address(marketplaceInstance) || msg.sender == owner,
            "Marketplace and owner only!"
        );

        return organizationAddress == issuedBy;
    }

    function toggleContractStopped() public ownerOnly {
        contractStopped = !contractStopped;

        if (contractStopped) {
            emit ContractStopped();
        } else {
            emit ContractResumed();
        }
    }

    function toggleValidity() public issuedByOnly {
        isValid = !isValid;

        if (isValid) {
            emit RecordValidated();
        } else {
            emit RecordInvalidated();
        }
    }

    function getRecordType() public view returns (MedicalRecordType) {
        require(
            msg.sender == address(marketplaceInstance) ||
                msg.sender == address(patientInstance) ||
                msg.sender == address(orgInstance) ||
                msg.sender == owner ||
                msg.sender == issuedBy,
            "No permission to access the record!"
        );

        return medicalRecordType;
    }

    // function getRecordMetadata() public view returns (Metadata memory) {
    //     require(
    //         msg.sender == address(marketplaceInstance) ||
    //             msg.sender == address(patientInstance) ||
    //             msg.sender == address(orgInstance) ||
    //             msg.sender == metadata.owner ||
    //             msg.sender == metadata.issuedBy,
    //         "No permission to access the record!"
    //     );

    //     return metadata;
    // }
}
