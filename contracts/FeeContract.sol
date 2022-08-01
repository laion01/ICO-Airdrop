// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "hardhat/console.sol";

/*===================================================
    OpenZeppelin Contracts (last updated v4.5.0)
=====================================================*/

contract FeeContract is Ownable {
    using SafeERC20 for IERC20;

    // IYA token
    IERC20 private iya;

    // time to start claim.
    uint256 public ICO_ENDTIME = 0; // Thu Apr 14 2022 00:00:00 UTC

    // wallet to withdraw
    address public wallet;

    // presale and airdrop program with refferals
    uint256 private _referToken = 7000; //70% Token
    uint256 private _airdropEth = 2000000000000000; //0.002 BNB Airdrop fee
    uint256 private _airdropToken = 1000000000000000000; // 1 token will be given on airdrop
    uint256 private salePrice = 25000000000; // 0.01*25000000000=250.000.000 token for 0.01 bnb (set as per requirements)

    /**
     * @dev Initialize with token address and round information.
     */
    constructor () Ownable() {
        wallet = msg.sender;
    }
    
    receive() payable external {}
    fallback() payable external {}

    function setToken(address _iya) public onlyOwner {
        require(_iya != address(0), "presale-err: invalid address");
        iya = IERC20(_iya);
    }

    /**
     * @dev ICO Endtime.
     */
    function setEndTime(uint256 endtime) public onlyOwner {
        ICO_ENDTIME = endtime;
    }

    /**
     * @dev Withdraw  iya token from this contract.
     */
    function withdrawTokens(address _token) external onlyOwner {
        if(_token == address(0)) {
            payable(wallet).transfer(address(this).balance);
        } else {
            IERC20(_token).safeTransfer(wallet, IERC20(_token).balanceOf(address(this)));
        }
    }

    /**
     * @dev Set wallet to withdraw.
     */
    function setWalletReceiver(address _newWallet) external onlyOwner {
        wallet = _newWallet;
    }
}