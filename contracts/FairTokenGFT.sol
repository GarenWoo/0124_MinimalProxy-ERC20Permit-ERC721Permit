// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ITokenBank {
    function tokensReceived(address, uint) external returns (bool);
}

interface INFTMarket {
    function tokensReceived(address, address, uint, bytes calldata) external;
}

contract FairTokenGFT is ERC20, ERC20Permit, ReentrancyGuard {
    using SafeERC20 for FairTokenGFT;
    using Address for address;
    address public owner;
    string private _name;
    string private _symbol;
    uint256 public maxSupply;
    uint256 public amountPerMint;
    error NotOwner(address caller);
    error NoTokenReceived();
    error transferTokenFail();
    error NotContract();
    error ReachMaxSupply(uint256 currentTotalSupply);
    event TokenMinted(uint amount, uint timestamp);

    constructor()
        ERC20("Garen Fair Token", "GFT")
        ERC20Permit("Garen Fair Token")
    {
        owner = msg.sender;
        /// @dev Initial totalsupply is 100,000
        _mint(msg.sender, 100000 * (10 ** uint256(decimals())));
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    function init(
        string calldata _initName,
        string calldata _initSymbol,
        uint256 _initTotalSupply,
        uint256 _initPerMint
    ) external {
        _name = _initName;
        _symbol = _initSymbol;
        maxSupply = _initTotalSupply;
        amountPerMint = _initPerMint;
    }

    function mint(address _recipient) external {
        uint256 currentTotalSupply = totalSupply();
        if (currentTotalSupply + amountPerMint > maxSupply) {
            revert ReachMaxSupply(currentTotalSupply);
        }
        _mint(_recipient, amountPerMint);
        emit TokenMinted(amountPerMint, block.timestamp);
    }

    // ERC20 Token Callback:
    function transferWithCallback(
        address _to,
        uint _amount
    ) external nonReentrant returns (bool) {
        bool transferSuccess = transfer(_to, _amount);
        if (!transferSuccess) {
            revert transferTokenFail();
        }
        if (_isContract(_to)) {
            bool success = ITokenBank(_to).tokensReceived(msg.sender, _amount);
            if (!success) {
                revert NoTokenReceived();
            }
        }
        return true;
    }

    // ERC721 Token Callback:
    // @param: _data contains information of NFT, including ERC721Token address, tokenId and other potential information.
    function transferWithCallbackForNFT(
        address _to,
        uint _bidAmount,
        bytes calldata _data
    ) external nonReentrant returns (bool) {
        if (_isContract(_to)) {
            INFTMarket(_to).tokensReceived(msg.sender, _to, _bidAmount, _data);
        } else {
            revert NotContract();
        }
        return true;
    }

    function getBytesOfNFTInfo(
        address _NFTAddr,
        uint256 _tokenId
    ) public pure returns (bytes memory) {
        bytes memory NFTInfo = abi.encode(_NFTAddr, _tokenId);
        return NFTInfo;
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
