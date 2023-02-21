pragma solidity >=0.4.22 <0.7.0;
import "./Marketplace";


contract Organization {
    enum OrganizationType {
        Hospital,
        ResearchLabs
    }
    
    Marketplace marketplace;
    // MedicalRecord medicalRecord;
    OrganizationType public typeOfBuyer;

    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function referUser(address newBuyer) public isOwner {
        marketplace.addToListOfAuthenticatedBuyers(newBuyer);
    }

    /*
    Only hopsitals can upload records 
     */
    function upload(address medicalRecordAddress) public isOwner {

    }
}