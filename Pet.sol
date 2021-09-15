// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

library UInteger {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add err");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul err");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

library String {
    function concat(string memory a, string memory b)
    internal pure returns (string memory) {

        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bc = new bytes(ba.length + bb.length);

        uint256 bal = ba.length;
        uint256 bbl = bb.length;
        uint256 k = 0;

        for (uint256 i = 0; i != bal; ++i) {
            bc[k++] = ba[i];
        }
        for (uint256 i = 0; i != bbl; ++i) {
            bc[k++] = bb[i];
        }

        return string(bc);
    }
}


library Util {
    bytes4 internal constant ERC721_RECEIVER_RETURN = 0x150b7a02;
    bytes4 internal constant ERC721_RECEIVER_EX_RETURN = 0x0f7b88e3;

    bytes public constant BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function randomUint(bytes memory seed, uint256 min, uint256 max)
    internal pure returns (uint256) {

        if (min >= max) {
            return min;
        }

        uint256 number = uint256(keccak256(seed));
        return number % (max - min + 1) + min;
    }

    function base64Encode(bytes memory bs) internal pure returns (string memory) {
        uint256 remain = bs.length % 3;
        uint256 length = bs.length / 3 * 4;
        bytes memory result = new bytes(length + (remain != 0 ? 4 : 0) + (3 - remain) % 3);

        uint256 i = 0;
        uint256 j = 0;
        while (i != length) {
            result[i++] = Util.BASE64_CHARS[uint8(bs[j] >> 2)];
            result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4 | bs[j + 1] >> 4)];
            result[i++] = Util.BASE64_CHARS[uint8((bs[j + 1] & 0x0f) << 2 | bs[j + 2] >> 6)];
            result[i++] = Util.BASE64_CHARS[uint8(bs[j + 2] & 0x3f)];

            j += 3;
        }

        if (remain != 0) {
            result[i++] = Util.BASE64_CHARS[uint8(bs[j] >> 2)];

            if (remain == 2) {
                result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4 | bs[j + 1] >> 4)];
                result[i++] = Util.BASE64_CHARS[uint8((bs[j + 1] & 0x0f) << 2)];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = 0x3d;
            } else {
                result[i++] = Util.BASE64_CHARS[uint8((bs[j] & 0x03) << 4)];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = Util.BASE64_CHARS[0];
                result[i++] = 0x3d;
                result[i++] = 0x3d;
            }
        }

        return string(result);
    }
}

abstract contract Owner {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4);
}

