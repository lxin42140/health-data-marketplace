pragma solidity ^0.5.0;
import "./Organization.sol";
import "./Patient.sol";
import "./MedToken.sol";

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
        Listing listing; // listing snapshot
        uint256 accessStartDate;
        uint256 expirationDate;
        string otp;
        address[] medicalRecordPointers;
    }

    struct QueryResponse {
        Listing[] matchingListings;
    }

    /** PROPERTIES */
    // owner of marketplace
    address owner;
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
    event ListingRemoved(uint256 listingId, String description); // event of removing a listing
    event ListingPurchased(
        address buyer,
        uint256 listingId,
        uint256 startDate,
        uint256 expiryDate,
        uint256 paidPrice
    ); // event of purchasing a listing access

    constructor(uint256 marketFee, uint256 orgFee) public {
        owner = msg.sender;
        comissionFee = fee;
        listingId = 1;
    }

    /********************MODIFIERS *****/

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
    function isExpired(uint256 date) private pure returns (bool) {
        return date > 0 && now > date;
    }

    // generate a 6 digit OTP which is used to access the DB
    function generateRandomOTP() private pure returns (uint256) {
        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );
        uint256 random = uint256(keccak256(abi.encodePacked(seed)));
        uint256 otp = random % 1000000;
        return otp;
    }

    /********************APIS *****/

    function checkIsOwner(address user) public view returns (bool) {
        return user == owner;
    }

    function addListing(
        uint256 price,
        string memory recordTypes,
        string memory allowOrganizationTypes,
        uint256 daysTillExpiry
    )
        public
        patientOnly
        hasRecordsOnly(recordTypes)
        removeExpiredListing
        returns (Listing memory)
    {
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

        emit ListingRemoved(id, "Remove by owner");

        return listing;
    }

    function buyListing(
        uint256 id,
        uint256 daysToPurchase
    )
        public
        organisationOnly
        removeExpiredListing
        validListingOnly(id)
        returns (Purchase memory)
    {
        /**************PURCHASE REQUIREMENT CHECK******/

        // must purchase for at least 30 days
        require(daysToPurchase > 30, "Invalid purchase duration! Min 30 days");

        // Only verified buyers can buy
        require(
            Organization.checkIsVerifiedOrganization(msg.sender),
            "Only verified organizations can buy listing!"
        );

        Listing listing = listingMap[id];

        if (listing.allowOrganizationTypes) {
            // TODO: check if buyer is allowed to purchase listing
        }

        // check if buyer has enough tokens to pay
        // for now, default to charge by per day
        uint256 totalPrice = listing.price * daysToPurchase;
        require(
            MedToken.checkCredit(msg.sender) >= totalPrice,
            "Insufficient tokens!"
        );

        /**************PURCHASE RECORD******/

        // find existing purchase associated with the same listing
        Purchase[] memory existingPurchases = purchases[msg.sender];
        uint256 index = -1;
        for (uint i = 0; i < existingPurchases.length; i++) {
            if (existingPurchases[i].listingId == id) {
                index = i;
                break;
            }
        }

        if (index > 0) {
            // if access is not expired, prevent buyer from purchasing again
            require(
                isExpired(existingPurchases[index].expirationDate),
                "Previous purchase has not expired yet!"
            );

            // if listing has expired, update the purchase details
            existingPurchases[index].accessStartDate = now;
            existingPurchases[index].expirationDate =
                now +
                (daysToPurchase * SECONDS_IN_DAYS);
            existingPurchases[index].otp = generateRandomOTP();
        } else {
            // create new purchase history and add to list
            Purchase memory newPurchase = Purchase(
                listing, // struct is pass by value
                now, // access start date
                now + (daysToPurchase * SECONDS_IN_DAYS), // expiry date of access
                generateRandomOTP() // OTP to access DB
            );

            // add to purchases
            purchases[msg.sender].push(newPurchase);
            index = purchases[msg.sender].length - 1;
        }

        /**************FUND TRANSFER******/

        uint256 marketCommission = (totalPrice / 100) * marketCommissionRate;
        uint256 orgComission = (totalPrice / 100) * orgComission;
        uint256 sellerEarning = totalPrice - marketCommission - orgComission;

        address patient = listing.listingOwner;
        //TODO: get issued by of patient

        MedToken.transferCredit(address(this), marketCommission);
        MedToken.transferCredit(listing.listingOwner, sellerEarning);
        //TODO: transfer credit to the org that added the user

        emit ListingPurchased(
            msg.sender,
            id,
            purchase.accessStartDate,
            purchase.expirationDate,
            totalPrice
        );

        return purchases[msg.sender][index];
    }

    function getPurchaseDetails(
        uint256 id
    ) public organisationOnly removeExpiredListing returns (Purchase memory) {
        Purchase[] memory orgPurchaseHistory = purchases[msg.sender];
        uint256 index = -1;

        // find the purchase
        for (uint i = 0; i < orgPurchaseHistory.length; i++) {
            if (orgPurchaseHistory[i].listing.id == id) {
                index = i;
                break;
            }
        }

        // check if org has purchased the listing
        require(index > 0, "Did not purchase the listing!");

        Purchase memory purchase = orgPurchaseHistory[index];

        // check if accesss has expired
        require(!isExpired(purchase.expirationDate), "Purchase has expired!");

        address patient = purchase.listing.listingOwner;
        //TODO: get matching medical record addresses from patients

        return purchase;
    }

    function searchListings(
        uin256 age,
        string memory gender,
        string memory country,
        string memory medicalRecordType
    )
        public
        organisationOnly
        removeExpiredListing
        returns (QueryResponse memory)
    {
        Listing[] memory matchingListings = Listing[];
        for (uint i = 0; i <= listingId; i++) {
            Listing memory currListing = listingMap[i];

            // TODO: use patient to get the profile and check base on filter
            // TODO: use patient to get listing of medical records
            // TODO: use list of medical records to check if any of the records are matching
        }

        QueryResponse memory resp = QueryResponse(matchingListings);

        return resp;
    }
}
