// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./access.sol";

contract multi is access {

    struct Transaction {
        bool executed;
        address payable toAddress;
        uint256 value;
        bytes data;
    }

    mapping(address => uint) balance;
    uint256 public txnCount;
    mapping(uint256 => Transaction) public txns;
    Transaction[] public _validTransactions;

    mapping(uint256 => mapping(address => bool)) public confirmations;


    fallback() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

    modifier isOwnerModifier(address owner) {
        require(
            isOwner[owner] == true,
            "You are not authorized for this action."
        );
        _;
    }

    modifier isConfirmedModifier(uint256 txnId, address owner) {
        require(
            confirmations[txnId][owner] == false,
            "You have already confirmed this txn."
        );
        _;
    }

    modifier isExecutedModifier(uint256 txnId) {
        require(
            txns[txnId].executed == false,
            "This txn has already been executed."
        );
        _;
    }


    constructor(address[] memory _owners) access(_owners) {
        admin = msg.sender;
        require(
            _owners.length >= 3,
            "There need to be atleast 3 initial signatories for this wallet"
        );
        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        uint256 num = mul(owners.length, 60);
        authorisation = div(num, 100);
    }

    function submitTransaction(
        address payable toAddress,
        uint256 value,
        bytes memory data
    ) public isOwnerModifier(msg.sender) returns (uint256 txnId) {

        txnId = txnCount;

        txns[txnId] = Transaction({
            executed: false,
            toAddress: toAddress,
            value: value,
            data: data
        });


        txnCount += 1;


        emit Submission(txnId);

        confirmTransaction(txnId);
    }


    function confirmTransaction(uint256 txnId)
        public
        isOwnerModifier(msg.sender)
        isConfirmedModifier(txnId, msg.sender)
        notNull(txns[txnId].toAddress)
    {
        // update confirmation
        confirmations[txnId][msg.sender] = true;
        emit Confirmation(msg.sender, txnId);

        executeTransaction(txnId);
    }

  
    function executeTransaction(uint256 txnId)
        public
        isOwnerModifier(msg.sender)
        isExecutedModifier(txnId)
    {
        uint256 count = 0;
        bool authorisationReached;


        for (uint256 i = 0; i < owners.length; i++) {

            if (confirmations[txnId][owners[i]]) count += 1;
            if (count >= authorisation) authorisationReached = true;
        }

        if (authorisationReached) {
            Transaction storage txn = txns[txnId];
            txn.executed = true;
            (bool success, ) = txn.toAddress.call{value: txn.value}(txn.data);

            if (success) {
                _validTransactions.push(txn);
                emit Execution(txnId);
            } else {
                emit ExecutionFailure(txnId);
                txn.executed = false;
            }
        }
    }


    function revokeTransaction(uint256 txnId)
        external
        isOwnerModifier(msg.sender)
        isConfirmedModifier(txnId, msg.sender)
        isExecutedModifier(txnId)
        notNull(txns[txnId].toAddress)
    {
        confirmations[txnId][msg.sender] = false;
        emit Revocation(msg.sender, txnId);
    }

    function deposit() public payable isOwnerModifier(msg.sender) {
        
        require(balance[msg.sender] >= 0, "cannot deposiit a calue of 0");
        
        balance[msg.sender] = msg.value;
        
        emit fundsDeposited(msg.sender, msg.value, block.timestamp);
        
    }

    function withdraw(uint amount) public isOwnerModifier(msg.sender) {
        
        require(balance[msg.sender] >= amount);
        
        balance[msg.sender] -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit fundsWithdrawed(msg.sender, amount, block.timestamp);
        
    }

   
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getValidTransactions()
        external
        view
        returns (Transaction[] memory)
    {
        return _validTransactions;
    }

    function getQuorum() external view returns (uint256) {
        return authorisation;
    }
}