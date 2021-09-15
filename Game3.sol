// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

library Util {
    function randomUtil(bytes memory seed, uint256 min, uint256 max)
    internal pure returns (uint256) {

        if (min >= max) {
            return min;
        }

        uint256 number = uint256(keccak256(seed));
        return number % (max - min + 1) + min;
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

contract Game3 is Role {
    using Address for address;

    uint256 private baseRate = 10000;//概率的分母
    mapping(uint256 => uint256[]) private tokenIdFightResults;//卡牌最近一次战斗结果

    string private gameToken = 'gameToken';
    string private statistics = 'statistics';
    string private dailyGameCount = 'dailyGameCount';
    string private petNFT = 'petNFT';

    uint256 expReward = 40;
    uint256 tokenReward = 80000 * 10 ** 18;

    uint256 private baseFight = 1000;
    mapping(uint256 => uint256) private rareBuffers;//稀有度加成

    constructor(){
        rareBuffers[1] = 100;
        rareBuffers[2] = 120;
        rareBuffers[3] = 150;
        rareBuffers[4] = 200;
        rareBuffers[5] = 400;
        rareBuffers[6] = 800;
    }

    function getFight(uint256 tokenId) private view returns (uint256){
        uint256 buffer = uint8(tokenId >> 120);
        uint256 level = uint8(tokenId >> 80);
        uint256 rarity = uint8(tokenId >> 72);
        //fight = baseFight*(1+buffer)*rareBuffer*2^(level-1)
        //level = 1,2,3,4,5 buffer = 1,2,4,8,16
        return baseFight * (100 + buffer) * rareBuffers[rarity] * 2 ** (level - 1) / 10000;
    }

    function randomFight(uint256 fightRate, uint256 count, uint256 tokenId) private returns (uint256) {
        delete tokenIdFightResults[tokenId];
        uint256 winCount;
        uint256 random;
        for (uint256 i = 0; i != count; ++i) {
            random = Util.randomUtil(abi.encode(i, block.timestamp, count - i), 0, 10000);
            if (fightRate >= random) {
                tokenIdFightResults[tokenId].push(1);
                winCount++;
            } else {
                tokenIdFightResults[tokenId].push(0);
            }
        }
        return winCount;
    }


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
        //计算成功率
        uint256 petFight = getFight(tokenId);
        //稀有度低的必须升级一次才能参与
        require(petFight >= 2000, 'fights not reach');
        uint256 fightRate = petFight * petFight / 8000 + petFight / 4;
        uint256 winCount = randomFight(fightRate, count, tokenId);
        //奖励代币
        uint256 winToken = winCount * tokenReward;
        //奖励经验
        uint256 exp = count * expReward;
        data.addLabelAddressData("game3Count", msg.sender, count);
        data.addLabelTokenData("exp", tokenId, exp);
        //赢的次数大于0
        if (0 < winCount) {
            data.addLabelAddressData("game3WinCount", msg.sender, winCount);
            data.addLabelAddressData("winToken", msg.sender, winToken);
            IToken token = IToken(config.labelAddress(gameToken));
            token.transfer(msg.sender, winToken);
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
        uint256 petFight;
        for (uint256 index = 0; index < tokenIds.length; index++) {
            tokenId = tokenIds[index];
            fightCounts[index] = maxFightCount - data.labelTokenData(dailyGameCount, tokenId);
            petFight = getFight(tokenId);
            if (petFight >= 2000) {
                fightRates[index] = petFight * petFight / 8000 + petFight / 4;
            } else {
                fightRates[index] = 0;
            }
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