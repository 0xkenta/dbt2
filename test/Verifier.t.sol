// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Verifier} from "../src/Verifier.sol";
import {RecipientOrder, RecipientOrderDetail} from "../src/OrderStructs.sol";

contract MockVerifier is Verifier {
    constructor(address _recipient) Verifier(_recipient) {}

    function structHash(RecipientOrderDetail calldata _recipientOrderDetail) external view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    RECIPIENT_ORDER_DETAIL_TYPEHASH,
                    _recipientOrderDetail.to,
                    _recipientOrderDetail.amount,
                    _recipientOrderDetail.id
                )
            )
        );
    }
}

contract VeriferTest is Test {
    uint256 internal DEAFULT_AMOUNT = 1 ether;
    uint256 internal DEFAULT_ID = 0;

    MockVerifier public verifier;

    uint256 internal recipientPrivateKey;
    address internal recipient;
    address internal to = address(0x2);
    uint256 internal otherPrivateKey;

    function setUp() public {
        recipientPrivateKey = 0xA11CE;
        recipient = vm.addr(recipientPrivateKey);

        otherPrivateKey = 0xA11CC;

        verifier = new MockVerifier(recipient);
    }

    function test_initialize() public {
        assertEq(recipient, verifier.recipient());
    }

    function test_execute_return_true() public {
        RecipientOrder memory recipientOrder = _getRecipientOrder(to, DEAFULT_AMOUNT, DEFAULT_ID, recipientPrivateKey);
        bool result = verifier.execute(recipientOrder);
        assertEq(result, true);
    }

    function test_execute_return_true_with_random_values(address _to, uint256 _amount, uint256 _id) public {
        RecipientOrder memory recipientOrder = _getRecipientOrder(_to, _amount, _id, recipientPrivateKey);
        bool result = verifier.execute(recipientOrder);
        assertEq(result, true);
    }

    function test_execute_return_false_if_other_signature_given() public {
        RecipientOrder memory recipientOrder = _getRecipientOrder(to, DEAFULT_AMOUNT, DEFAULT_ID, recipientPrivateKey);

        RecipientOrder memory recipientOrderWithOther =
            _getRecipientOrder(to, DEAFULT_AMOUNT, DEFAULT_ID, otherPrivateKey);
        recipientOrder.signature = recipientOrderWithOther.signature;

        bool result = verifier.execute(recipientOrder);
        assertEq(result, false);
    }

    function _getRecipientOrder(address _to, uint256 _amount, uint256 _id, uint256 _recipientPrivateKey)
        private
        view
        returns (RecipientOrder memory)
    {
        RecipientOrderDetail memory recipientOrderDetail = RecipientOrderDetail({to: _to, amount: _amount, id: _id});

        bytes32 digest = verifier.structHash(recipientOrderDetail);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_recipientPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        bytes memory order = abi.encode(recipientOrderDetail);

        return RecipientOrder({order: order, signature: signature});
    }
}
