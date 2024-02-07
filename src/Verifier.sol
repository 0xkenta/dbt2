pragma solidity 0.8.23;

// reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/metatx/ERC2771Forwarder.sol

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {RecipientOrder} from "./OrderStructs.sol";

contract Verifier is EIP712 {
    bytes32 internal constant RECIPIENT_ORDER_DETAIL_TYPEHASH =
        keccak256("RecipientOrderDetail(address to,uint256 amount,uint256 id)");

    address public recipient;

    constructor(address _recipient) EIP712("Test", "0.0.1") {
        recipient = _recipient;
    }

    function execute(RecipientOrder calldata _recipientOrder) external view returns (bool) {
        // decode
        (address to, uint256 amount, uint256 id) = abi.decode(_recipientOrder.order, (address, uint256, uint256));

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(RECIPIENT_ORDER_DETAIL_TYPEHASH, to, amount, id)));

        address signer = ECDSA.recover(digest, _recipientOrder.signature);

        return recipient == signer ? true : false;
    }
}
