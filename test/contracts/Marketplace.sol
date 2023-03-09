pragma solidity ^0.5.0;

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
    function generateRandomOTP() public view returns (uint256) {
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
        require(daysToPurchase > 0, "Invalid purchase duration!");


        // check if buyer is allowed to purchase listing

        // check if listing is expired
    }
}
