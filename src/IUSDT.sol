// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

// Because USDT is not so standard ERC20, we just use their code as interface
interface IUSDT {
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function balanceOf(address who) external view returns (uint);
    function approve(address _spender, uint _value) external;
    function allowance(address _owner, address _spender) external view returns (uint remaining);
}