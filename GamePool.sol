// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
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

contract GamePool is Role {
    string private gameToken = 'gameToken';

    function giveGameToken(address addr, uint256 amount) external CheckPermit("game") {
        IToken token = IToken(config.labelAddress(gameToken));
        token.transfer(addr, amount);
    }

    function giveBalance(address addr, uint256 amount) external CheckPermit("game") {
        address payable payableAddr = payable(addr);
        payableAddr.transfer(amount);
    }

    receive() external payable {}
}