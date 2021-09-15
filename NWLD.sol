// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface Token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract NWLD is Owner, IERC20, Token {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor () {
        _totalSupply = 100000000 * 1000 * 10 ** 18;
        _balances[msg.sender] = _totalSupply;
    }

    function name() public view virtual returns (string memory) {
        return 'N World';
    }

    function symbol() public view virtual returns (string memory) {
        return 'NWLD';
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][msg.sender] >= amount, "> b");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "from 0 addr");
        require(recipient != address(0), "to 0 addr");
        require(_balances[sender] >= amount, "> b");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "from 0 addr");
        require(spender != address(0), "to 0 addr");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function withdrawToken(address _tokenAddress) onlyOwner public {
        Token token = Token(_tokenAddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function withdrawBalance() onlyOwner public {
        address payable addr = payable(owner);
        addr.transfer(address(this).balance);
    }
}