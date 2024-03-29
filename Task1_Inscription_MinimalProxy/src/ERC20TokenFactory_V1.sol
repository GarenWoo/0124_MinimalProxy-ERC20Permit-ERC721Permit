// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./FairTokenGFT_V1.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title This is a factory contract that deploys inscription (ERC-20 token) contract instances by cloning a logic contract that provides the implementation of the inscription.
 *
 * @author Garen Woo
 */
contract ERC20TokenFactory_V1 is Ownable {
    using Clones for address;

    // This is the address of the implement contract(template of ERC20Token contract)
    address private libraryAddress;

    struct InscriptionStruct {
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 perMint;
    }

    mapping(address => InscriptionStruct) public inscriptionInfo;

    event ImpleCloned(address instanceAddress);
    event Minted(address inscriptAddr, uint256 mintedAmount);

    error ReachMaxSupply(address inscriptAddr, uint256 currentSupply, uint256 mintedAmount, uint256 maxSupply);

    /**
     * @notice maxAmountOfInscription is a deterministic number that limits the maximum amount of inscription.
     * This parameter set a cap to avoid transaction failure which results from over-high gas.
     * This state variable can be modified by owner of this factory.
     */
    uint256 public maxAmountOfInscription = 10000;

    constructor(address _libraryAddress) Ownable(msg.sender) {
        libraryAddress = _libraryAddress;
    }

    /**
     * @dev Using the implement contract of libraryAddress, deploy its contract instance.
     *
     * @param _tokenName the name of the ERC20 token contract that will be deployed
     * @param _tokenSymbol the symbol of the ERC20 token contract that will be deployed
     * @param _tokenTotalSupply the maximum of the token supply(if this maximum is reached, token cannot been minted any more)
     * @param _perMint the fixed amount of token that can be minted once
     */
    function deployInscription(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokenTotalSupply,
        uint256 _perMint
    ) public returns (address) {
        address clonedImpleInstance = libraryAddress.clone();
        InscriptionStruct memory deployedInscription = InscriptionStruct({
            name: _tokenName,
            symbol: _tokenSymbol,
            totalSupply: _tokenTotalSupply,
            perMint: _perMint
        });
        inscriptionInfo[clonedImpleInstance] = deployedInscription;

        FairTokenGFT_V1(clonedImpleInstance).init(address(this), _tokenName, _tokenSymbol);
        emit ImpleCloned(clonedImpleInstance);
        return clonedImpleInstance;
    }

    /**
     * @dev Mint fixed amount of token in the contract of '_tokenAddr'.
     *
     * @param _tokenAddr the address of the contract instance which is cloned from the implement contract
     */
    function mintInscription(address _tokenAddr) public {
        _beforeMintInscription(_tokenAddr);
        uint256 amountPerMint = inscriptionInfo[_tokenAddr].perMint;
        FairTokenGFT_V1(_tokenAddr).mint(msg.sender, amountPerMint);
        emit Minted(_tokenAddr, amountPerMint);
    }

    /**
     * @dev Replace the address of the implement contract with a new one.
     * This function can only be called by the owner of this factory contract.
     */
    function setLibraryAddress(address _libraryAddr) public onlyOwner {
        libraryAddress = _libraryAddr;
    }

    /**
     * @dev Update the maximum of the ERC20 token contract instances
     */
    function setMaxAmountOfInscription(uint256 _newMaximum) external onlyOwner {
        maxAmountOfInscription = _newMaximum;
    }

    /**
     * @notice This function is used to get the current total amount of minted token. It's for the convenience of knowing
     * if the current total amount has reached the maximum.
     *
     * @param _tokenAddr the address of the contract instance which is cloned from the implement contract
     */
    function getInscriptionCurrentSupply(address _tokenAddr) public view returns (uint256) {
        return FairTokenGFT_V1(_tokenAddr).totalSupply();
    }

    /**
     * @dev Get the current address of the implement contract
     */
    function getLibraryAddress() public view returns (address) {
        return libraryAddress;
    }

    /**
     * @dev Get the information of the inscription at `_inscriptionAddr`.
     */
    function getInscriptionInfo(address _inscriptionAddr) public view returns (InscriptionStruct memory) {
        return inscriptionInfo[_inscriptionAddr];
    }

    function _beforeMintInscription(address _tokenAddr) internal view {
        uint256 currentTotalSupply = FairTokenGFT_V1(_tokenAddr).totalSupply();
        uint256 amountPerMint = inscriptionInfo[_tokenAddr].perMint;
        uint256 maxSupply = inscriptionInfo[_tokenAddr].totalSupply;
        if (currentTotalSupply + amountPerMint > maxSupply) {
            revert ReachMaxSupply(_tokenAddr, currentTotalSupply, amountPerMint, maxSupply);
        }
    }
}
