pragma solidity ^0.5.0;

contract Patient {
    struct patient {
        //patient basic info
        string NRIC;
        // more to add
        address owner;
        mapping(uint256 => string) medicalRecords;
    }

    mapping(uint256 => patient) public patients;
    uint256 public numPatients = 0;

   //modifier to ensure a function is callable only by its owner    
    modifier ownerOnly(uint256 patientId) {
        require(patients[patientId].owner == msg.sender);
        _;
    }
    
    modifier validPatientId(uint256 patientId) {
        require(patientId < numPatients);
        _;
    }

    //are we giving patients value?
     function addNewPatient(string memory nric) public returns(uint256) { 
        //new patient object
        patient memory newPatient = patient(
            nric,
            msg.sender  //owner
        );

        uint256 newPatientId = numPatients++;
        patients[newPatientId] = newPatient; 
        return newPatientId; 
    }

    //transfer ownership of patient?
    function transferOwnership(uint256 patientId, address newOwner) public ownerOnly(patientId) validPatientId(patientId) {
        patients[patientId].owner = newOwner;
    }
}