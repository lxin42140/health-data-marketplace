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

    /** STRUCT */
    struct Metadata {
        address patient;
        address issuedBy;
        address record;
        uint dateCreated;
        MedicalRecordType recordType;
        string uri;
    }

    /** PROPERTIES */
    address public patientInstance;
    address public marketplaceInstance;
    uint createdDate = block.timestamp;
    address issuedBy;
    address owner;
    MedicalRecordType medicalRecordType;
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
        address issuedByOrg,
        address patient,
        string memory uri,
        address patientContract,
        address market
    ) {
        medicalRecordType = typeOfRecord;
        issuedBy = issuedByOrg;
        owner = patient;
        filePointer = uri;
        patientInstance = patientContract;
        marketplaceInstance = market;
    }

    /********************MODIFIERS *****/
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

    // TESTED
    function getMetadata() public view returns (Metadata memory) {
        require(
            msg.sender == marketplaceInstance ||
                msg.sender == issuedBy ||
                msg.sender == owner ||
                Marketplace(marketplaceInstance).hasPurchasedAccessToRecord(
                    msg.sender,
                    address(this)
                ),
            "No access!"
        );

        Metadata memory data = Metadata(
            owner,
            issuedBy,
            address(this),
            createdDate,
            medicalRecordType,
            filePointer
        );

        return data;
    }

    // TESTED
    function getRecordType() public view returns (MedicalRecordType) {
        require(
            msg.sender == marketplaceInstance ||
                msg.sender == issuedBy ||
                msg.sender == owner ||
                Marketplace(marketplaceInstance).hasPurchasedAccessToRecord(
                    msg.sender,
                    address(this)
                ),
            "No access!"
        );

        return medicalRecordType;
    }

    // TESTED
    function getFilePointer() public view returns (string memory) {
        require(
            msg.sender == marketplaceInstance ||
                msg.sender == issuedBy ||
                msg.sender == owner ||
                Marketplace(marketplaceInstance).hasPurchasedAccessToRecord(
                    msg.sender,
                    address(this)
                ),
            "No access!"
        );

        return filePointer;
    }
}
