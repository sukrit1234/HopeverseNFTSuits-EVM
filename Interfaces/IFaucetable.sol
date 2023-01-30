// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFaucetable {

    function get_token_contract() external view returns (address);

    function request_faucet() external;

    function refill_faucet(uint256 amount) external;

    function get_amount_per_request() external view returns (uint256);

    function get_remain_faucet_amount() external view returns (uint256);
}