abstract contract ERC721 is IERC165, IERC721, IERC721Metadata {
    using Address for address;

    /*
     * bytes4(keccak256("supportsInterface(bytes4)")) == 0x01ffc9a7
     */
    bytes4 private constant INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /*
     *     bytes4(keccak256("balanceOf(address)")) == 0x70a08231
     *     bytes4(keccak256("ownerOf(uint256)")) == 0x6352211e
     *     bytes4(keccak256("approve(address,uint256)")) == 0x095ea7b3
     *     bytes4(keccak256("getApproved(uint256)")) == 0x081812fc
     *     bytes4(keccak256("setApprovalForAll(address,bool)")) == 0xa22cb465
     *     bytes4(keccak256("isApprovedForAll(address,address)")) == 0xe985e9c5
     *     bytes4(keccak256("transferFrom(address,address,uint256)")) == 0x23b872dd
     *     bytes4(keccak256("safeTransferFrom(address,address,uint256)")) == 0x42842e0e
     *     bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes4 private constant INTERFACE_ID_ERC721Metadata = 0x5b5e139f;

    string public override name;
    string public override symbol;

    mapping(address => uint256[]) internal ownerTokens;
    mapping(uint256 => uint256) internal tokenIndexs;
    mapping(uint256 => address) internal tokenOwners;

    mapping(uint256 => address) internal tokenApprovals;
    mapping(address => mapping(address => bool)) internal approvalForAlls;

    mapping(address => uint256) private holderIndexes;//持有过卡牌的人在持有人列表中的序号
    address[] private holders;//持有过卡牌的人，方便以后统计用

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        holders.push(address(0x000000000000000000000000000000000000dEaD));
        holderIndexes[address(0x000000000000000000000000000000000000dEaD)] = 0;
    }

    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "no owner");
        return ownerTokens[owner].length;
    }

    function tokensOf(address owner) external view returns (uint256[] memory) {
        require(owner != address(0), "no owner");
        return ownerTokens[owner];
    }

    function getHolders() external view returns (address[] memory) {
        return holders;
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = tokenOwners[tokenId];
        require(owner != address(0), "no owner");
        return owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        _transferFrom(from, to, tokenId);
        if (to.isContract()) {
            require(IERC721TokenReceiver(to)
            .onERC721Received(msg.sender, from, tokenId, data)
                == Util.ERC721_RECEIVER_RETURN,
                "onReceived");
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) external payable override {
        _transferFrom(from, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(from != address(0), "from 0");
        require(to != address(0), "to 0");
        require(from == tokenOwners[tokenId], "from own");
        require(msg.sender == from
        || msg.sender == tokenApprovals[tokenId]
            || approvalForAlls[from][msg.sender],
            "must own or approvaled");
        if (tokenApprovals[tokenId] != address(0)) {
            delete tokenApprovals[tokenId];
        }
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    // ensure everything is ok before call it
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        uint256 index = tokenIndexs[tokenId];
        uint256[] storage tokens = ownerTokens[from];
        uint256 indexLast = tokens.length - 1;
        // save gas
        // if (index != indexLast) {
        uint256 tokenIdLast = tokens[indexLast];
        tokens[index] = tokenIdLast;
        tokenIndexs[tokenIdLast] = index;
        // }
        tokens.pop();
        // delete tokenIndexs[tokenId]; // save gas
        delete tokenOwners[tokenId];
    }

    // ensure everything is ok before call it
    function _addTokenTo(address to, uint256 tokenId) internal {
        uint256[] storage tokens = ownerTokens[to];
        tokenIndexs[tokenId] = tokens.length;
        tokens.push(tokenId);
        tokenOwners[tokenId] = to;
        //添加持有人
        if (0 == holderIndexes[to]) {
            holderIndexes[to] = holders.length;
            holders.push(to);
        }
    }

    function approve(address to, uint256 tokenId)
    external payable override {

        address owner = tokenOwners[tokenId];

        require(msg.sender == owner
            || approvalForAlls[owner][msg.sender],
            "must own or approved"
        );

        tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) external override {
        approvalForAlls[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function getApproved(uint256 tokenId)
    external view override returns (address) {

        require(tokenOwners[tokenId] != address(0),
            "no owner");

        return tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator)
    external view override returns (bool) {

        return approvalForAlls[owner][operator];
    }

    function supportsInterface(bytes4 interfaceID)
    external pure override returns (bool) {

        return interfaceID == INTERFACE_ID_ERC165
        || interfaceID == INTERFACE_ID_ERC721
        || interfaceID == INTERFACE_ID_ERC721Metadata;
    }
}

abstract contract ERC721Ex is ERC721, Owner {
    uint256 public constant NFT_SIGN_BIT = 1 << 255;
    uint256 public totalSupply = 0;
    string public uriPrefix = "http://api.dgqxyc.com/";

    function _mint(address to, uint256 tokenId) internal {
        _addTokenTo(to, tokenId);
        ++totalSupply;
        emit Transfer(address(0), to, tokenId);
    }

    function setUriPrefix(string memory prefix) external onlyOwner {
        uriPrefix = prefix;
    }
}

interface IConfig {
    function hasPermit(address user, string memory permit) view external returns (bool);
}

abstract contract Role is Owner {
    IConfig config;

    modifier CheckPermit(string memory permit) {
        require(config.hasPermit(msg.sender, permit),
            "no permit");
        _;
    }

    function setConfig(address addr) external onlyOwner {
        config = IConfig(addr);
    }
}

// nftSign  custom  buffer   label  who    level   rarity    mintTime   index
// 1        120     8        16     16     8       8         40         32
// 255      128     120      104    88     80      72        32         0
contract Pet is ERC721Ex, Role {
    using String for string;
    using UInteger for uint256;

    mapping(uint256 => uint256) public rareRates;//稀有度概率
    mapping(uint256 => uint256) public levelRates;//购买等级概率
    mapping(uint256 => uint256[]) private rareWhoList;//稀有度对应的英雄列表
    uint256 public label = 1;//活动标签，例如创世=1
    uint256 public buffer = 10;//当前活动购买卡牌的战力加成，创世加成10%

    constructor() ERC721('NWLD Pet', 'NWLDPET'){
        //概率1万取余
        //稀有度概率
        // rareRates[6] = 0;
        // rareRates[5] = 200;
        // rareRates[4] = 800;
        // rareRates[3] = 2000;
        // rareRates[2] = 7000;
    }

    /**
    *随机稀有度 //TODO 配置可以修改
    */
    function rareRandom(uint256 random) view private returns (uint256){
        uint256 rareNum = rareRates[6];
        if (rareNum > random) {
            return 6;
        }
        rareNum += rareRates[5];
        if (rareNum > random) {
            return 5;
        }
        rareNum += rareRates[4];
        if (rareNum > random) {
            return 4;
        }
        rareNum += rareRates[3];
        if (rareNum > random) {
            return 3;
        }
        rareNum += rareRates[2];
        if (rareNum > random) {
            return 2;
        }
        return 1;
    }

    function whoRandom(uint256 random, uint256 rare) view private returns (uint256){
        uint256 mod = random % rareWhoList[rare].length;
        return rareWhoList[rare][mod];
    }

    /**
    *随机等级 //TODO 配置可以修改
    */
    function levelRandom(uint256 random) view private returns (uint256){
        uint256 levelNum = levelRates[5];
        if (levelNum > random) {
            return 5;
        }
        levelNum += levelRates[4];
        if (levelNum > random) {
            return 4;
        }
        levelNum += levelRates[3];
        if (levelNum > random) {
            return 3;
        }
        levelNum += levelRates[2];
        if (levelNum > random) {
            return 2;
        }
        return 1;
    }

    // nftSign  custom  buffer   label  who    level   rarity    mintTime   index
    // 1        120     8        16     16     8       8         40         32
    // 255      128     120      104    88     80      72        32         0
    function update(address to, uint256 tokenId, uint256 newWho) external CheckPermit("updatePet") returns (uint256){
        require(to == tokenOwners[tokenId], "not owner");
        uint256 custom = uint120(tokenId >> 128);
        uint256 tokenBuffer = uint8(tokenId >> 120);
        uint256 who = uint16(tokenId >> 88);
        uint256 level = uint8(tokenId >> 80);
        uint256 rarity = uint8(tokenId >> 72);
        uint256 newLabel;
        if (0 == newWho) {
            newLabel = 2;
            level = level + 1;
        } else {
            //切换角色必须在同一稀有度内
            uint256[] storage whoList = rareWhoList[rarity];
            uint256 len = whoList.length;
            bool inRare;
            for (uint256 index = 0; index < len; index++) {
                if (newWho == whoList[index]) {
                    inRare = true;
                    break;
                }
            }
            require(inRare, "not in Rare");
            newLabel = 3;
            who = newWho;
        }
        uint256 cardId = NFT_SIGN_BIT | (custom << 128) | (tokenBuffer << 120) | (newLabel << 104) |
        (who << 88) | (level << 80) | (rarity << 72) |
        (block.timestamp << 32) | uint32(totalSupply + 1);
        _mint(to, cardId);
        return cardId;
    }


    function mint(address to, uint256 custom) external CheckPermit("mintPet") returns (uint256){
        return _randomMint(to, custom, 0);
    }

    // nftSign  custom  buffer   label  who    level   rarity    mintTime   index
    // 1        120     8        16     16     8       8         40         32
    // 255      128     120      104    88     80      72        32         0
    function _randomMint(address to, uint256 custom, uint256 index) private returns (uint256){
        uint256 random = Util.randomUint(abi.encode(block.timestamp, index, totalSupply), 0, 10000);
        uint256 rare = rareRandom(random);
        uint256 level = levelRandom(random);
        uint256 who = whoRandom(random, rare);
        uint256 cardId = NFT_SIGN_BIT | (custom << 128) | (buffer << 120) | (label << 104) |
        (who << 88) | (level << 80) | (rare << 72) |
        (block.timestamp << 32) | uint32(totalSupply + 1);
        _mint(to, cardId);
        return cardId;
    }

    function batchMint(address to, uint256 num) external CheckPermit("mintPet") returns (uint256[] memory){
        uint256[] memory cardIds = new uint256[](num);
        for (uint256 i = 0; i != num; ++i) {
            cardIds[i] = _randomMint(to, 0, i);
        }
        return cardIds;
    }

    function tokenURI(uint256 cardId) external view override returns (string memory) {
        bytes memory bs = abi.encodePacked(cardId);
        string memory id = Util.base64Encode(bs);
        return uriPrefix.concat("card/").concat(id);
    }

    function setLabel(uint256 _label, uint256 _buffer) onlyOwner public {
        label = _label;
        buffer = _buffer;
    }

    function setRareRate(uint256 rare, uint256 rate) onlyOwner public {
        rareRates[rare] = rate;
    }

    function setLevelRate(uint256 level, uint256 rate) onlyOwner public {
        levelRates[level] = rate;
    }

    function setRareWhoList(uint256 rare, uint256[] memory whoList) onlyOwner public {
        delete rareWhoList[rare];
        rareWhoList[rare] = whoList;
    }

    function getRareWhoList(uint256 rare) external view returns (uint256[] memory) {
        return rareWhoList[rare];
    }
}
