// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

// Mock imports
import { RWAIncToken } from "../../contracts/RWAIncToken.sol";

// OApp imports
import { IOAppOptionsType3, EnforcedOptionParam } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

// OFT imports
import { IOFT, SendParam, OFTReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee, MessagingReceipt } from "@layerzerolabs/oft-evm/contracts/OFTCore.sol";
import { OFTMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTMsgCodec.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";

// OZ imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Forge imports
import "forge-std/console.sol";

// DevTools imports
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract RWAIncTokenTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 private aEid = 1;

    uint32 private bEid = 2;

    RWAIncToken private aOFT;
    RWAIncToken private bOFT;

    address private RWA_MULTISIG = makeAddr("RWA");
    address private DEPLOYER = makeAddr("DEPLOYER");

    address private userA = makeAddr("userA");
    address private userB = makeAddr("userB");

    uint32 public constant BASE_MAINNET = 8453;
    uint256 public constant ONE_BILLION = 1_000_000_000 * 1e18;

    function setUp() public virtual override {
        //chainId does not do anything here, it is to just show that we are not on BASE mainnet
        vm.chainId(1);
        vm.deal(RWA_MULTISIG, 1000 ether);
        vm.deal(DEPLOYER, 1000 ether);
        vm.deal(userA, 1 ether);

        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        vm.startPrank(DEPLOYER);

        // Deploy RWA on Base mainnet - should mint 1 billion tokens
        vm.chainId(BASE_MAINNET);
        aOFT = new RWAIncToken("RWA Token", "RWA", address(endpoints[aEid]), DEPLOYER, RWA_MULTISIG);

        // Deploy RWA not on Base mainnet - should not mint any tokens
        vm.chainId(1);
        bOFT = new RWAIncToken("RWA Token", "RWA", address(endpoints[bEid]), DEPLOYER, RWA_MULTISIG);

        // config and wire the ofts
        address[] memory ofts = new address[](2);
        ofts[0] = address(aOFT);
        ofts[1] = address(bOFT);
        wireOApps(ofts);
        vm.stopPrank();
    }

    function test_deployment() public {
        assertEq(aOFT.owner(), DEPLOYER);
        assertEq(bOFT.owner(), DEPLOYER);

        assertEq(aOFT.balanceOf(RWA_MULTISIG), ONE_BILLION, "should mint 1 billion tokens because it is on BASE");
        assertEq(bOFT.balanceOf(RWA_MULTISIG), 0, "should not mint any tokens because it is not on BASE");

        assertEq(aOFT.token(), address(aOFT));
        assertEq(bOFT.token(), address(bOFT));
    }
    function test_transfer_2_tokens_from_RWAMultisig_to_userA() public {
        uint256 tokensToSend = 1 ether;

        vm.prank(RWA_MULTISIG);
        aOFT.transfer(userA, tokensToSend);
        assertEq(aOFT.balanceOf(userA), tokensToSend);
        assertEq(aOFT.balanceOf(RWA_MULTISIG), ONE_BILLION - tokensToSend);
    }

    function test_send_oft() public {
        uint256 tokensToSend = 1 ether;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        SendParam memory sendParam = SendParam(
            bEid,
            addressToBytes32(userB),
            tokensToSend,
            tokensToSend,
            options,
            "",
            ""
        );
        MessagingFee memory fee = aOFT.quoteSend(sendParam, false);

        test_transfer_2_tokens_from_RWAMultisig_to_userA();

        uint256 initialBalanceOnA = aOFT.balanceOf(userA);
        uint256 initialBalanceOnB = bOFT.balanceOf(userB);

        vm.prank(userA);
        aOFT.send{ value: fee.nativeFee }(sendParam, fee, userA);
        verifyPackets(bEid, addressToBytes32(address(bOFT)));

        assertEq(aOFT.balanceOf(userA), initialBalanceOnA - tokensToSend);
        assertEq(bOFT.balanceOf(userB), initialBalanceOnB + tokensToSend);
    }
}
