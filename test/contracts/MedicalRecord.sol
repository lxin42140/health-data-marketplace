pragma solidity ^0.5.0;
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
    struct Metadata {
        MedicalRecordType medicalRecordType;
        uint dateCreated;
        address issuedBy; //organizationAddress
        address owner; //ownerAddress
        string filePointer; //URI of file
    }

    /** PROPERTIES */
    Marketplace public marketplaceInstance;
    Patient public patientInstance;
    Organization public orgInstance;
    Metadata metadata;

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
        uint dateCreated,
        address issuedBy,
        address owner,
        string memory uri,
        address marketplace,
        address patient,
        address org
    ) public {
        metadata = Metadata(typeOfRecord, dateCreated, issuedBy, owner, uri);

        marketplaceInstance = Marketplace(marketplaceInstance);
        orgInstance = Organization(org);
        patientInstance = Patient(patient);
    }

    /********************MODIFIERS *****/
    modifier marketplaceOnly() {
        require(marketplaceInstance == msg.sender, "Marketplace only!");

        _;
    }

    modifier ownerOnly() {
        require(metadata.owner == msg.sender, "Owner only!");

        _;
    }

    modifier issuedByOnly() {
        require(
            metadata.issuedBy == msg.sender,
            "Organization that issued the record only!"
        );

        _;
    }

    /********************APIS *****/

    function checkIsIssuedBy(
        address organizationAddress
    ) public returns (bool) {
        require(
            msg.sender == marketplaceInstance || msg.sender == metadata.owner,
            "Marketplace and owner only!"
        );

        return organizationAddress == metadata.issuedBy;
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

    function getRecordMetadata() public returns (Metadata memory) {
        require(
            msg.sender == marketplaceInstance ||
                msg.sender == metadata.owner ||
                metadata.issuedBy == msg.sender,
            "Marketplace, owner and organization that issued the record only!"
        );

        return metadata;
    }
}
