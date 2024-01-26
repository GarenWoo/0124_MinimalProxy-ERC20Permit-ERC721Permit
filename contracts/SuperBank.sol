// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Bank.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// @dev SuperBank can receive ETH, any ERC20 tokens and any SafeERC20 tokens.
contract SuperBank is Bank {
    mapping(address => mapping(address => uint)) internal tokenBalance;
    address[3] internal tokenRank;
    IERC20 public iERC20Token;
    using SafeERC20 for IERC20;
    event tokenReceived(address sender, uint amount);

    constructor() {
        owner = msg.sender;
    }

    function depositToken(address _tokenAddr, uint _tokenAmount) public {
        iERC20Token = IERC20(_tokenAddr);
        /* 
        Considering the design of those functions with the prefix of 'safe' in SafeERC20 contract,
        if the token does not support safeTransferFrom, it will turn to call transferFrom instead.
        */
        iERC20Token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        tokenBalance[_tokenAddr][msg.sender] += _tokenAmount;
        _handleRankWhenDepositToken(_tokenAddr);
    }

    function depositTokenWithPermit(
        address _tokenAddr,
        uint _tokenAmount,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        IERC20Permit(_tokenAddr).permit(msg.sender, address(this), _tokenAmount, _deadline, _v, _r, _s);
        iERC20Token = IERC20(_tokenAddr);
        /* 
        Considering the design of those functions with the prefix of 'safe' in SafeERC20 contract,
        if the token does not support safeTransferFrom, it will turn to call transferFrom instead.
        */
        iERC20Token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        tokenBalance[_tokenAddr][msg.sender] += _tokenAmount;
        _handleRankWhenDepositToken(_tokenAddr);
    }

    function withdrawToken(address _tokenAddr) public onlyOwner {
        iERC20Token = IERC20(_tokenAddr);
        /* 
        Considering the design of those functions with the prefix of 'safe' in SafeERC20 contract,
        if the token does not support safeTransfer, it will turn to call transfer instead.
        */
        iERC20Token.safeTransfer(owner, iERC20Token.balanceOf(address(this)));
    }

    function tokensReceived(
        address _tokenAddr,
        address _from,
        uint _amount
    ) external returns (bool) {
        tokenBalance[_tokenAddr][_from] += _amount;
        emit tokenReceived(_from, _amount);
        return true;
    }

    function getTokenBalance(
        address _tokenAddr,
        address _account
    ) public view returns (uint) {
        return tokenBalance[_tokenAddr][_account];
    }

    function getTokenTopThreeAccount()
        public
        view
        returns (address, address, address)
    {
        return (tokenRank[0], tokenRank[1], tokenRank[2]);
    }

    function _handleRankWhenDepositToken(address _tokenAddr) internal {
        uint membershipIndex = _checkTokenRankMembership();
        uint convertedIndex;
        uint indexRecord = 777;
        if (membershipIndex != 999) {
            // Case 1: msg.sender is already inside the top3 rank.
            convertedIndex = membershipIndex + 4;
            for (uint i = convertedIndex - 3; i > 1; i--) {
                if (membershipIndex != 0) {
                    if (
                        tokenBalance[_tokenAddr][msg.sender] >=
                        tokenBalance[_tokenAddr][tokenRank[i - 2]]
                    ) {
                        indexRecord = i - 2;
                        for (uint j = 2; j > i - 2; j--) {
                            tokenRank[j] = tokenRank[j - 1];
                        }
                        // Boundry condition
                        if (indexRecord == 0) {
                            tokenRank[indexRecord] = msg.sender;
                        }
                    } else {
                        if (indexRecord != 777) {
                            tokenRank[indexRecord] = msg.sender;
                        }
                    }
                }
            }
        } else {
            // Case 2: msg.sender is not inside the top3 rank.
            for (uint i = 3; i > 0; i--) {
                if (
                    tokenBalance[_tokenAddr][msg.sender] >=
                    tokenBalance[_tokenAddr][tokenRank[i - 1]]
                ) {
                    indexRecord = i - 1;
                    // move backward the element(s) which is(/are) right at the index and also behind the index
                    for (uint j = 2; j > i - 1; j--) {
                        tokenRank[j] = tokenRank[j - 1];
                    }
                    // Boundry condition
                    if (indexRecord == 0) {
                        tokenRank[indexRecord] = msg.sender;
                    }
                } else {
                    if (indexRecord != 777) {
                        tokenRank[indexRecord] = msg.sender;
                    }
                }
            }
        }
    }

    function _checkTokenRankMembership() internal view returns (uint) {
        uint index = 999;
        for (uint i = 0; i < 3; i++) {
            if (tokenRank[i] == msg.sender) {
                index = i;
                break;
            }
        }
        return index;
    }
}
