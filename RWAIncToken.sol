// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/oft-evm/contracts/OFT.sol";

contract RWAIncToken is OFT {
    uint32 public constant BASE_MAINNET = 8453;
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        address _owner
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        // if the contract is deployed on base mainnet then mint 1 billion tokens to the _owner
        if (block.chainid == BASE_MAINNET)
            // mint 1 billion tokens to the _owner (which is RWA's multisig)
            _mint(_owner, 1_000_000_000 * 10 ** decimals());
    }
}
