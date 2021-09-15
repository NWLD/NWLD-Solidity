// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

contract Statistics is Role {
    //某个维度统计地址对应数据，例如 buyHero a 10000 ==== 购买英雄消费统计，a地址花费了10000
    mapping(string => mapping(address => uint256)) public labelAddressData;
    //某个维度统计的地址列表，参与过该统计的地址都记录，需要利用labelAddressIndex去重
    mapping(string => address[]) private labelAddressList;
    //某个维度统计的地址在列表中的索引/序号
    mapping(string => mapping(address => uint256)) private labelAddressIndex;

    //某个维度统计NFT对应数据，例如 daily-game-count b 10 ==== 每日游戏次数统计，b-NFT玩了10次
    mapping(string => mapping(uint256 => uint256)) public labelTokenData;
    mapping(string => uint256[]) private labelTokenList;
    mapping(string => mapping(uint256 => uint256)) private labelTokenIndex;

    function addLabelAddressData(string memory label, address _address, uint256 value) external CheckPermit("statistics") {
        labelAddressData[label][_address] += value;
        //因为solidity默认值为0，需要再次判断0位置是不是该地址
        if (0 == labelAddressIndex[label][_address]) {
            //数组长度为0，0位置不是该地址，是新插入地址
            if (0 == labelAddressList[label].length || _address != labelAddressList[label][0]) {
                labelAddressIndex[label][_address] = labelAddressList[label].length;
                labelAddressList[label].push(_address);
            }
        }
    }

    function minusLabelAddressData(string memory label, address _address, uint256 value) external CheckPermit("statistics") {
        require(labelAddressData[label][_address] >= value, 'exceed value');
        labelAddressData[label][_address] -= value;
    }

    function addLabelTokenData(string memory label, uint256 tokenId, uint256 value) external CheckPermit("statistics") {
        labelTokenData[label][tokenId] += value;
        //因为solidity默认值为0，需要再次判断0位置是不是该Token
        if (0 == labelTokenIndex[label][tokenId]) {
            //数组长度为0，0位置不是该Token，是新插入Token
            if (0 == labelTokenList[label].length || tokenId != labelTokenList[label][0]) {
                labelTokenIndex[label][tokenId] = labelTokenList[label].length;
                labelTokenList[label].push(tokenId);
            }
        }
    }

    function minusLabelTokenData(string memory label, uint256 tokenId, uint256 value) external CheckPermit("statistics") {
        require(labelTokenData[label][tokenId] >= value, 'exceed value');
        labelTokenData[label][tokenId] -= value;
    }

    function getLabelAddressDataList(string memory label) view external returns (address[] memory, uint256[] memory){
        address[] storage addressList = labelAddressList[label];
        uint256 length = addressList.length;
        if (0 == length) {
            return (new address[](0), new uint256[](0));
        }
        uint256[] memory valueResult = new uint256[](length);
        for (uint256 index = 0; index < length; ++index) {
            valueResult[index] = labelAddressData[label][addressList[index]];
        }
        return (addressList, valueResult);
    }

    function getLabelTokenDataList(string memory label) view external returns (uint256[] memory, uint256[] memory){
        uint256[] storage tokenList = labelTokenList[label];
        uint256 length = tokenList.length;
        if (0 == length) {
            return (new uint256[](0), new uint256[](0));
        }
        uint256[] memory valueResult = new uint256[](length);
        for (uint256 index = 0; index < length; ++index) {
            valueResult[index] = labelTokenData[label][tokenList[index]];
        }
        return (tokenList, valueResult);
    }
}