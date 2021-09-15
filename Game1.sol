// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

interface IPet {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokensOf(address owner) external view returns (uint256[] memory);
}

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IConfig {
    function labelAddress(string memory label) view external returns (address);

    function labelData(string memory label) view external returns (uint256);

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

interface IData {
    function addLabelAddressData(string memory label, address _address, uint256 value) external;

    function addLabelTokenData(string memory label, uint256 tokenId, uint256 value) external;

    function labelTokenData(string memory label, uint256 tokenId) external view returns (uint256);
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

contract Game1 is Role {
    using Address for address;

    mapping(uint256 => uint256[]) private tokenIdFightResults;//卡牌最近一次战斗结果

    string private gameToken = 'gameToken';
    string private statistics = 'statistics';
    string private dailyGameCount = 'dailyGameCount';
    string private petNFT = 'petNFT';

    uint256 expReward = 10;
    uint256 tokenReward = 1000 * 10 ** 18;

    function fight(uint256 tokenId, uint256 count) external {
        require(!msg.sender.isContract(), "contract not allow");
        IPet pet = IPet(config.labelAddress(petNFT));
        //必须是nft所有者
        require(msg.sender == pet.ownerOf(tokenId), 'not the owner');
        uint256 maxGameCount = config.labelData(dailyGameCount);
        IData data = IData(config.labelAddress(statistics));
        uint256 gameCount = data.labelTokenData(dailyGameCount, tokenId);
        //检测次数
        require(maxGameCount >= count + gameCount, 'exceed count');
        data.addLabelTokenData(dailyGameCount, tokenId, count);
        //奖励代币
        uint256 winToken = count * tokenReward;
        //奖励经验
        uint256 exp = count * expReward;
        data.addLabelAddressData("game1WinCount", msg.sender, count);
        data.addLabelAddressData("winToken", msg.sender, winToken);
        data.addLabelTokenData("exp", tokenId, exp);
        IToken token = IToken(config.labelAddress(gameToken));
        token.transfer(msg.sender, winToken);

        delete tokenIdFightResults[tokenId];
        for (uint256 i = 0; i != count; ++i) {
            tokenIdFightResults[tokenId].push(1);
        }
    }

    function getFightPets(address owner) external view returns (uint256[] memory, uint256[] memory, uint256[] memory){
        IPet pet = IPet(config.labelAddress(petNFT));
        uint256[] memory tokenIds = pet.tokensOf(owner);
        uint256[] memory fightCounts = new uint256[](tokenIds.length);
        uint256[] memory fightRates = new uint256[](tokenIds.length);
        uint256 maxFightCount = config.labelData(dailyGameCount);
        IData data = IData(config.labelAddress(statistics));
        uint256 tokenId;
        for (uint256 index = 0; index < tokenIds.length; index++) {
            tokenId = tokenIds[index];
            fightCounts[index] = maxFightCount - data.labelTokenData(dailyGameCount, tokenId);
            fightRates[index] = 10000;
        }
        return (tokenIds, fightCounts, fightRates);
    }

    function setExpReward(uint256 reward) external onlyOwner {
        expReward = reward;
    }

    function minusTokenReward(uint256 rate) external onlyOwner {
        //只减产
        tokenReward = tokenReward - tokenReward * rate / 10000;
    }

    function getFightReward() external view returns (uint256, uint256){
        return (tokenReward, expReward);
    }

    function getFightResults(uint256 tokenId) external view returns (uint256[] memory){
        return tokenIdFightResults[tokenId];
    }
}