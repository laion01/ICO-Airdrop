// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";

interface IIYAICO { 
    function ICO_ENDTIME() external view returns (uint256);
}

contract IYAL is ERC20, ERC20Capped, ERC20Mintable, ERC20Burnable {
    uint256 private BurningAmount;
    uint8 public MaxTransferAmount;
    uint8 public feeAmount;
    address public feeWallet;
    address public ICO_ADDRESS;

    event MaxTransferAmountUpdate(address indexed operator, uint8 Max);

    constructor() 
        ERC20("IYAL", "IYA") 
        ERC20Capped(10000000000000000000000000)
    {
        feeWallet = msg.sender;
        feeAmount = 2;
        BurningAmount = 2;
        _mint(msg.sender, 10000000000000000000000000);
        ICO_ADDRESS = address(0);
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) onlyOwner {
        super._mint(account, amount);
    }

    function SetFeeWallet(address addr) public onlyOwner {
        feeWallet = addr;
    }

    function setMaxTransfer(uint8 max) public onlyOwner {
        emit MaxTransferAmountUpdate(msg.sender, max);
        MaxTransferAmount = max;
    }

    function transfer(
        address recipient,
        uint256 amount
    )  public virtual override returns (bool) {
        IIYAICO ico = IIYAICO(ICO_ADDRESS);

        if(msg.sender == owner() || msg.sender == ICO_ADDRESS) {
            super.transfer(recipient, amount);
            return true;
        }
        if (block.timestamp <= ico.ICO_ENDTIME()) {
            require(msg.sender == owner() || msg.sender == ICO_ADDRESS, "Transfer is locked");
        }
            
        uint256 transferamountlimit = balanceOf(msg.sender) * MaxTransferAmount / 100;

        require(
            amount <= transferamountlimit,
            "your amount more than max transfer"
        );

        uint256 burnAmount = balanceOf(ICO_ADDRESS) * BurningAmount/ 100;
        uint256 fee = amount * feeAmount / 100;
        amount -= fee;
        
        super.transfer(feeWallet, fee);
        super.transfer(recipient, amount);

        require(ICO_ADDRESS != address(0), "ICO Contract isn't set yet.");
        _burn(ICO_ADDRESS, burnAmount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool)  {
        IIYAICO ico = IIYAICO(ICO_ADDRESS);

        if(sender == owner() || sender == ICO_ADDRESS) {
            super.transferFrom(sender, recipient, amount);
            return true;
        }

        if (block.timestamp <= ico.ICO_ENDTIME()) {
            require(sender == owner() || sender == ICO_ADDRESS, "Transfer is locked");
        }
            
        uint256 transferamountlimit = balanceOf(sender) * MaxTransferAmount / 100;

        require(
            amount <= transferamountlimit,
            "your amount more than max transfer"
        );

        uint256 burnAmount = balanceOf(ICO_ADDRESS) * BurningAmount/ 100;
        uint256 fee = amount * feeAmount / 100;
        amount -= fee;

        super.transferFrom(sender, feeWallet, fee);
        super.transferFrom(sender, recipient, amount);

        require(ICO_ADDRESS != address(0), "ICO Contract isn't set yet.");
        _burn(ICO_ADDRESS, burnAmount);

        return true;
    }

    function setICOAddress(address addr) public onlyOwner {
        require(ICO_ADDRESS == address(0), "ICO Contract address is already set!");
        ICO_ADDRESS = addr;
    }    
}
