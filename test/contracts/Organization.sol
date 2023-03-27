// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Marketplace.sol";
import "./Patient.sol";
import "./MedicalRecord.sol";

contract Organization {
    /** CONSTANTS */
    enum OrganizationType {
        Hospital,
        Research,
        Pharmacy
    }

    /** STRUCTS */
    struct Profile {
        uint256 profileId;
        address verifiedBy; // the address of org that verified this organization
        OrganizationType organizationType;
        string location;
        string organizationName;
    }

    /** PROPERTIES */
    address public owner = msg.sender;
    Marketplace public marketplaceInstance;
    Patient public patientInstance;

    mapping(address => Profile) organizationProfileMap;
    uint256 profileId;

    /** EVENTS */
    event OrganizationAdded(address addedBy, address newOrgAddress);
    event OrganizationRemoved(address removedBy, address deletedOrgAddress);

    constructor() {
        profileId++;
        organizationProfileMap[msg.sender] = Profile(
            profileId,
            msg.sender,
            OrganizationType.Hospital,
            "Singapore",
            "NUH"
        );
    }

    /********************MODIFIERS *****/
    modifier ownerOnly() {
        require(msg.sender == owner, "Only only!");

        _;
    }

    modifier verifiedOnly() {
        require(
            organizationProfileMap[msg.sender].profileId > 0,
            "Verified organization only!"
        );

        _;
    }

    modifier marketplaceOnly(address marketplace) {
        require(
            marketplace == address(marketplaceInstance),
            "Marketplace only!"
        );

        _;
    }

    /********************APIs *****/

    function setPatient(address patient) public ownerOnly {
        patientInstance = Patient(patient);
    }

    function setMarketplace(address market) public ownerOnly {
        marketplaceInstance = Marketplace(market);
    }

    function addNewOrganisation(
        address newOrg,
        OrganizationType organizationType,
        string memory location,
        string memory organizationName
    ) public verifiedOnly {
        // check if new org already is verified
        require(
            organizationProfileMap[newOrg].profileId == 0,
            "Organization already added!"
        );

        // incre id
        profileId++;

        // create profile
        Profile memory newProfile = Profile(
            profileId,
            msg.sender, //verified by
            organizationType,
            location,
            organizationName
        );

        organizationProfileMap[newOrg] = newProfile;

        emit OrganizationAdded(msg.sender, newOrg);
    }

    function getOrganizationType(
        address org
    ) public view marketplaceOnly(msg.sender) returns (OrganizationType) {
        return organizationProfileMap[org].organizationType;
    }

    function getOrganizationProfile(
        address org
    ) public view returns (Profile memory) {
        return organizationProfileMap[org];
    }

    function removeOrganization(address orgAddress) public verifiedOnly {
        require(
            organizationProfileMap[orgAddress].profileId > 0,
            "Org to delete is not verified organization!"
        );

        require(
            msg.sender == organizationProfileMap[orgAddress].verifiedBy,
            "Org not eligible to remove organization!"
        );

        delete organizationProfileMap[orgAddress];

        emit OrganizationRemoved(msg.sender, orgAddress);
    }

    function isVerifiedOrganization(
        address userAddress
    ) public view returns (bool) {
        return organizationProfileMap[userAddress].profileId > 0;
    }
}
