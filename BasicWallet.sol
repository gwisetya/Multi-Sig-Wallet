// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract BasicWallet{
    address payable public owner; 

    constructor() {
        owner = payable(msg.sender); 
    }

    receive() external payable{}

    function withdraw(uint256 _amount) public{
        require(msg.sender == owner, "not the owner"); 
        payable(msg.sender).transfer(_amount);
    }

     function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}