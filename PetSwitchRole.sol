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

interface IConfig {
    function labelAddress(string memory label) view external returns (address);

    function hasPermit(address user, string memory permit) view external returns (bool);
}

interface IToken {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IPet {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function update(address to, uint256 tokenId, uint256 newWho) external returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external payable;
}

interface IData {
    function addLabelAddressData(string memory label, address _address, uint256 value) external;

    function labelTokenData(string memory label, uint256 tokenId) external view returns (uint256);

    function addLabelTokenData(string memory label, uint256 tokenId, uint256 value) external;
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

contract PetSwitchRole is Role {
    using Address for address;
    using UInteger for uint256;

    uint256 public price = 100000 * 10 ** 18;//升级价格，初始10万，跟随商品售卖价格变化

    string private gameToken = 'gameToken';
    string private petNFT = 'petNFT';
    string private statistics = 'statistics';

    address private dead = address(0x000000000000000000000000000000000000dEaD);

    function switchRole(uint256 tokenId, uint256 who) external {
        require(!msg.sender.isContract(), "contract is not allowed");
        IToken token = IToken(config.labelAddress(gameToken));
        uint256 balanceBefore = token.balanceOf(msg.sender);
        //销毁代币
        token.transferFrom(msg.sender, dead, price);
        //验证是否攻击，花费同样的代币升级多次
        require(balanceBefore == price.add(token.balanceOf(msg.sender)), "account balance exception");
        IPet pet = IPet(config.labelAddress(petNFT));
        //切换角色
        uint256 petId = pet.update(msg.sender, tokenId, who);
        //销毁卡牌
        pet.transferFrom(msg.sender, dead, tokenId);
        //统计
        IData data = IData(config.labelAddress(statistics));
        data.addLabelAddressData("switchPetFee", msg.sender, price);
        data.addLabelAddressData("switchPetCount", msg.sender, 1);
        //转移卡牌经验
        data.addLabelTokenData("exp", petId, data.labelTokenData("exp", tokenId));
        data.addLabelTokenData("dailyGameCount", petId, data.labelTokenData("dailyGameCount", tokenId));
    }

    function addPrice(uint256 priceRate) external onlyOwner {
        uint256 priceAdd = price.mul(priceRate).div(10000);
        price = price.add(priceAdd);
    }
}
