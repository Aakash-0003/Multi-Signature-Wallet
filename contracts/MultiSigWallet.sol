pragma solidity >=0.7.5;
pragma abicoder v2;

contract MultiSigWallet {
    uint256 majority;
    address[3] owners;
    uint256 public Balance;
    enum Status {
        Pending,
        Confirmed,
        Rejected
    }

    //events
    event amountDeposited(uint256 amount, address indexed depositedBy);
    event TransactionConfirmed(uint256 indexed _txnID, address By, address to);
    event TransactionRejected(uint256 indexed _txnID, address By, address to);

    constructor(
        address owner1,
        address owner2,
        address owner3,
        uint256 limit
    ) {
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;
        majority = limit;
    }

    struct Transaction {
        uint256 txnID;
        address creator;
        address recipient;
        uint256 amount;
        uint256 approvals;
        uint256 rejections;
        Status status;
    }

    Transaction[] transactionPool;

    mapping(address => mapping(uint256 => Status)) transactionRecord;

    modifier onlyOwner() {
        require(
            msg.sender == owners[0] ||
                msg.sender == owners[1] ||
                msg.sender == owners[2],
            "YOU'RE NOT AUTHORISED!"
        );
        _;
    }
    modifier sufficientAmount(uint256 _amount) {
        require(_amount <= Balance, "Insufficient Balance");
        _;
    }

    function RequestTransaction(address _recipient, uint256 _amount)
        public
        onlyOwner
        sufficientAmount(_amount)
        returns (Transaction memory)
    {
        Transaction memory newTransaction;
        newTransaction.txnID = transactionPool.length;
        newTransaction.creator = msg.sender;
        newTransaction.recipient = _recipient;
        newTransaction.amount = _amount;
        newTransaction.approvals = 1;
        newTransaction.rejections = 0;
        newTransaction.status = Status.Pending;
        transactionPool.push(newTransaction);
        //mapping record
        transactionRecord[msg.sender][transactionPool.length - 1] = Status
            .Pending;
        return newTransaction;
    }

    function ConfirmTransaction(uint256 _txnID)
        public
        onlyOwner
        returns (Status)
    {
        require(
            transactionRecord[msg.sender][_txnID] == Status.Pending,
            "YOU'VE ALREADY SIGNED THIS TRANSACTION."
        );
        transactionRecord[msg.sender][_txnID] = Status.Confirmed;
        transactionPool[_txnID].approvals += 1;
        if (transactionPool[_txnID].approvals == 2) {
            payable(transactionPool[_txnID].recipient).transfer(
                transactionPool[_txnID].amount
            );
            transactionPool[_txnID].status = Status.Confirmed;
            Balance -= transactionPool[_txnID].amount;
            emit TransactionConfirmed(
                _txnID,
                transactionPool[_txnID].creator,
                transactionPool[_txnID].recipient
            );
        }
        return transactionPool[_txnID].status;
    }

    function RejectTransaction(uint256 _txnID)
        public
        onlyOwner
        returns (Status)
    {
        require(
            transactionRecord[msg.sender][_txnID] == Status.Pending,
            "YOU'VE ALREADY SIGNED THIS TRANSACTION."
        );
        transactionRecord[msg.sender][_txnID] = Status.Rejected;
        transactionPool[_txnID].rejections += 1;
        if (transactionPool[_txnID].rejections == 2) {
            transactionPool[_txnID].status = Status.Rejected;
            emit TransactionRejected(
                _txnID,
                transactionPool[_txnID].creator,
                transactionPool[_txnID].recipient
            );
        }
        return transactionPool[_txnID].status;
    }

    function GetTransactions() public view returns (Transaction[] memory) {
        return transactionPool;
    }

    function deposit() public payable {
        Balance += msg.value;
        emit amountDeposited(msg.value, msg.sender);
    }

    function withdraw(uint256 _amount)
        public
        onlyOwner
        sufficientAmount(_amount)
    {
        RequestTransaction(msg.sender, _amount);
    }
}
