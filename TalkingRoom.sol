// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

library String {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {b := and(mload(ptr), 0xFF)}
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }
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

contract TalkingRoom is Owner {
    using String for *;

    struct TalkingInfo {
        string data;
        address from;
        uint256 time;
    }

    TalkingInfo[] private talkingData;//设计上只保留100条聊天记录
    uint256 public maxLength = 100;
    uint256 private lastClearIndex = 0;//消息满100条后，清除前面的消息
    mapping(address => string) public nickMap;//昵称
    mapping(address => bool) public blackNameMap;//黑名单，你懂的
    bool private pause;//暂停发言，避免大半夜有人乱搞

    //获取聊天数据
    function getTalkingData(uint256 index) external view returns (string[] memory, address[] memory, uint256[] memory, uint256, string[] memory) {
        //数据总长度
        uint256 allLength = talkingData.length;
        if (index > allLength) {
            index = 0;
        }
        //要返回的数据长度
        uint256 resultLength = allLength - index;
        if (maxLength < resultLength) {
            //设计上最多只返回最近的固定长度的聊天记录，再之前的记录会被清除
            resultLength = maxLength;
            index = allLength - resultLength;
        }
        string[] memory msgList = new string[](resultLength);
        address[] memory addressList = new address[](resultLength);
        uint256[] memory timeList = new uint256[](resultLength);
        string[] memory nickList = new string[](resultLength);
        for (uint256 startIndex = index; startIndex < allLength; ++startIndex) {
            uint256 i = startIndex - index;
            addressList[i] = talkingData[startIndex].from;
            timeList[i] = talkingData[startIndex].time;
            nickList[i] = nickMap[addressList[i]];
            //黑名单用户的消息不返回
            if (blackNameMap[talkingData[startIndex].from]) {
                msgList[i] = '';
            } else {
                msgList[i] = talkingData[startIndex].data;
            }
        }
        return (msgList, addressList, timeList, allLength, nickList);
    }

    //发送消息
    function sendMsg(string memory message) external {
        require(!pause, 'pause talking');
        //不在黑名单
        require(!blackNameMap[msg.sender], 'black name');
        //限制单次发200字
        require(200 > message.toSlice().len(), 'too long');
        talkingData.push(TalkingInfo({data : message, from : msg.sender, time : block.timestamp}));
        //记录超过最大长度
        if (talkingData.length > maxLength) {
            uint256 endIndex = talkingData.length - maxLength;
            for (; lastClearIndex < endIndex; lastClearIndex++) {
                delete talkingData[lastClearIndex];
            }
        }
    }

    //只允许管理员设置昵称，or 收费，哈哈
    function setNick(address addr, string memory nick) external onlyOwner {
        nickMap[addr] = nick;
    }

    //设置黑名单，还是有可能误操作的，加个参数吧
    function setBlackName(address addr, bool enable) external onlyOwner {
        blackNameMap[addr] = enable;
    }

    //清除全部聊天数据，在重大违规事件发生时调用
    function clearAllData() external onlyOwner {
        delete talkingData;
        lastClearIndex = 0;
    }

    function setPause(bool enable) external onlyOwner {
        pause = enable;
    }

    function setMaxLength(uint256 length) external onlyOwner {
        maxLength = length;
    }
}
