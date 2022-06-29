// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/// @title Contract of Rpcp NFTs collection
/// @author Johnleouf21
import "./ERC721A.sol";


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";


contract Rpcp is ERC721A, PaymentSplitter, Ownable, ReentrancyGuard {


    //To concatenate the URL of an NFT
    using Strings for uint256;
   
    uint public constant LIMIT_SUPPLY_RATON = 1000;
    uint public constant LIMIT_SUPPLY_CARCAJOU = 2000;
    uint public constant LIMIT_SUPPLY_RENARD = 3000;
    uint public constant LIMIT_SUPPLY_LOUP = 4000;
    uint public constant LIMIT_SUPPLY_OURS = 5000;

    uint256 public constant COMMISSION_RATE = 10;
    uint256 public constant COMMISSION_CYCLE = 30 * 24 * 60 * 60;
 
    uint public max_mint_allowed = 5000;

    uint public priceRaton = 0.000002 ether;

    uint public priceCarcajou = 0.000006 ether;

    uint public priceRenard = 0.000015 ether;

    uint public priceLoup = 0.00003 ether;

    uint public priceOurs = 0.00006 ether;

    string public baseURIRaton;

    string public baseURICarcajou;

    string public baseURIRenard;

    string public baseURILoup;

    string public baseURIOurs;

    string public notRevealedURIRaton;

    string public notRevealedURICarcajou;

    string public notRevealedURIRenard;

    string public notRevealedURILoup;

    string public notRevealedURIOurs;

    string public baseExtension = ".json";

    bool public revealedRaton = false;

    bool public revealedCarcajou = false;

    bool public revealedRenard = false;

    bool public revealedLoup = false;

    bool public revealedOurs = false;

    //Is the contract paused ?
    bool public paused = false;
    address public  tokenAddress;
    //The different stages of selling the collection
    enum Steps {
        Before,
        SaleRaton,
        SaleCarcajou,
        SaleRenard,
        SaleLoup,
        SaleOurs,
        SoldOut,
        Reveal
    }

    Steps public sellingStep;

  //Log of bought nfts
  event CommissionWithdraw(address indexed buyer, uint256 indexed amount);

  struct SaleLog {
    uint256 unitPrice;
    uint256 qty;
    uint256 startTokenId;
    uint256 lastWithdraw;
  }

  mapping(address => SaleLog[]) saleLogs;
    
    //Owner of the smart contract
    address private _owner;
    uint256 private _currentIndex;

    //Keep a track of the number of tokens per address
    mapping(address => uint) nftsPerWallet;

    uint private teamLength;

    //Addresses of all the members of the team
    address[] private _team = [
        0x45520e8A18deE37d34BacF78Ab98E1a123b484DC,
        0xA709E24E41861fE3Ea034bFd0142cf17caa2Fd28,
        0x7EEAaD9C49c5422Ea6B65665146187A66F22c48E,
        0x08db6be654bA391e80e80358112EDE75717dcfAb,
        0x2005B0314DD86741bbc436e0448f2be42e2f4c69
    ];

    //Shares of all the members of the team
    uint[] private _teamShares = [
        70, 
        26,
        2,
        1,
        1
    ];

    //Constructor of the collection
    constructor(string memory _theBaseURIRaton, string memory _notRevealedURIRaton, address _tokenAddress) ERC721A("Rpcp", "RPCP") PaymentSplitter(_team, _teamShares) {
        transferOwnership(msg.sender);
        sellingStep = Steps.Before;
        baseURIRaton = _theBaseURIRaton;
        notRevealedURIRaton = _notRevealedURIRaton;
        teamLength = _team.length;
        tokenAddress = _tokenAddress;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /** 
    * @notice Change the number of NFTs that an address can mint
    *
    * @param _maxMintAllowed The number of NFTs that an address can mint
    **/
    function changeMaxMintAllowed(uint _maxMintAllowed) external onlyOwner {
        max_mint_allowed = _maxMintAllowed;
    }

    function setBaseUriRaton(string memory _newBaseURIRaton) external onlyOwner {
        baseURIRaton = _newBaseURIRaton;
    }

    function setBaseUriCarcajou(string memory _newBaseURICarcajou) external onlyOwner {
        baseURICarcajou = _newBaseURICarcajou;
    }

    function setBaseUriRenard(string memory _newBaseURIRenard) external onlyOwner {
        baseURIRenard = _newBaseURIRenard;
    }

	 function setBaseUriRenard(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }
	

    function setBaseUriLoup(string memory _newBaseURILoup) external onlyOwner {
        baseURILoup = _newBaseURILoup;
    }

    function setBaseUriOurs(string memory _newBaseURIOurs) external onlyOwner {
        baseURIOurs = _newBaseURIOurs;
    }

    function setNotRevealURIRaton(string memory _notRevealedURIRaton) external onlyOwner {
        notRevealedURIRaton = _notRevealedURIRaton;
    }

    function setNotRevealURICarcajou(string memory _notRevealedURICarcajou) external onlyOwner {
        notRevealedURICarcajou = _notRevealedURICarcajou;
    }

    function setNotRevealURIRenard(string memory _notRevealedURIRenard) external onlyOwner {
        notRevealedURIRenard = _notRevealedURIRenard;
    }

    function setNotRevealURILoup(string memory _notRevealedURILoup) external onlyOwner {
        notRevealedURILoup = _notRevealedURILoup;
    }

    function setNotRevealURIOurs(string memory _notRevealedURIOurs) external onlyOwner {
        notRevealedURIOurs = _notRevealedURIOurs;
    }

    function revealRaton() external onlyOwner{
        revealedRaton = true;
    }

    function revealCarcajou() external onlyOwner{
        revealedCarcajou = true;
    }

    function revealRenard() external onlyOwner{
        revealedRenard = true;
    }

    function revealLoup() external onlyOwner{
        revealedLoup = true;
    }

    function revealOurs() external onlyOwner{
        revealedOurs = true;
    }

    /**
    * @notice Return URI of the NFTs when revealed
    *
    * @return The URI of the NFTs when revealed
    **/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIRaton;
    }

    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    function setUpSaleRaton() external onlyOwner {
        sellingStep = Steps.SaleRaton;
    }

    function setUpSaleCarcajou() external onlyOwner {
        require(sellingStep == Steps.SaleRaton, "First the SaleRaton, then the saleCarcajou.");
        sellingStep = Steps.SaleCarcajou;
    }

    function setUpSaleRenard() external onlyOwner {
        require(sellingStep == Steps.SaleCarcajou, "First the SaleCarcajou, then the saleRenard.");
        sellingStep = Steps.SaleRenard;
    }

    function setUpSaleLoup() external onlyOwner {
        require(sellingStep == Steps.SaleRenard, "First the SaleRenard, then the saleLoup.");
        sellingStep = Steps.SaleLoup;
    }

    function setUpSaleOurs() external onlyOwner {
        require(sellingStep == Steps.SaleLoup, "First the SaleLoup, then the saleOurs.");
        sellingStep = Steps.SaleOurs;
    }

    function addSaleLog(
        address _buyer,
        uint256 price,
        uint256 qty
    ) internal {
        saleLogs[_buyer].push(SaleLog(price, qty, _currentIndex - qty + 1, block.timestamp));
    }

    function getBillableCommissionCycle(uint256 lastWithdraw, uint256 currentTime)
        internal
        pure
        returns (uint256)
    {
        uint256 duration = currentTime - lastWithdraw;
        return duration / COMMISSION_CYCLE;
    }

    function calculateCommission(address _buyer, uint256 currentTime)
        internal
        view
        returns (uint256)
    {
        uint256 amount = 0;

        for (uint256 i = 0; i < saleLogs[_buyer].length; i++) {
        SaleLog memory saleLog = saleLogs[_buyer][i];
        uint256 billableCycle = getBillableCommissionCycle(
            saleLog.lastWithdraw,
            currentTime
        );
        uint256 billableAmount = (billableCycle *
            saleLog.unitPrice * saleLog.qty *
            COMMISSION_RATE) / 100;
        amount += billableAmount;
        }

        return amount;
    }

    function afterWithdrawCommission(address _buyer, uint256 currentTime)
        internal
    {
        for (uint256 i = 0; i < saleLogs[_buyer].length; i++) {
        uint256 billableCycle = getBillableCommissionCycle(
            saleLogs[_buyer][i].lastWithdraw,
            currentTime
        );
        uint256 billableDuration = billableCycle * COMMISSION_CYCLE;
        saleLogs[_buyer][i].lastWithdraw += billableDuration;
        }
    }

    function withdrawCommission() external nonReentrant {
        address buyer =  msg.sender;
        uint256 currentTime = block.timestamp;

        require(saleLogs[buyer].length > 0, "You haven't bought any items");
        uint256 amount = calculateCommission(buyer, currentTime);
        require(amount > 0, "There is nothing to withdraw");
        require(address(this).balance >= amount, "Contract's balance is not enough");
		require(IERC20(tokenAddress).transferFrom(address(this),buyer,amount),"Not enought funds.");
      //  (bool sucess, ) = payable(buyer).call{value: amount}("");
      //  require(sucess, "Failed to withdraw");

        afterWithdrawCommission(buyer, currentTime);
        emit CommissionWithdraw(buyer, amount);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function deposit(uint amount) public  onlyOwner {
       // require(msg.value > 0, "No funds");
     require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),amount),"Not enought funds.");

    }
    function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {
      if (saleLogs[from].length > 0) {
          for (uint256 i = 0; i < saleLogs[from].length; i++) {
            SaleLog memory log = saleLogs[from][i];
            bool isInTokenRange = log.startTokenId <= startTokenId && log.startTokenId + log.qty >= startTokenId + quantity && quantity <= log.qty;

            if (isInTokenRange) {
                // Any token transfer will break the current sale log to 2 new sale logs
                uint256 headLogQty =  startTokenId - log.startTokenId;
                uint256 tailLogQty = log.qty - quantity - headLogQty;
                delete saleLogs[from][i];

                if (headLogQty > 0) {
                    saleLogs[from].push(SaleLog(log.unitPrice, headLogQty, log.startTokenId, log.lastWithdraw));
                }

                if (tailLogQty > 0) {
                    saleLogs[from].push(SaleLog(log.unitPrice, tailLogQty, startTokenId + quantity, log.lastWithdraw));
                }             

                // Add new sale log for buyer
                saleLogs[to].push(SaleLog(log.unitPrice, quantity, startTokenId, log.lastWithdraw));
            }
        }
      }
    }


  
		 
    function saleRaton(address _account, uint256 _quantity) external  nonReentrant {
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //Get the price of one NFT in Sale
        uint price = priceRaton;
        //If everything has been bought
        require(sellingStep != Steps.SaleCarcajou, "Sorry, no NFTs left.");
        //If Sale didn't start yet
        require(sellingStep == Steps.SaleRaton, "Sorry, saleRaton has not started yet.");
        //Did the user then enought Ethers to buy _quantity NFTs ?
       // require(msg.value >= price * _quantity, "Not enought funds.");
        require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity),"Not enought funds.");
        //The user can only mint max 5 NFTs
        require(nftsPerWallet[_account] + _quantity <= max_mint_allowed, "You can't mint more than the limit");
        //If the user try to mint any non-existent token
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_RATON, "SaleRaton is almost done and we don't have enought NFTs left.");
        //Add the _quantity of NFTs minted by the user to the total he minted
        nftsPerWallet[msg.sender] += _quantity;
        //If this account minted the last NFTs available
        if(numberNftSold + _quantity == LIMIT_SUPPLY_RATON) {
            sellingStep = Steps.SaleCarcajou;   
        }
        // _safeMint's second argument now takes in a _quantity, not a tokenId.
        _safeMint(msg.sender, _quantity);
        addSaleLog(msg.sender, price, _quantity);
    }

    function saleCarcajou(address _account, uint256 _quantity) external  nonReentrant {
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //Get the price of one NFT in Sale
        uint price = priceCarcajou;
        //If everything has been bought
        require(sellingStep != Steps.SaleRenard, "Sorry, no NFTs left.");
        //If Sale didn't start yet
        require(sellingStep == Steps.SaleCarcajou, "Sorry, saleCarcajou has not started yet.");
        //Did the user then enought Ethers to buy _quantity NFTs ?
        // require(msg.value >= price * _quantity, "Not enought funds.");
                require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity),"Not enought funds.");

        //The user can only mint max 5 NFTs
        require(nftsPerWallet[_account] + _quantity <= max_mint_allowed, "You can't mint more than the limit");
        //If the user try to mint any non-existent token
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_CARCAJOU, "SaleCarcajou is almost done and we don't have enought NFTs left.");
        //Add the _quantity of NFTs minted by the user to the total he minted
        nftsPerWallet[msg.sender] += _quantity;
        //If this account minted the last NFTs available
        if(numberNftSold + _quantity == LIMIT_SUPPLY_CARCAJOU) {
            sellingStep = Steps.SaleRenard;   
        }
        // _safeMint's second argument now takes in a _quantity, not a tokenId.
        _safeMint(msg.sender, _quantity);
        addSaleLog(msg.sender, price, _quantity);
    }

    function saleRenard(address _account, uint256 _quantity) external  nonReentrant {
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //Get the price of one NFT in Sale
        uint price = priceRenard;
        //If everything has been bought
        require(sellingStep != Steps.SaleLoup, "Sorry, no NFTs left.");
        //If Sale didn't start yet
        require(sellingStep == Steps.SaleRenard, "Sorry, saleRenard has not started yet.");
        //Did the user then enought Ethers to buy _quantity NFTs ?
        // require(msg.value >= price * _quantity, "Not enought funds.");
                require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity),"Not enought funds.");

        //The user can only mint max 5 NFTs
        require(nftsPerWallet[_account] + _quantity <= max_mint_allowed, "You can't mint more than the limit");
        //If the user try to mint any non-existent token
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_RENARD, "SaleRenard is almost done and we don't have enought NFTs left.");
        //Add the _quantity of NFTs minted by the user to the total he minted
        nftsPerWallet[msg.sender] += _quantity;
        //If this account minted the last NFTs available
        if(numberNftSold + _quantity == LIMIT_SUPPLY_RENARD) {
            sellingStep = Steps.SaleLoup;   
        }
        // _safeMint's second argument now takes in a _quantity, not a tokenId.
        _safeMint(msg.sender, _quantity);
        addSaleLog(msg.sender, price, _quantity);
    }

    function saleLoup(address _account, uint256 _quantity) external  nonReentrant {
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //Get the price of one NFT in Sale
        uint price = priceLoup;
        //If everything has been bought
        require(sellingStep != Steps.SaleOurs, "Sorry, no NFTs left.");
        //If Sale didn't start yet
        require(sellingStep == Steps.SaleLoup, "Sorry, saleLoup has not started yet.");
        //Did the user then enought Ethers to buy _quantity NFTs ?
        // require(msg.value >= price * _quantity, "Not enought funds.");
                require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity),"Not enought funds.");

        //The user can only mint max 5 NFTs
        require(nftsPerWallet[_account] + _quantity <= max_mint_allowed, "You can't mint more than the limit");
        //If the user try to mint any non-existent token
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_LOUP, "SaleLoup is almost done and we don't have enought NFTs left.");
        //Add the _quantity of NFTs minted by the user to the total he minted
        nftsPerWallet[msg.sender] += _quantity;
        //If this account minted the last NFTs available
        if(numberNftSold + _quantity == LIMIT_SUPPLY_LOUP) {
            sellingStep = Steps.SaleOurs;   
        }
        // _safeMint's second argument now takes in a _quantity, not a tokenId.
        _safeMint(msg.sender, _quantity);
        addSaleLog(msg.sender, price, _quantity);
    }

    function saleOurs(address _account, uint256 _quantity) external  nonReentrant {
        //Get the number of NFT sold
        uint numberNftSold = totalSupply();
        //Get the price of one NFT in Sale
        uint price = priceOurs;
        //If everything has been bought
        require(sellingStep != Steps.SoldOut, "Sorry, no NFTs left.");
        //If Sale didn't start yet
        require(sellingStep == Steps.SaleOurs, "Sorry, saleOurs has not started yet.");
        //Did the user then enought Ethers to buy _quantity NFTs ?
        // require(msg.value >= price * _quantity, "Not enought funds.");
                require(IERC20(tokenAddress).transferFrom(msg.sender,address(this),price * _quantity),"Not enought funds.");

        //The user can only mint max 5 NFTs
        require(nftsPerWallet[_account] + _quantity <= max_mint_allowed, "You can't mint more than the limit");
        //If the user try to mint any non-existent token
        require(numberNftSold + _quantity <= LIMIT_SUPPLY_OURS, "SaleOurs is almost done and we don't have enought NFTs left.");
        //Add the _quantity of NFTs minted by the user to the total he minted
        nftsPerWallet[msg.sender] += _quantity;
        //If this account minted the last NFTs available
        if(numberNftSold + _quantity == LIMIT_SUPPLY_OURS) {
            sellingStep = Steps.SoldOut;   
        }
        // _safeMint's second argument now takes in a _quantity, not a tokenId.
        _safeMint(msg.sender, _quantity);
        addSaleLog(msg.sender, price, _quantity);
    }

    /**
    * @notice Allows to get the complete URI of a specific NFT by his ID
    *
    * @param _nftId The id of the NFT
    *
    * @return The token URI of the NFT which has _nftId Id
    **/
    function tokenURI(uint _nftId) public view override(ERC721A) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");

        if(revealedRaton == false) {
            return notRevealedURIRaton;
        }
        if(revealedCarcajou == false) {
            return notRevealedURICarcajou;
        }
        if(revealedRenard == false) {
            return notRevealedURIRenard;
        }
        if(revealedLoup == false) {
            return notRevealedURILoup;
        }
        if(revealedOurs == false) {
            return notRevealedURIOurs;
        }
    

    string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
            : "";
    }    

    //ReleaseALL
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    // deployed address on rinkeby  0xf8e83cdabeae54d1EdB36880dF6e7E75fC9C26AB
    // deployed token on rinkeby   0x084453eA6653647Efa09235B2D8866a7B3638560
}