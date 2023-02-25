pragma solidity ^0.5.0;

contract MedicalRecord {

    struct medicalRecord {
        uint256 id;
        address owner;
        address author;
        address[] permissions;
        string fileHash;
    }

    mapping(uint256 => medicalRecord) public record;



}