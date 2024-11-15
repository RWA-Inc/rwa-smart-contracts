// SPDX-License-Identifier: MIT

//** RWA Token */
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title Official RWA Token
/// @author https://www.rwa.inc
/// @dev Powered by OpenZeppelin - Industry-leading security expertise and world-class intelligence

contract RWAToken is ERC20Burnable {
    /// @notice A constructor that mint the tokens
    constructor() ERC20("RWA Token", "RWA") {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());
    }
}
