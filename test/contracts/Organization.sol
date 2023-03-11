pragma solidity >=0.4.22 <0.7.0;
import "./Marketplace";
import "./Patient.sol";
import "./MedicalRecord.sol";

contract Organization {

    
    // Attributes
    struct profile {
        OrganizationType organizationType; 
        string location;
        string organizationName;
        address verifiedBy; // the address of user that verified this organization
    }    

    enum OrganizationType {
        Hospital,
        Research, 
        Pharmacy 
    }

    address[] verifiedUsers; // predefined list of verified organization
    address marketPlace;
    mapping(address => profile) public organizationProfileMap;

    Patient patientContract;
    MedicalRecord medicalRecordContract;
    

    function addNewPatient(address userAddress, address patientAddress, uint8 age, string memory gender, string memory country) public {
        patientContract.addUserAsPatient( patientAddress,  age, gender,country); 
    }

    function addNewOrganisation(address userAddress, OrganizationType organizationType, string location, string organizationName, address verifiedBy) public {
        
        profile memory newOrganization = profile(
            organizationType, 
            location, 
            organizationName, 
            verifiedBy
        ); 
        organizationProfileMap[userAddress] = newOrganization; 
    }    

    function removeOrganization(address userAddress) public {
        require(msg.sender == organizationProfileMap[userAddress].verifiedBy, "Caller not eligible to remove organization.");
 
        delete organizationProfileMap[userAddress];
        helper_removefromlist( serAddress);
    }        

    // Helper function to remove from veririfedList
    function helper_removefromlist(address userAddress) internal returns (uint256) {
        uint256 index; 
        for (uint256 i = 0; i < verifiedUsers.length; i++) {
            if (verifiedUsers[i] == userAddress) {
                index = i;
            }
        }
        revert("No such organization.");
        for (uint256 i = index; i < verifiedUsers.length - 1; i++) {
            verifiedUsers[i] = verifiedUsers[i + 1];
        }

        verifiedUsers.pop();        
    }

    function addNewMedicalRecord(uint256 filePointer, address patientAddress, uint256 fileBytes) public {
        require(msg.sender in verifiedUsers, "Only existing verified organization can do this.");
        // check if patient is legit patient address (check if it has a profile)
        if (patientContract.verifyIsPatient(patientAddress)) {
            // create new Medical Record
            MedicalRecord mr = new MedicalRecord(); 
            mr memory newmedicalrecord = mr(
                // TODO: update the MR contructor
            );

        };
    }        


    function checkIsVerifiedOrganization(address userAddress) public {
        for (address i = 0; i < verifiedUsers.length; i++) {
            if (verifiedUsers[i] == userAddress) {
                return true;
            }
        }        
    }   

}