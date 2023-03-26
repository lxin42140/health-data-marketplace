// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Marketplace.sol";
import "./Patient.sol";
import "./Organization.sol";

contract MedToken {
    /** PROPERTIES */
    ERC20 erc20Contract;
    Marketplace marketplaceInstance;
    Patient patientInstance;
    Organization orgInstance;

    constructor(address patient, address org) {
        ERC20 e = new ERC20();
        erc20Contract = e;
        marketplaceInstance = Marketplace(msg.sender);
        patientInstance = Patient(patient);
        orgInstance = Organization(org);
    }

    /**
     * Check if caller is patient, organisation or marketplace
     */
    modifier authorizedOnly() {
        require(
            marketplaceInstance.isMarketplace(msg.sender) ||
                orgInstance.isVerifiedOrganization(msg.sender) ||
                patientInstance.isPatient(msg.sender),
            "Only patient, marketplace and organization can perform this action!"
        );
        _;
    }

    /**
     * @dev Function to give DT to the recipient for a given wei amount
     * @param recipient address of the recipient that wants to buy the DT
     * @param weiAmt uint256 amount indicating the amount of wei that was passed
     * @return A uint256 representing the amount of DT bought by the msg.sender.
     */
    function getCredit(
        address recipient,
        uint256 weiAmt
    ) public authorizedOnly returns (uint256) {
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
