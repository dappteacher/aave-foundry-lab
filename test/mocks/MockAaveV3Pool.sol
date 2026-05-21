// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../../src/interfaces/IERC20.sol";

contract MockAaveV3Pool {
    mapping(address => mapping(address => uint256)) public supplied;

    address public lastAsset;
    uint256 public lastAmount;
    address public lastOnBehalfOf;
    uint16 public lastReferralCode;

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        supplied[asset][onBehalfOf] += amount;
        lastAsset = asset;
        lastAmount = amount;
        lastOnBehalfOf = onBehalfOf;
        lastReferralCode = referralCode;
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        uint256 available = supplied[asset][msg.sender];
        uint256 withdrawn = amount == type(uint256).max || amount > available ? available : amount;

        supplied[asset][msg.sender] = available - withdrawn;
        IERC20(asset).transfer(to, withdrawn);

        return withdrawn;
    }
}
