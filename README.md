# Cross-Chain Rebase Token

This protocol implements a cross-chain rebase token system where users can deposit assets into a vault and receive tokens that represent their underlying balance. The unique feature of this token is its dynamic balance mechanism.

## Key Mechanics

### 1. Dynamic Balance (Rebase)
The token's `balanceOf` function is designed to be dynamic, reflecting a balance that increases linearly over time. This ensures that users' holdings grow automatically as they hold the token.

### 2. Interest Rate Model
- **Global Interest Rate**: The protocol maintains a global interest rate that is designed to decrease over time. This mechanism is intended to incentivize early adopters by offering them higher rates.
- **Individual Rates**: When a user deposits into the vault, their interest rate is locked in based on the current global rate. This personalized rate determines how fast their balance grows.

### 3. Token Operations
New tokens are minted to users whenever they interact with the protocol. This includes actions such as:
- Minting
- Burning
- Transferring
- Bridging