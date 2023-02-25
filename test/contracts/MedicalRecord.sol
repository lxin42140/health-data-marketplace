pragma solidity ^0.5.0;

contract MedicalRecord {

    struct medicalRecord {
        address owner;
        address author;
        address[] permissions;
        string fileHash;
    }

    mapping(uint256 => medicalRecord) public records;
    uint256 public numRecords = 0;

    event add_record(uint256 id1);

    function addNewPatient(string memory filehash) public returns(uint256) { 
        //new patient object
        address[] memory temp;
        temp[0] = msg.sender;
        medicalRecord memory newRecord = medicalRecord(
            msg.sender,  //owner
            msg.sender, //author
            temp, // permissions
            filehash
        );

        uint256 newRecordId = numRecords++;
        records[newRecordId] = newRecord; 
        return newRecordId; 
    }


}