// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract PaperMastersNFI is ERC721, Ownable {
    event identityFeeChanged(uint256 identityFee);
    event Log(uint256 gasLeftLeft);
    event DonationMade(uint256 amount, uint256 balance, address donationSender, uint256 totalDonationsBySender);
    event Withdraw(uint256 amount, uint256 balance, address withdrawAddress);
    event Pause();
    event Unpause();
    event NFIMinted(uint256 chainId, address indexed _from, uint256 tokenId, uint256 timeStamp, uint256 contractFee, identity identityStruct);

    struct identity
    {
        uint256 chainId;
        address walletAccount;
        string name;
        string email;
        string profession;
        string organization;
        string slogan;
        string website;
        string uniqueYou;
        string bgRGB;
        uint256 originDate;
    }

    identity[] _dictionaryNFIs;
    string private _setBaseURI;
    uint256 private identityFee;
    mapping(address => uint256) totalIdentities;
    mapping(address => uint256) _supportPMDonations;

    bool internal locked;
    bool public paused = false;
    
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }
    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Message sender must be the contract's owner.");
    //     _;
    // }
    constructor() ERC721("papermasters.io", "NFI") {
        _setBaseURI = "www.papermasters.io/identity";
        identityFee = 100000000000000000;
        _dictionaryNFIs.push(identity({
            chainId: block.chainid,
            walletAccount: address(this),
            name: "",
            email: "",
            profession: "",
            organization: "",
            slogan: "",
            website: "",
            uniqueYou: "",
            bgRGB: "",
            originDate: block.timestamp
        }));
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    function addressToTokenID(address walletAddress) public view returns (uint256) {
        return totalIdentities[walletAddress];
    }

    function tokenIDtoIdentityStruct(uint256 _tokenid) public view returns (identity memory) {
        return _dictionaryNFIs[_tokenid];
    }

    function addressHasTokenBool(address walletAddress) public view returns (bool) {
        uint256 _tokenId = addressToTokenID(walletAddress);
        return _tokenId >= 1;
    }

    function addressToIdentityStruct(address walletAddress) public view returns (identity memory){
        uint256 tokenId = addressToTokenID(walletAddress);
        return _dictionaryNFIs[tokenId];
    }

    function allIdentityStructs() public view returns (identity[] memory){
        return _dictionaryNFIs;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        //require(tokenIDtoIdentityStruct(tokenId), "ERC721Metadata: URI query for nonexistent token");
        //address owner = ownerOf(tokenId);
        require(tokenId + 1  <= _dictionaryNFIs.length, "Invalid Token ID");
        identity memory ident = _dictionaryNFIs[tokenId];
        uint256 chainid = block.chainid;
        string memory baseURI = _baseURI();
        return string(bytes.concat(
                bytes(baseURI),
                "/",
                bytes(Strings.toString(chainid)),
                "/",
                bytes(Strings.toHexString(uint160(ident.walletAccount), 20))
            ));
    }

    function setBaseURI(string memory changeBaseURI) public onlyOwner {
        _setBaseURI = changeBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _setBaseURI;
    }

    function getIdentityFee() public view returns (uint256) {
        return identityFee;
    }

    function setIdentityFee(uint256 val) external onlyOwner {
        identityFee = val;
        emit identityFeeChanged(val);
    }

    fallback() external payable {
        emit Log(gasleft());
    }

    receive() external payable {}

    function deposit() public payable {
        uint256 amount = msg.value;
        _supportPMDonations[msg.sender] += msg.value;
        emit DonationMade(amount, address(this).balance, msg.sender, _supportPMDonations[msg.sender]);
    }

    function getBalance() public view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function withdraw() external noReentrant onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = msg.sender.call{value : amount}("");
        require(success, "Transfer failed.");
        emit Withdraw(amount, address(this).balance, msg.sender);
    }

    function totalSupply() public view returns (uint256) {
        return _dictionaryNFIs.length;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }

    function mintNFI(
        string memory _name,
        string memory _email,
        string memory _profession,
        string memory _organization,
        string memory _slogan,
        string memory _website,
        string memory _uniqueYou,
        string memory _bgRGB
    ) public virtual noReentrant payable whenNotPaused
    {
        require(msg.value >= identityFee, "Not enough ETH sent; check price!");
        require(msg.sender.balance >= identityFee, "Account does not have sufficient funds");
        require(!addressHasTokenBool(msg.sender), " Wallet already has an NFI! You get one per wallet account");

        identity memory _identity = identity({
            chainId : block.chainid,
            walletAccount : msg.sender,
            name : _name,
            email : _email,
            profession : _profession,
            organization : _organization,
            slogan : _slogan,
            website : _website,
            uniqueYou : _uniqueYou,
            bgRGB : _bgRGB,
            originDate : block.timestamp
        });

        _dictionaryNFIs.push(_identity);
        uint256 newTokenID = _dictionaryNFIs.length - 1;
        totalIdentities[msg.sender] = newTokenID;
        _safeMint(msg.sender, newTokenID);

        emit NFIMinted(block.chainid, msg.sender, newTokenID, block.timestamp, msg.value, _identity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override onlyOwner {}

    function isApprovedForAll(address owner, address operator) public view virtual override onlyOwner returns (bool) {}

    function transferFrom(address from, address to, uint256 tokenId) public virtual override onlyOwner {}

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override onlyOwner {}

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override onlyOwner {}

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual override onlyOwner {}
}
