pragma solidity 0.8.23;

struct RecipientOrder {
    bytes order;
    bytes signature;
}

struct RecipientOrderDetail {
    address to;
    uint256 amount;
    uint256 id;
}
