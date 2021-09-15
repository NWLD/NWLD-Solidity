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
        require(c >= a, "add error");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul error");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

interface IConfig {
    function labelAddress(string memory label) view external returns (address);

    function hasPermit(address user, string memory permit) view external returns (bool);
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

interface Token {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface Card {
    function mint(address to, uint256 custom) external returns (uint256);

    function batchMint(address to, uint256 num) external returns (uint256[] memory);
}

interface IData {
    function addLabelAddressData(string memory label, address _address, uint256 value) external;
}

contract PetShop is Role {
    using Address for address;
    using UInteger for uint256;

    string private title = "\u521b\u4e16\u793c\u5305";//商店标题
    string  private des = "\u7a00\u6709\u54c1\u8d28\u6700\u9ad8\u7206\u7387\u002c\u0020\u673a\u4f1a\u4ec5\u6b64\u4e00\u6b21, UR 2%, SSR 8%, SR 20%, R 70%";//商店描述
    uint256 private startTime;//开始时间
    uint256 private qty = 2000;//库存
    uint256 private soldCount = 0;//已售卖数量
    uint256 private price = 1000000 * 10 ** 18;//售价，初始100万

    string private gameToken = 'gameToken';
    string private petNFT = 'petNFT';
    string private statistics = 'statistics';

    address private dead = address(0x000000000000000000000000000000000000dEaD);

    uint256[] private cardIdList;

    uint256 public allSoldCount = 0;

    constructor(){
        startTime = block.timestamp + 3600 * 100;
    }

    function buy(uint256 num) external {
        require(block.timestamp >= startTime, "not start");
        //不允许合约购买
        require(!msg.sender.isContract(), "contract not allowed");
        soldCount += num;
        require(soldCount <= qty, "qty exceed");
        Token token = Token(config.labelAddress(gameToken));
        uint256 balanceBefore = token.balanceOf(msg.sender);
        //代币转入黑洞
        token.transferFrom(msg.sender, dead, price.mul(num));
        //验证是否攻击购买，花费同样的代币购买多次
        require(balanceBefore == price.mul(num).add(token.balanceOf(msg.sender)), "balance exception");
        allSoldCount += num;
        uint256[] memory cardIds = Card(config.labelAddress(petNFT)).batchMint(msg.sender, num);
        for (uint256 index = 0; index < num; index++) {
            cardIdList.push(cardIds[index]);
        }
        IData data = IData(config.labelAddress(statistics));
        data.addLabelAddressData("buyPetCost", msg.sender, price.mul(num));
    }

    function newShop(string memory _title, string memory _des, uint256 _startTime, uint256 priceRate, uint256 max) external onlyOwner {
        uint256 priceAdd = price.mul(priceRate).div(10000);
        price = price.add(priceAdd);
        startTime = _startTime;
        title = _title;
        des = _des;
        qty = max;
        soldCount = 0;
    }

    function shopInfo() external view returns (uint256, string memory, string memory, uint256, uint256, uint256, uint256) {
        return (block.timestamp, title, des, startTime, price, qty, soldCount);
    }

    function getCardIds() external view returns (uint256[] memory) {
        return cardIdList;
    }
}
