// App-level variables
let provider, signer, contract;
const CONTRACT_ADDRESS = "0xD5e86470A713624138c2FdC77d376AAFf9383d02";
let userAddress = "";

// Connect wallet using MetaMask
async function connectWallet() {
  if (window.ethereum) {
    provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = await provider.getSigner();
    userAddress = await signer.getAddress();

    // Update UI after connection
    document.getElementById("connectButton").textContent = "Connected";
    document.getElementById("connectButton").disabled = true;
    document.getElementById("disconnectButton").style.display = "inline-block";
    document.getElementById("walletAddress").textContent = `Connected: ${userAddress}`;

    await initContract();
    await loadUsername();
    await loadGoals();
  } else {
    alert("Please install MetaMask.");
  }
}

// Disconnect wallet (reloads the page)
function disconnectWallet() {
  window.location.reload();
  alert("Wallet disconnected.");
}

// Load ABI and create contract instance
async function initContract() {
  const res = await fetch("abi.json");
  const abi = await res.json();
  contract = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);
}

// Set a username via the smart contract
async function setUsername() {
  const name = document.getElementById("usernameInput").value;
  if (!name) return alert("Username cannot be empty");
  const tx = await contract.setUsername(name);
  await tx.wait();
  alert("Username set!");
  await loadUsername();
}

// Load username from contract and update welcome message
async function loadUsername() {
  const res = await fetch("abi.json");
  const abi = await res.json();
  const readContract = new ethers.Contract(CONTRACT_ADDRESS, abi, provider);
  const name = await readContract.getUsername(userAddress);

  if (name && name.trim()) {
    document.getElementById("welcomeMessage").textContent = `Welcome, ${name}! Ready to pump up your savings?`;
  } else {
    document.getElementById("welcomeMessage").textContent = `Welcome! Set a username to personalize your dashboard.`;
  }
}

// Create a new savings goal
async function createGoal() {
  const name = document.getElementById("goalName").value;
  const desc = document.getElementById("goalDesc").value;
  const amount = document.getElementById("goalAmount").value;

  if (!name || !desc || !amount) {
    alert("All fields are required");
    return;
  }

  const target = ethers.parseEther(amount);
  const tx = await contract.createGoal(target, name, desc);
  await tx.wait();
  alert("Goal Created!");
  await loadGoals();
}

// Deposit ETH into a specific goal
async function deposit(goalId) {
  const eth = prompt("Enter ETH to deposit:");
  if (!eth) return;
  const tx = await contract.deposit(goalId, { value: ethers.parseEther(eth) });
  await tx.wait();
  await loadGoals();
}

// Withdraw from a completed goal
async function withdraw(goalId) {
  const tx = await contract.withdraw(goalId);
  await tx.wait();
  alert("Funds Withdrawn!");
  await loadGoals();
}

// Load and render all goals, separating completed and incomplete
async function loadGoals() {
  const res = await fetch("abi.json");
  const abi = await res.json();
  const readContract = new ethers.Contract(CONTRACT_ADDRESS, abi, provider);
  const goals = await readContract.getAllGoals(userAddress);

  const incompleteContainer = document.getElementById("incompleteGoalsList");
  const completedContainer = document.getElementById("completedGoalsList");
  incompleteContainer.innerHTML = "";
  completedContainer.innerHTML = "";

  goals.forEach((goal, i) => {
    const isWithdrawn = goal.targetReached && goal.amountSaved === 0n;
    const isCompleted = goal.targetReached;

    const div = document.createElement("div");
    div.classList.add("goal-item");
    div.innerHTML = `
      <h3>${goal.name}</h3>
      <p>${goal.description}</p>
      <p>Saved: ${ethers.formatEther(goal.amountSaved)} / ${ethers.formatEther(goal.targetAmount)} ETH</p>
      <p>Status: ${goal.targetReached ? (isWithdrawn ? "✅ Withdrawn" : "✅ Target reached") : "⏳ In progress"}</p>
      ${!goal.targetReached ? `<button onclick="deposit(${i})">Deposit</button>` : ""}
      ${goal.targetReached && !isWithdrawn ? `<button onclick="withdraw(${i})">Withdraw</button>` : ""}
    `;

    if (isCompleted) {
      completedContainer.appendChild(div);
    } else {
      incompleteContainer.appendChild(div);
    }
  });
}

// Toggle visibility of the completed goals section
function toggleCompletedGoals() {
  const container = document.getElementById("completedGoalsContainer");
  const btn = document.getElementById("toggleCompletedBtn");

  if (container.style.display === "none") {
    container.style.display = "flex";
    btn.textContent = "Hide Completed Goals";
  } else {
    container.style.display = "none";
    btn.textContent = "Show Completed Goals";
  }
}

// Button listeners once DOM is ready
window.addEventListener("DOMContentLoaded", () => {
  document.getElementById("connectButton").onclick = connectWallet;
  document.getElementById("disconnectButton").onclick = disconnectWallet;
  document.getElementById("createGoalButton").onclick = createGoal;
  document.getElementById("setUsernameButton").onclick = setUsername;
});

// Open the modal to set username
document.getElementById("openUsernameModalButton").onclick = () => {
  document.getElementById("usernameModal").style.display = "flex";
};

// Close the username modal
document.getElementById("closeUsernameModalButton").onclick = () => {
  document.getElementById("usernameModal").style.display = "none";
};

// Set the username from modal input
document.getElementById("confirmUsernameButton").onclick = async () => {
  const name = document.getElementById("usernameInput").value.trim();
  if (!name) return alert("Please enter a username");

  const tx = await contract.setUsername(name);
  await tx.wait();

  document.getElementById("usernameModal").style.display = "none";
  alert("Username set!");
  await loadUsername();
};