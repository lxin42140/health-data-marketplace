// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Organization.sol";
import "./Patient.sol";
import "./MedToken.sol";
import "./MedicalRecord.sol";

contract Marketplace {
    /** CONSTANTS */
    uint256 constant SECONDS_IN_DAYS = 86400;

    /** STRUCTS */
    struct Listing {
        uint256 id;
        address listingOwner;
        uint timeUnit; // fixed to 1 day
        uint256 price;
        MedicalRecord.MedicalRecordType[] recordTypes;
        Organization.OrganizationType[] allowOrganizationTypes;
        uint256 expirationDate;
    }

    struct Purchase {
        Listing listing; // listing snapshot
        uint256 accessStartDate;
        uint256 expirationDate;
        uint256 otp;
        address[] medicalRecordPointers;
    }

    // struct QueryResponse {
    //     Listing[] matchingListings;
    // }

    /** PROPERTIES */
    Organization public orgInstance;
    Patient public patientInstance;
    MedToken public medTokenInstance;
    // owner of marketplace
    address public owner = msg.sender;
    // commission of marketplace e.g. 10 == 10%
    uint256 public marketCommissionRate;
    uint256 public orgCommissionRate;
    // to use as ID, increment only
    uint256 listingId;
    // map id to the listing
    mapping(uint => Listing) listingMap;
    // map buyer address to list of its purchases
    mapping(address => Purchase[]) purchases;

    /** EVENTS */
    event ListingAdded(address seller, uint256 listingId); // event of adding a listing
    event ListingRemoved(uint256 listingId, string description); // event of removing a listing
    event ListingPurchased(
        address buyer,
        uint256 listingId,
        uint256 startDate,
        uint256 expiryDate,
        uint256 paidPrice
    ); // event of purchasing a listing access

    constructor(uint256 marketFee, uint256 orgFee) {
        marketCommissionRate = marketFee;
        orgCommissionRate = orgFee;

        patientInstance = new Patient();
        orgInstance = new Organization();

        //MedToken depends on marketplace, patient and organization
        medTokenInstance = new MedToken(
            address(patientInstance),
            address(orgInstance)
        );

        // Organization depends on marketplace and patient
        orgInstance.setPatientInstance(address(patientInstance));

        // Patient depends on marketplace and organization
        patientInstance.setOrgInstance(address(orgInstance));
    }

    /********************MODIFIERS *****/

    modifier ownerOnly() {
        require(msg.sender == owner, "Only only!");

        _;
    }

    modifier organisationOnly(address organization) {
        require(
            orgInstance.isVerifiedOrganization(organization),
            "Verified organization only!"
        );

        _;
    }

    modifier patientOnly(address patient) {
        require(patientInstance.isPatient(patient), "Patient only!");

        _;
    }

    modifier validListingOnly(uint256 id) {
        require(listingMap[id].id != 0, "Invalid listing!");

        _;
    }

    modifier removeExpiredListing() {
        for (uint i = 0; i <= listingId; i++) {
            if (isExpired(listingMap[i].expirationDate)) {
                delete listingMap[i];
                emit ListingRemoved(i, "Expired listing");
            }
        }

        _;
    }

    /********************UTILITY FUNCTIONS *****/

    // returns true if input date is earlier than block timestamp
    function isExpired(uint256 date) private view returns (bool) {
        return date > 0 && block.timestamp > date;
    }

    // generate a 6 digit OTP which is used to access the DB
    function generateRandomOTP() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        );
        uint256 random = uint256(keccak256(abi.encodePacked(seed)));
        uint256 otp = random % 1000000;
        return otp;
    }

    // common method to get the purchase detail given buyer address and listing id
    function getPurchaseDetails(
        address buyer,
        uint256 id
    ) private view returns (Purchase memory) {
        Purchase[] memory orgPurchaseHistory = purchases[buyer];
        uint index = 0;
        bool purchaseExists = false;

        // find the purchase
        for (uint i = 0; i < orgPurchaseHistory.length; i++) {
            if (orgPurchaseHistory[i].listing.id == id) {
                index = i;
                purchaseExists = true;
                break;
            }
        }

        // check if org has purchased the listing
        require(purchaseExists, "Did not purchase the listing!");

        Purchase memory purchase = orgPurchaseHistory[index];

        // check if accesss has expired
        require(!isExpired(purchase.expirationDate), "Purchase has expired!");

        // retrieve matching medical record addresses
        address[] memory matchingRecords = patientInstance.getMedicalRecords(
            purchase.listing.listingOwner,
            purchase.listing.recordTypes
        );

        purchase.medicalRecordPointers = matchingRecords;

        return purchase;
    }

    /********************APIS *****/

    function isOwner(address user) public view returns (bool) {
        return user == owner;
    }

    function isMarketplace(address user) public view returns (bool) {
        return user == address(this);
    }

    function addListing(
        uint256 price,
        MedicalRecord.MedicalRecordType[] memory recordTypes,
        Organization.OrganizationType[] memory allowOrganizationTypes,
        uint256 daysTillExpiry
    )
        public
        patientOnly(msg.sender)
        removeExpiredListing
        returns (Listing memory)
    {
        // determine expiry, if any
        uint256 expiry = 0;
        if (daysTillExpiry > 0) {
            expiry = block.timestamp + daysTillExpiry * SECONDS_IN_DAYS;
        }

        // incre id
        listingId++;

        // create new listing and add to map
        Listing memory newListing = Listing(
            listingId, // id
            msg.sender, // listingOwner
            1 days, // timeUnit
            price, // price per time unit
            recordTypes,
            allowOrganizationTypes,
            expiry
        );

        listingMap[listingId] = newListing;
        emit ListingAdded(msg.sender, listingId);

        return listingMap[listingId];
    }

    function removeListing(
        uint256 id
    ) public validListingOnly(id) returns (Listing memory) {
        Listing memory listing = listingMap[id];

        // only listing ower can remove listing
        require(
            msg.sender == listing.listingOwner,
            "Only listing owner can perform this action!"
        );

        delete listingMap[id];

        emit ListingRemoved(id, "Remove by owner!");

        return listing;
    }

    function buyListing(
        uint256 id,
        uint256 daysToPurchase
    )
        public
        organisationOnly(msg.sender)
        removeExpiredListing
        validListingOnly(id)
        returns (Purchase memory)
    {
        /**************PURCHASE REQUIREMENT CHECK******/

        // must purchase for at least 30 days
        require(daysToPurchase > 30, "Invalid purchase duration! Min 30 days");

        // only verified buyers can buy
        require(
            orgInstance.isVerifiedOrganization(msg.sender),
            "Only verified organizations can buy listing!"
        );

        Listing memory listing = listingMap[id];

        // only allowed organizations can purchase
        if (listing.allowOrganizationTypes.length > 0) {
            Organization.Profile memory orgProfile = orgInstance.getOrgProfile(
                msg.sender
            );

            bool isAllowed = false;

            for (
                uint256 i = 0;
                i < listing.allowOrganizationTypes.length;
                i++
            ) {
                if (
                    listing.allowOrganizationTypes[i] ==
                    orgProfile.organizationType
                ) {
                    isAllowed = true;
                    break;
                }
            }

            require(isAllowed, "Organization is banned by listing owner!");
        }

        // check if buyer has enough tokens to pay
        // for now, default to charge by per day
        uint256 totalPrice = listing.price * daysToPurchase;
        require(
            medTokenInstance.checkCredit(msg.sender) >= totalPrice,
            "Insufficient tokens!"
        );

        /**************PURCHASE RECORD******/

        // find existing purchase associated with the same listing
        Purchase[] memory existingPurchases = purchases[msg.sender];
        uint256 index = 0;
        bool purchaseExists = false;

        for (uint i = 0; i < existingPurchases.length; i++) {
            if (existingPurchases[i].listing.id == id) {
                index = i;
                purchaseExists = true;
                break;
            }
        }

        if (purchaseExists) {
            // if access is not expired, prevent buyer from purchasing again
            require(
                isExpired(existingPurchases[index].expirationDate),
                "Previous purchase has not expired yet!"
            );

            // if listing has expired, update the purchase details
            existingPurchases[index].accessStartDate = block.timestamp;
            existingPurchases[index].expirationDate =
                block.timestamp +
                (daysToPurchase * SECONDS_IN_DAYS);
            existingPurchases[index].otp = generateRandomOTP();
        } else {
            // create new purchase history and add to list
            address[] memory recordAddress;

            Purchase memory newPurchase = Purchase(
                listing, // struct is pass by value
                block.timestamp, // access start date
                block.timestamp + (daysToPurchase * SECONDS_IN_DAYS), // expiry date of access
                generateRandomOTP(), // OTP to access DB
                recordAddress
            );

            // add to purchases
            purchases[msg.sender].push(newPurchase);
            index = purchases[msg.sender].length - 1;
        }

        /**************FUND TRANSFER******/

        uint256 marketCommission = (totalPrice / 100) * marketCommissionRate;
        uint256 orgComission = (totalPrice / 100) * orgCommissionRate;
        uint256 sellerEarning = totalPrice - marketCommission - orgComission;

        address patient = listing.listingOwner;
        Patient.Profile memory profile = patientInstance.getPatientProfile(
            patient
        );
        address issuedBy = profile.issuedBy;

        medTokenInstance.transferCredit(address(this), marketCommission);
        medTokenInstance.transferCredit(listing.listingOwner, sellerEarning);
        medTokenInstance.transferCredit(issuedBy, orgComission);

        emit ListingPurchased(
            msg.sender,
            id,
            existingPurchases[index].accessStartDate,
            existingPurchases[index].expirationDate,
            totalPrice
        );

        return purchases[msg.sender][index];
    }

    // for the market to get purchase details of all buyers
    // for DB layer
    function marketGetPurchaseDetails(
        address org,
        uint256 id
    ) public view ownerOnly returns (Purchase memory) {
        return getPurchaseDetails(org, id);
    }

    // for individual organisation to get their purchase details
    function buyerGetPurchaseDetails(
        uint256 id
    )
        public
        organisationOnly(msg.sender)
        removeExpiredListing
        returns (Purchase memory)
    {
        return getPurchaseDetails(msg.sender, id);
    }

    // function searchListings(
    //     uint8 age,
    //     string memory gender,
    //     string memory country,
    //     string memory medicalRecordType
    // )
    //     public
    //     organisationOnly(msg.sender)
    //     removeExpiredListing
    //     returns (QueryResponse memory)
    // {
    //     Listing[] memory matchingListings;

    //     for (uint i = 0; i <= listingId; i++) {
    //         Listing memory currListing = listingMap[i];

    //         // TODO: use patient to get the profile and check base on filter
    //         // TODO: use patient to get listing of medical records
    //         // TODO: use list of medical records to check if any of the records are matching
    //     }

    //     QueryResponse memory resp = QueryResponse(matchingListings);

    //     return resp;
    // }
}
