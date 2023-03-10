pragma solidity ^0.5.0;
import "./Organization.sol";
import "./Patient.sol";

contract Marketplace {
    /** CONSTANTS */
    uint256 constant SECONDS_IN_DAYS = 86400;

    /** STRUCTS */
    struct Listing {
        uint256 id;
        address listingOwner;
        uint timeUnit; // fixed to 1 day
        uint256 price;
        // TODO: need to wait for medical record to add the enum
        string recordType;
        // TODO: need to wait until org add the enum
        string allowOrganizationTypes;
        uint256 expirationDate;
    }

    struct Purchase {
        uint256 listingId;
        uint256 expirationDate;
        string otp;
    }

    /** PROPERTIES */
    // owner of marketplace
    address owner;
    // commission of marketplace
    uint256 public comissionFee;
    // to use as ID, increment only
    uint256 listingId;
    // map id to the listing
    mapping(uint256 => Listing) listingMap;
    // map buyer address to list of its purchases
    mapping(address => Purchase[]) purchases;

    /** EVENTS */
    event ListingAdded(address seller, uint256 listingId); // event of adding a listing
    event ListingRemoved(uint256 listingId); // event of removing a listing
    event AccessPurchases(address buyer, uint256 listingId, uint256 expiryDate, uint256 amount);

    constructor(uint256 fee) public {
        owner = msg.sender;
        comissionFee = fee;
        listingId = 1;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "Only owner can perform this action!");

        _;
    }

    modifier patientOnly() {
        //TODO: check that msg.sender is in patient smart contract

        _;
    }

    modifier organisationOnly() {
        //TODO: check that msg.sender is in organisation smart contract

        _;
    }

    modifier hasRecordsOnly(string memory recordTypes) {
        // TODO: check that msg.sender has at least one medical records with the provided type, or if none provided
        // at least one record in general

        _;
    }

    modifier validListingOnly(uint256 id) {
        Listing memory listing = listingMap[id];
        require(listing.id != 0, "Invalid listing!");

        _;
    }

    // generate a 6 digit OTP which is used to access the DB
    function generateRandomOTP() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );
        uint256 random = uint256(keccak256(abi.encodePacked(seed)));
        uint256 otp = random % 1000000;
        return otp;
    }

    function addListing(
        uint256 price,
        string memory recordTypes,
        string memory allowOrganizationTypes,
        uint256 daysTillExpiry
    ) public patientOnly hasRecordsOnly(recordTypes) returns (uint256) {
        // determine expiry, if any
        uint256 expiry = 0;
        if (daysTillExpiry > 0) {
            expiry = now + daysTillExpiry * SECONDS_IN_DAYS;
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

        // return listing id
        return listingId;
    }

    function removeListing(uint256 id) public validListingOnly(id) {
        Listing memory listing = listingMap[id];

        // only listing ower can remove listing
        require(
            msg.sender == listing.listingOwner,
            "Only listing owner can perform this action!"
        );

        delete listingMap[id];

        emit ListingRemoved(id);
    }

    function buyListing(
        uint256 id,
        uint256 daysToPurchase
    ) public validListingOnly(id) organisationOnly returns (uint256) {
        // must purchase for at least 30 days
        require(daysToPurchase > 30, "Invalid purchase duration!");

        // Only verified buyers can buy
        require(
            Organization.checkIsVerifiedOrganization(msg.sender),
            "Only verified organizations can buy listing!"
        );

        Listing listing = listingMap[id];

        // TODO: check if buyer is allowed to purchase listing
        if (listing.allowOrganizationTypes) {}

        // check if listing is expired
        if (listing.expirationDate > 0) {
            require(block.timestamp <= timestamp, "Listing has expired!");
        }

        /****************check if buyer has previously purchased the listing*/
        Purchase[] memory existingPurchases = purchases[msg.sender];
        Purchase memory purchase = 0;
        for (uint i = 0; i < existingPurchases.length; i++) {
            if (existingPurchases[i].listingId == listing.id) {
                purchase = existingPurchases[i];
                break;
            }
        }

        if (purchase != 0) {
            // existing purchase exists, extend expiration date
            purchase.expirationDate += (daysToPurchase *
                SECONDS_IN_DAYS);
        } else {
            uint expiry = now + (daysToPurchase * SECONDS_IN_DAYS);
            // create new purchase history and add to list
            Purchase memory newPurchase = Purchase(
                id, // listing id
                expiry, // expiry date of access
                generateRandomOTP() // OTP to access DB
            );
            purchases[msg.sender].push(newPurchase);
            purchase = newPurchase;
        }

        /****************fund transfer*/
        //TODO: fund transfer after adding in token contract

        // return OTP
        return purchase.otp;
    }

    function checkIsOwner(address user) public view returns(bool) {
        return user == owner;
    }
}
