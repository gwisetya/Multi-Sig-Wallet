// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract MultiSigWallet{
    address[] public owners;
    mapping (address => bool) public isOwner; 
    mapping (uint256 => mapping(address => bool)) public isConfirmed; 
    uint256 numRequiredConfirmations; 
    Transaction[] public transactions;
    uint256 txIndex; 

    struct Transaction{
        address to;
        uint256 value; 
        bytes data; 
        bool executed; 
        uint256 numConfirmations;
        }

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner"); 
        _;
    }

    modifier txExist(uint256 _txIndex) {
        require(_txIndex < transactions.length, "transaction invalid"); 
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "transaction already executed"); 
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "transaction already confirmed by the sender"); 
        _;
    }

    constructor(address[] memory _owners, uint256 _numRequiredConfirmations) {
        require(_owners.length > 0, "insert at least one owner"); 
        require(_numRequiredConfirmations > 0 && _numRequiredConfirmations <= _owners.length, "Num required confirmations is invalid");
        for(uint256 i = 0; i< _owners.length; i++){
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true; 
        }
        numRequiredConfirmations = _numRequiredConfirmations; 
    }

    function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner(){
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));
        
        emit SubmitTransaction(msg.sender, transactions.length - 1, _to, _value, _data); 
    }

    function confirmTransaction(uint256 _txIndex) public onlyOwner() txExist(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex){
        isConfirmed[_txIndex][msg.sender] = true; 
        transactions[_txIndex].numConfirmations += 1; 
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransactions(uint256 _txIndex) public onlyOwner() txExist(_txIndex) notExecuted(_txIndex) {
        require(transactions[_txIndex].numConfirmations >= numRequiredConfirmations, "not enough confirmations"); 
        transactions[_txIndex].executed = true; 
        (bool success, ) = payable(transactions[_txIndex].to).call{value: transactions[_txIndex].value}("");
        require(success, "transaction unsuccessful"); 
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex) public onlyOwner() txExist(_txIndex) notExecuted(_txIndex){
        require(isConfirmed[_txIndex][msg.sender], "transaction is not confirmed yet"); 
        isConfirmed[_txIndex][msg.sender] = false;
        transactions[_txIndex].numConfirmations -= 1; 
        emit RevokeConfirmation(msg.sender, _txIndex);
    }
}