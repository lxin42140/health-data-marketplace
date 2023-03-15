pragma solidity ^0.5.0;

import "./ERC20.sol";

contract MedToken {
    ERC20 erc20Contract;
    address owner;

    constructor() public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
    }

    /**
     * Check if caller is patient, organisation or marketplace
     */
    modifier authorizedOnly() {
        // There does not seem to be an explicit way to check if msg.sender is of
        // a specific contract type.
        // Doing a workaround by calling a function that is specific to the contract
        require(
            msg.sender.iAmPatient() ||
                msg.sender.iAmOrganization() || //TODO: Add functions to organisation and marketplace once merged
                msg.sender.iAmMarketPlace(),
            "Not allowed to mint token!"
        );
        _;
    }

    /**
     * @dev Function to give DT to the recipient for a given wei amount
     * @param recipient address of the recipient that wants to buy the DT
     * @param weiAmt uint256 amount indicating the amount of wei that was passed
     * @return A uint256 representing the amount of DT bought by the msg.sender.
     */
    function getCredit(address recipient, uint256 weiAmt)
        public
        authorizedOnly
        returns (uint256)
    {
        uint256 amt = weiAmt / (1000000000000000000 / 100); // Convert weiAmt to MT
        erc20Contract.mint(recipient, amt);
        return amt;
    }

    /**
     * @dev Function to check the amount of DT the msg.sender has
     * @param ad address of the recipient that wants to check their DT
     * @return A uint256 representing the amount of DT owned by the msg.sender.
     */
    function checkCredit(address ad) public view returns (uint256) {
        uint256 credit = erc20Contract.balanceOf(ad);
        return credit;
    }

    /**
     * @dev Function to transfer the credit from the owner to the recipient
     * @param recipient address of the recipient that will gain in DT
     * @param amt uint256 aount of DT to transfer
     */
    function transferCredit(address recipient, uint256 amt) public {
        // Transfers from tx.origin to receipient
        erc20Contract.transfer(recipient, amt);
    }
}
