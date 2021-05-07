pragma solidity 0.7.5;
pragma abicoder v2;

contract multiSigWallet {

    uint private totalBalance;
    address[3] owners;
    uint public numOfApprovalsNeeded;

    constructor(address _owner1, address _owner2, address _owner3, uint _numOfApprovalsNeeded) {
        require(_owner1 != _owner2 && _owner1 != _owner3 && _owner2 != _owner3, "Three different owners needed");
        owners = [_owner1, _owner2, _owner3];
        numOfApprovalsNeeded = _numOfApprovalsNeeded;
    }

    struct Transaction {
        address payable to;
        uint amount;
        uint approvals;
        bool executed;
    }

    Transaction[] transactions;

    mapping(address => mapping(uint => bool)) approved;

    modifier onlyOwners {
        require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2], "Only owners");
        _;
    }

    modifier notApproved (uint _txID) {
        require(!approved[msg.sender][_txID], "You have already approved this transaction");
        _;
    }

    modifier notExecuted (uint _txID) {
        require(!transactions[_txID].executed, "Transaction already executed");
        _;
    }

    function deposit() public payable {
        totalBalance += msg.value;
    }

    function requestTransaction(address payable _to, uint _amount) public onlyOwners {
        require(_to != msg.sender, "Don't send money to yourself");

        createTransaction(_to, _amount);
    }

    function requestWithdrawal(uint _amount) public onlyOwners {
        createTransaction(msg.sender, _amount);
    }

    function createTransaction (address payable _to, uint _amount) private onlyOwners {
        require(_amount <= totalBalance, "Not enough balance");

        transactions.push(Transaction({
            to: _to,
            amount: _amount,
            approvals: 0,
            executed: false
        }));
    }

    function approveTransaction(uint _txID) public onlyOwners notApproved(_txID) notExecuted(_txID) {
        Transaction storage transaction = transactions[_txID];

        transaction.approvals += 1;
        approved[msg.sender][_txID] = true;

        if(transaction.approvals >= numOfApprovalsNeeded) {
            executeTransaction(_txID);
        }
    }

    function executeTransaction(uint _txID) private onlyOwners notExecuted(_txID) {
        require(transactions[_txID].approvals >= numOfApprovalsNeeded, "Not enough approvals");

        Transaction storage transaction = transactions[_txID];
        totalBalance -= transaction.amount;
        transaction.executed = true;
        transaction.to.transfer(transaction.amount);
    }

    function getBalance() public view returns(uint) {
        return totalBalance;
    }

    function getOwners() public view returns(address[3] memory) {
        return owners;
    }

    function getTransaction(uint _txID) public view returns(Transaction memory) {
        return(transactions[_txID]);
    }

    function getNumberOfTransactions() public view returns(uint) {
        return transactions.length;
    }


}
