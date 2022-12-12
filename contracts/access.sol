// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;



contract access {


    event Deposit(address indexed sender, uint256 value);
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event authorisationUpdate(uint256 authorisation);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event fundsDeposited(address sender, uint amount, uint timeOfTransaction);
    event fundsWithdrawed(address sender, uint amount, uint timeOfTransaction);


    address public admin;

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public authorisation;

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * Modifiers
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin restricted function");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "Specified destination doesn't exist");
        _;
    }

    modifier ownerExistsMod(address owner) {
        require(isOwner[owner] == true, "This owner doesn't exist");
        _;
    }

    modifier notOwnerExistsMod(address owner) {
        require(isOwner[owner] == false, "This owner already exists");
        _;
    }

    /**
     * @dev Contract constructor instantiates wallet interface and sets msg.sender to admin
     */
    constructor(address[] memory _owners) {
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


    function addOwner(address owner)
        public
        onlyAdmin
        notNull(owner)
        notOwnerExistsMod(owner)
    {
 
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);

     
        updateAuthorisation(owners);
    }

    function removeOwner(address owner)
        public
        onlyAdmin
        notNull(owner)
        ownerExistsMod(owner)
    {
        isOwner[owner] = false;

        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();

        updateAuthorisation(owners);
    }


    function transferOwner(address _from, address _to)
        public
        onlyAdmin
        notNull(_from)
        notNull(_to)
        ownerExistsMod(_from)
        notOwnerExistsMod(_to)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == _from) {
                owners[i] = _to;
                break;
            }

  
        isOwner[_from] = false;
        isOwner[_to] = true;


        emit OwnerRemoval(_from);
        emit OwnerAddition(_to);
    }

  
    function transferAdmin(address newAdmin) public onlyAdmin {
        
        admin = newAdmin;
        emit AdminTransferred(admin,newAdmin);
    }

    function renounceAdmin() public onlyAdmin {

        admin = address(0);
        emit AdminTransferred(admin, address(0));
    }

    function updateAuthorisation(address[] memory _owners) internal {
        uint256 num = mul(_owners.length, 60);
        authorisation = div(num, 100);

        emit authorisationUpdate(authorisation);
    }
}