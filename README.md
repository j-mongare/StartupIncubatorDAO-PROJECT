# Startup Incubator DAO (Learning Project)

Hi 👋 I'm learning Solidity and smart contract development!  
This project is part of my journey to understand how DAOs (Decentralized Autonomous Organizations) work on Ethereum.

It’s a basic version of an **Incubator DAO**, where:
- People can register startup projects.
- Members can vote on which projects should get funding.
- A secure vault holds and releases ETH when proposals are approved.

---

## 🧱 What I Learned
While building this project, I learned:
- How to write and organize multiple smart contracts in Solidity.
- How ERC20 tokens work (used here as a reputation token called **IREP**).
- How to use modifiers, events, and custom errors for better contract structure.
- How to use OpenZeppelin libraries safely and effectively.

---

## 🧩 The Contracts
1. **IncubatorToken.sol** — ERC20 token for reputation and voting power.  
2. **ProjectRegistry.sol** — Stores startup projects and approvals.  
3. **GrantVault.sol** — Holds ETH and releases grants to approved projects.  
4. **IncubatorManager.sol** — Handles voting, proposals, and overall DAO logic.

---

## ⚙️ Tools I Used
- [Remix IDE](https://remix.ethereum.org) — for writing and testing Solidity.  
- **Solidity 0.8.23** — current compiler version.  
- **OpenZeppelin Contracts** — for ERC20, AccessControl, and ReentrancyGuard.

---

## 🚀 How to Try It
If you want to test it too:
1. Open [Remix IDE](https://remix.ethereum.org).
2. Upload all the `.sol` files from this repo.
3. Compile them using version **0.8.23**.
4. Deploy in this order:
   - `IncubatorToken.sol`
   - `ProjectRegistry.sol`
   - `GrantVault.sol`
   - `IncubatorManager.sol`

---

## 🧠 Next Steps
I plan to:
- Learn how to write unit tests.
- Improve voting logic and add more DAO features.
- Keep learning Solidity and smart contract security!

---

## 🪪 License
MIT License — free to use and learn from.

---

> 💡 *This project is for learning purposes only — not for production use.*

