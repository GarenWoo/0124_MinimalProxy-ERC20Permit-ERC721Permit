//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title An interface of ERC721TokenWithPermit which is checked in function supportsInterface.
 *
 * @author Garen Woo
 */
interface IERC721TokenWithPermit {
    function NFTPermit(
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external returns (bool);
}

/**
 * @title This ERC721 token has permit checking that simulates a 'white list'. EOAs in the 'white list' can buy NFT from any NFT exchange
 *
 * @author Garen Woo
 */
contract ERC721TokenWithPermit is ERC721URIStorage, EIP712, Nonces {
    address public owner;
    error NotOwner(address caller);
    error Unapproved(address derivedSigner, address validSigner);
    error ExpiredSignature(uint256 currendTimestamp, uint256 deadline);

    constructor()
        ERC721("Garen at OpenSpace", "GOS")
        EIP712("Garen at OpenSpace", "1")
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    function mint(
        address to,
        string memory tokenURI
    ) public onlyOwner returns (uint256) {
        uint256 newItemId = nonces(address(this));
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _useNonce(address(this));
        return newItemId;
    }

    /**
     * @dev When 'buyer' buys a specific NFT(specified by input '_tokenId'), this function will check if 'buyer' is in "white-list".
     * The signed message will be the proof to be input into this function and will be checked for its validity.
     *
     * @param _spender the address which can control the NFT after the permit is verified to be valid
     * @param _tokenId the specific tokenId of the NFT which needs permit checking
     * @param _deadline the expire timestamp of the input signed message
     * @param _v ECDSA signature parameter v
     * @param _r ECDSA signature parameter r
     * @param _s ECDSA signature parameter s
     * @dev NFTAuth is the address which owns the NFT or is approved to control the NFT. Here is the NFT exchange in this function.
     * @dev buyer is the EOA who wants to buy the NFT from the NFT exchange.
     */
    function NFTPermit(
        address _spender,
        uint256 _tokenId,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (bool) {
        address NFTAdmin = owner;
        address NFTAuth = msg.sender;
        address buyer = _spender;
        bytes32 PERMIT_TYPEHASH = keccak256(
            "NFTPermit(address buyer,uint256 tokenId,uint256 signerNonce,uint256 deadline)"
        );
        if (block.timestamp > _deadline) {
            revert ExpiredSignature(block.timestamp, _deadline);
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                buyer,
                _tokenId,
                _useNonce(NFTAdmin),
                _deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, _v, _r, _s);
        if (signer != NFTAdmin) {
            revert Unapproved(signer, NFTAdmin);
        }

        _approve(buyer, _tokenId, NFTAuth);
        return true;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == type(IERC721TokenWithPermit).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}
