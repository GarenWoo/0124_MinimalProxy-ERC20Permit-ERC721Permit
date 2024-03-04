// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ITokenBank {
    function tokensReceived(address, uint256) external returns (bool);
}

interface INFTMarket {
    function tokensReceived(address, uint256, bytes calldata) external;
}

contract FairTokenGFT_V1 is ERC20, ERC20Permit, ReentrancyGuard, Initializable {
    address public factory;
    string private _name;
    string private _symbol;
    uint256 public maxSupply;
    uint256 public amountPerMint;

    error NotFactory(address caller);
    error NoTokenReceived();
    error TransferTokenFail();
    error NotContract();
    error ReachMaxSupply(uint256 currentTotalSupply);

    event TokenMinted(uint256 amount, uint256 timestamp);
    event TransferedWithCallback(address target, uint256 amount);
    event TransferedWithCallbackForNFT(address target, uint256 amount, bytes data);

    using SafeERC20 for FairTokenGFT_V1;
    using Address for address;

    constructor() ERC20("Garen Fair Token", "GFT") ERC20Permit("Garen Fair Token") {
        factory = msg.sender;
    }

    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert NotFactory(msg.sender);
        }
        _;
    }

    function init(
        address _factory,
        string calldata _initName,
        string calldata _initSymbol,
        uint256 _initTotalSupply,
        uint256 _initPerMint
    ) external initializer {
        factory = _factory;
        _name = _initName;
        _symbol = _initSymbol;
        maxSupply = _initTotalSupply;
        amountPerMint = _initPerMint;
    }

    function mint(address _recipient) external onlyFactory {
        uint256 currentTotalSupply = totalSupply();
        if (currentTotalSupply + amountPerMint > maxSupply) {
            revert ReachMaxSupply(currentTotalSupply);
        }
        _mint(_recipient, amountPerMint);
        emit TokenMinted(amountPerMint, block.timestamp);
    }

    // ERC20 Token Callback:
    function transferWithCallback(address _to, uint256 _amount) external nonReentrant returns (bool) {
        bool transferSuccess = transfer(_to, _amount);
        if (!transferSuccess) {
            revert TransferTokenFail();
        }
        if (_isContract(_to)) {
            bool success = ITokenBank(_to).tokensReceived(msg.sender, _amount);
            if (!success) {
                revert NoTokenReceived();
            }
        }
        emit TransferedWithCallback(_to, _amount);
        return true;
    }

    // ERC721 Token Callback:
    // @param: _data contains information of NFT, including ERC721Token address, tokenId and other potential information.
    function transferWithCallbackForNFT(address _to, uint256 _bidAmount, bytes calldata _data)
        external
        nonReentrant
        returns (bool)
    {
        if (_isContract(_to)) {
            INFTMarket(_to).tokensReceived(_to, _bidAmount, _data);
        } else {
            revert NotContract();
        }
        emit TransferedWithCallbackForNFT(_to, _bidAmount, _data);
        return true;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function getBytesOfNFTInfo(address _NFTAddr, uint256 _tokenId) public pure returns (bytes memory) {
        bytes memory NFTInfo = abi.encode(_NFTAddr, _tokenId);
        return NFTInfo;
    }
}
