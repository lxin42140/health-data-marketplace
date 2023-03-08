pragma solidity ^0.5.0;
import "./Organization.sol";
import "./MedicalRecord.sol";

contract MedicalRecord {

    enum Type {
        Prescription, 
        Diagnoses, 
        Procedure, 
        Test, 
        TreatmentPlan 
        }

    struct medicalRecord {
        Type medicalRecordType;
        uint dateCreated;
        address issuedBy; //organizationAddress
        address owner; //ownerAddress
        string fileHash;
        string filePointer;
    }

    address marketPlace;
    bool contractStopped;
    bool isValid;
    Organization organizationContract;

    function addNewMedRecord(Type typeOfRecord, string memory filePointer, bytes memory file, address issuer, address owner, address marketPlace) public returns(address){
        require(organizationContract.checkIsVerifiedOrganization(msg.sender), "Only verified organizations can add user");
        string newFileHash = abi.encode(file);
        
        //how to check if the fileHash is the same

       medicalRecord medRec = medicalRecord(
        typeOfRecord,
        block.timestamp,
        issuer,
        owner,
        newFileHash
        //needsThePointer
       );
    }

    function checkIsIssuedBy(address organizationAddress) public returns(bool){
        if(organizationAddress == issuedBy){
            return true;
        } else {
            return false;
        }
    }

    function checkIsValid() public returns(bool){
        return isValid;
    }

    function checkIsContractStopped() public returns(bool) {
        return contractStopped;
    }

    function toggleContractStopped() public returns(bool){
        requires(msg.sender == owner, "only owner of medical record can toggle start/stop of contract");
        contractStopped = !contractStopped;
        return contractStopped;
    }

    function toggleValidity() public returns(bool) {
        require(msg.sender == issuedBy, "only issuer of medical record can toggle validity");
        isValid = !isValid;
        return isValid;
    }

    function getRecordMetadata() public returns(bytes) {
        requires(msg.sender == owner || msg.sender == marketplace);
        return abi.decode(fileHash);
    }

}