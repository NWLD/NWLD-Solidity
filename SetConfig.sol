// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IConfig {
    function setLabelAddress(string memory label, address addr) external;

    function setLabelData(string memory label, uint256 value) external;

    function setUserPermit(address user, string memory permit, bool enable) external;
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

contract SetConfig is Role {
    string private gameToken = 'gameToken'; //游戏代币的合约地址
    string private petNFT = 'petNFT'; //Pet合约地址
    string private petShop = 'petShop'; //Pet购买合约地址
    string private statistics = 'statistics'; //Data统计的合约地址
    string private tokenShop = 'tokenShop'; //代币商店的合约地址
    string private talkingRoom = 'talkingRoom'; //聊天室合约地址
    string private petUpgrade1 = 'petUpgrade1'; //升级1 使用代币概率升级
    string private petUpgrade2 = 'petUpgrade2'; //升级2 使用同种卡牌升级
    string private petSwitchRole = 'petSwitchRole'; //同一稀有度内切换角色
    string private game1 = 'game1';
    string private game2 = 'game2';
    string private game3 = 'game3';
    string private tokenPool = 'tokenPool';
    string private gamePool = 'gamePool';

    address private gameTokenAddress = address(0x3C32FF033214B117a5a559a6FaA60f7199468EC4); //游戏代币的合约地址
    address private petNFTAddress = address(0x6bc4dA19459CABeAa08DE92E155BBf5700DEED8f); //Pet合约地址
    address private petShopAddress = address(0xaA54821aBdf4D96fb8b0F7F57DAb7F4b38D66226); //Pet购买合约地址
    address private statisticsAddress = address(0x175B7faf3AC94E8424d197BA457b387723043B0c); //Data统计的合约地址
    address private tokenShopAddress = address(0x7Ed2bC948bC9Eb6374B3A4737B041CdeDEFFb186); //代币商店的合约地址
    address private talkingRoomAddress = address(0x4EBcD18d70527774a765fAdeCD8C30205EcB8eC8); //聊天室合约地址
    address private petUpgrade1Address = address(0x941EE65B55ef3ef932E406B22Dd58235d53E17bf); //升级1 使用代币概率升级
    address private petUpgrade2Address = address(0x2e0935aCD5F79aA00283FF80dFd9F81ac5c489e1); //升级2 使用同种卡牌升级
    address private petSwitchRoleAddress = address(0x372FA9C87B79Bd20d8e930620e3504cb8bDf09FD); //同一稀有度内切换角色
    address private game1Address = address(0x548a0260d6329a7aeEc282D95936bD8371358Cf6);
    address private game2Address = address(0xC1c5e241dC5F648AB0F66F50121E5aA8548b4fcd);
    address private game3Address = address(0x52869Bfd715bE279c0312057B1C33e902A3044F0);
    address private tokenPoolAddress = address(0x85D8DAE09E4Fb8D453D92b3Ddb6b2304b3d9D9E5);
    address private gamePoolAddress = address(0x92c5d8C771323297db6E8de5024FedAA9Fb49480);

    string private statisticsPermit = 'statistics';
    string private mintPetPermit = 'mintPet';
    string private updatePetPermit = 'updatePet';

    function setAllConfig() external onlyOwner {
        config.setLabelAddress(gameToken, gameTokenAddress);
        config.setLabelAddress(petNFT, petNFTAddress);
        config.setLabelAddress(petShop, petShopAddress);
        config.setLabelAddress(statistics, statisticsAddress);
        config.setLabelAddress(tokenShop, tokenShopAddress);
        config.setLabelAddress(talkingRoom, talkingRoomAddress);
        config.setLabelAddress(petUpgrade1, petUpgrade1Address);
        config.setLabelAddress(petUpgrade2, petUpgrade2Address);
        config.setLabelAddress(petSwitchRole, petSwitchRoleAddress);
        config.setLabelAddress(game1, game1Address);
        config.setLabelAddress(game2, game2Address);
        config.setLabelAddress(game3, game3Address);
        config.setLabelAddress(tokenPool, tokenPoolAddress);
        config.setLabelAddress(gamePool, gamePoolAddress);

        config.setUserPermit(petShopAddress, mintPetPermit, true);

        config.setUserPermit(petUpgrade1Address, updatePetPermit, true);
        config.setUserPermit(petUpgrade2Address, updatePetPermit, true);
        config.setUserPermit(petSwitchRoleAddress, updatePetPermit, true);

        config.setUserPermit(petShopAddress, statisticsPermit, true);
        config.setUserPermit(petUpgrade1Address, statisticsPermit, true);
        config.setUserPermit(petUpgrade2Address, statisticsPermit, true);
        config.setUserPermit(petSwitchRoleAddress, statisticsPermit, true);
        config.setUserPermit(game1Address, statisticsPermit, true);
        config.setUserPermit(game2Address, statisticsPermit, true);
        config.setUserPermit(game3Address, statisticsPermit, true);
    }
}
