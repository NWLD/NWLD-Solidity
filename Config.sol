// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

contract Config is Owner {
    mapping(string => address) private labelAddressMap;//某个标签对应的地址，例如shop=》address，表示商店的合约地址
    mapping(string => uint256) private labelDataMap;//某个标签对应的数据，例如gameDailyMaxCount=每日游戏总次数

    mapping(address => mapping(string => bool)) public userPermits;

    address private admin;//加个admin地址，通过admin合约一次性设置所有配置，不然真是太麻烦了

    constructor(){
        labelAddressMap['cashier'] = address(0xC44F16045D94049284FE4E27ec8D46Ea4bE26560);
        labelDataMap['dailyGameCount'] = 10;
    }

    function labelAddress(string memory label) view external returns (address){
        address addr = labelAddressMap[label];
        require(addr != address(0), 'addr not set');
        return addr;
    }

    function labelData(string memory label) view external returns (uint256){
        return labelDataMap[label];
    }

    function hasPermit(address user, string memory permit) view external returns (bool){
        return userPermits[user][permit];
    }

    function setLabelAddress(string memory label, address addr) external onlyAdmin {
        labelAddressMap[label] = addr;
    }

    function setLabelData(string memory label, uint256 value) external onlyAdmin {
        labelDataMap[label] = value;
    }

    function setUserPermit(address user, string memory permit, bool enable) external onlyAdmin {
        userPermits[user][permit] = enable;
    }

    function labelListAddress(string[] memory labels) view external returns (address[] memory){
        address[] memory addrList = new address[](labels.length);
        for (uint256 index = 0; index < labels.length; index++) {
            address addr = labelAddressMap[labels[index]];
            require(addr != address(0), 'addr not set');
            addrList[index] = addr;
        }
        return addrList;
    }

    function setAdmin(address addr) external onlyOwner {
        require(address(0) != addr);
        admin = addr;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || address(0) != admin && msg.sender == admin);
        _;
    }
}
