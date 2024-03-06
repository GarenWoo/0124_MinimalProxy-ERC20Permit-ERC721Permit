// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FairTokenGFT_V1} from '../src/FairTokenGFT_V1.sol';
import {ERC20TokenFactory_V1} from '../src/ERC20TokenFactory_V1.sol';

import {Test, console} from "forge-std/Test.sol";

contract ERC20TokenFactory_V1_Test is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    FairTokenGFT_V1 public implementContract;
    ERC20TokenFactory_V1 public inscriptFactoryContract;

    address public implementAddr;
    address public inscriptFactoryAddr;
    

    function setUp() public {
        vm.startPrank(alice);
        implementContract = new FairTokenGFT_V1();
        implementAddr = address(implementContract);
        inscriptFactoryContract = new ERC20TokenFactory_V1(implementAddr);
        inscriptFactoryAddr = address(inscriptFactoryContract);
        deal(alice, 200000 ether);
        vm.stopPrank();
    }

    function test_DeployInscription() public {
        vm.startPrank(alice);
        address inscriptAddr = inscriptFactoryContract.deployInscription("OpenSpace Token", "OT", 10000, 1000);
        string memory inscriptName = inscriptFactoryContract.getInscriptionInfo(inscriptAddr).name;
        string memory inscriptSymbol = inscriptFactoryContract.getInscriptionInfo(inscriptAddr).symbol;
        uint256 inscriptTotalSupply = inscriptFactoryContract.getInscriptionInfo(inscriptAddr).totalSupply;
        uint256 inscriptPerMint = inscriptFactoryContract.getInscriptionInfo(inscriptAddr).perMint;
        vm.stopPrank();
        assertEq(inscriptName, "OpenSpace Token", "Expected name of the inscription is 'OpenSpace Token'!");
        assertEq(inscriptSymbol, "OT", "Expected symbol of the inscription is 'OT'!");
        assertEq(inscriptTotalSupply, 10000, "Expected totalSupply of the inscription is 10000!");
        assertEq(inscriptPerMint, 1000, "Expected perMint of the inscription is 1000!");
    }

    function test_MintInscription() public {
        vm.startPrank(alice);
        address inscriptAddr = inscriptFactoryContract.deployInscription("OpenSpace Token", "OT", 10000, 1000);
        uint256 inscriptPerMint = inscriptFactoryContract.getInscriptionInfo(inscriptAddr).perMint;
        FairTokenGFT_V1 inscriptInstance = FairTokenGFT_V1(inscriptAddr);    // the newly deployed inscription instance
        inscriptFactoryContract.mintInscription(inscriptAddr);
        uint256 tokenInUser = inscriptInstance.balanceOf(alice);
        vm.stopPrank();
        assertTrue(tokenInUser == inscriptPerMint, "Expect the inscription balance of user equal to perMint");
    }

}
