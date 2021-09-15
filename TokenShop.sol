// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IConfig {
    function labelAddress(string memory label) view external returns (address);
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

    function setConfig(address addr) external onlyOwner {
        config = IConfig(addr);
    }
}

contract TokenShop is Role {
    using Address for address;

    uint256 private decimal = 10 ** 18;

    mapping(uint256 => uint256) private amountMap;
    mapping(uint256 => uint256) private priceMap;//BNB 410时的价格
    mapping(uint256 => uint256) private qtyMap;
    mapping(uint256 => uint256) private soldMap;
    mapping(uint256 => mapping(address => bool)) private buyMap;

    string private gameToken = 'gameToken';
    string private cashier = 'cashier';
    string private tokenPool = 'tokenPool';
    string private gamePool = 'gamePool';

    constructor() {
        amountMap[1] = 1000000 * decimal;
        priceMap[1] = 0;
        qtyMap[1] = 1000;

        amountMap[2] = 10000000 * decimal;
        qtyMap[2] = 500;

        amountMap[3] = 50000000 * decimal;
        qtyMap[3] = 200;

        amountMap[4] = 100000000 * decimal;
        qtyMap[4] = 100;
    }

    function buy(uint256 index) payable external {
        //设置价格后才开始
        require(priceMap[2] != 0, "not start");
        require(!msg.sender.isContract(), "contract not allow");
        require(msg.sender.balance >= msg.value, "balance not enough");
        require(msg.value == priceMap[index], "price not match");
        require(!buyMap[index][msg.sender], "only 1 time");
        require(qtyMap[index] >= soldMap[index] + 1, 'sold out');
        soldMap[index] += 1;
        buyMap[index][msg.sender] = true;
        IToken token = IToken(config.labelAddress(gameToken));
        token.transfer(msg.sender, amountMap[index]);
    }

    function info(address addr, uint256 index) view external returns (uint256, uint256, uint256, uint256, bool){
        return (amountMap[index], priceMap[index], qtyMap[index], soldMap[index], buyMap[index][addr]);
    }

    function withdrawBalance() onlyOwner public {
        uint256 balance = address(this).balance;
        require(balance > 0, '0 b');
        //40%转入兜底资金池
        uint256 poolAmount = balance * 4 / 10;
        address payable tokenPoolPayable = payable(config.labelAddress(tokenPool));
        tokenPoolPayable.transfer(poolAmount);
        //30%转入游戏池，用于运营活动
        uint256 gameAmount = balance * 3 / 10;
        address payable gamePoolPayable = payable(config.labelAddress(gamePool));
        gamePoolPayable.transfer(gameAmount);
        //剩余部分转入收银地址，用于dex添加流动性
        address payable cashierPayable = payable(config.labelAddress(cashier));
        cashierPayable.transfer(balance - poolAmount - gameAmount);
    }

    function setPrice(uint256 price) onlyOwner public {
        //price 是该主链币1u对应的币值，开启后不能再改价格，只能设置一次价格
        require(priceMap[2] == 0, "had started");
        priceMap[2] = price * 11;
        priceMap[3] = price * 60;
        priceMap[4] = price * 130;
    }
}