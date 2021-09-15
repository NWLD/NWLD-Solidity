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
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
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

//该池子用于币价兜底，卖出价格为初始定价的0.8倍，买入价格1.5倍，初始定价1U：100万币
contract TokenPool is Role {
    using Address for address;
    uint256 decimal = 10 ** 18;
    uint256 public sellPrice;//卖币给池子的价格
    uint256 public buyPrice;//从池子买币的价格

    string private gameToken = 'gameToken';

    constructor() {
    }

    function buy() payable external {
        require(!msg.sender.isContract(), "contract not allow");
        require(msg.sender.balance >= msg.value, "balance not enough");
        IToken token = IToken(config.labelAddress(gameToken));
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "pool token empty");
        uint256 buyAmount = msg.value * decimal / buyPrice;
        //池子的币数量不够，即付的钱买光池子还有多余，避免用户损失，不让交易成功
        require(buyAmount <= tokenBalance, "pool token not enough");
        //给购买者代币
        token.transfer(msg.sender, buyAmount);
    }

    function sell(uint256 amount) external {
        require(!msg.sender.isContract(), "contract not allow");
        require(address(this).balance > 0, "pool balance empty");
        IToken token = IToken(config.labelAddress(gameToken));
        uint256 tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance >= amount, "token not enough");
        //计算卖出金额
        uint256 sellEthAmount = amount * sellPrice / decimal;
        //池子的金额不够，即卖的币掏空池子还有多余，避免用户损失，不让交易成功
        require(sellEthAmount <= address(this).balance, "pool balance not enough");
        token.transferFrom(msg.sender, address(this), amount);
        //给售卖者金额
        address payable senderAddr = payable(msg.sender);
        senderAddr.transfer(sellEthAmount);
    }

    function setPrice(uint256 price) onlyOwner public {
        //只允许设置一次
        require(0 == sellPrice, 'had set');
        //卖出价格8折
        sellPrice = price * 8 / 10;
        //买入价格1.5倍
        buyPrice = price * 15 / 10;
    }

    function info() view external returns (uint256, uint256, uint256, uint256){
        IToken token = IToken(config.labelAddress(gameToken));
        uint256 tokenBalance = token.balanceOf(address(this));
        return (tokenBalance, address(this).balance, sellPrice, buyPrice);
    }

    receive() external payable {}
}