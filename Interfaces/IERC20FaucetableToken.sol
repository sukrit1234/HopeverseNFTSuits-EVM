// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20FaucetableToken {

    function request_faucet_for(address pool_address,uint256 amount) external;
}