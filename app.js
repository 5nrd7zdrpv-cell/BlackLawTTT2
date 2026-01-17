const playerForm = document.getElementById("player-form");
const playerNameInput = document.getElementById("player-name");
const playerList = document.getElementById("player-list");
const rolesContainer = document.getElementById("roles");
const startGameButton = document.getElementById("start-game");
const resetGameButton = document.getElementById("reset-game");
const statusText = document.getElementById("game-status");
const phaseStatus = document.getElementById("phase-status");
const togglePhaseButton = document.getElementById("toggle-phase");
const eventLog = document.getElementById("event-log");

const state = {
  players: [],
  roles: new Map(),
  phase: "Tag",
};

const rolePool = [
  { name: "Innocent", description: "Versucht zu überleben." },
  { name: "Traitor", description: "Sabotiert die Gruppe." },
  { name: "Detective", description: "Findet Hinweise." },
];

const logEvent = (message) => {
  const entry = document.createElement("li");
  entry.textContent = message;
  eventLog.prepend(entry);
};

const renderPlayers = () => {
  playerList.innerHTML = "";
  state.players.forEach((player) => {
    const item = document.createElement("li");
    item.textContent = player;

    const removeButton = document.createElement("button");
    removeButton.textContent = "Entfernen";
    removeButton.addEventListener("click", () => removePlayer(player));

    item.appendChild(removeButton);
    playerList.appendChild(item);
  });
};

const renderRoles = () => {
  rolesContainer.innerHTML = "";
  if (state.roles.size === 0) {
    rolesContainer.innerHTML = "<p class=\"helper\">Noch keine Rollen vergeben.</p>";
    return;
  }

  state.roles.forEach((role, player) => {
    const card = document.createElement("div");
    card.className = "role-card";
    card.innerHTML = `<strong>${player}</strong><p>${role.name}</p><small>${role.description}</small>`;
    rolesContainer.appendChild(card);
  });
};

const addPlayer = (name) => {
  if (!name || state.players.includes(name)) {
    return;
  }
  state.players.push(name);
  logEvent(`Spieler hinzugefügt: ${name}`);
  renderPlayers();
};

const removePlayer = (name) => {
  state.players = state.players.filter((player) => player !== name);
  state.roles.delete(name);
  logEvent(`Spieler entfernt: ${name}`);
  renderPlayers();
  renderRoles();
};

const shuffle = (items) => {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
};

const assignRoles = () => {
  state.roles.clear();
  const shuffledPlayers = shuffle(state.players);
  const roleDistribution = shuffledPlayers.map((player, index) => {
    if (index === 0 && shuffledPlayers.length >= 3) {
      return { player, role: rolePool[2] };
    }
    if (index === 1 && shuffledPlayers.length >= 4) {
      return { player, role: rolePool[1] };
    }
    return { player, role: rolePool[0] };
  });

  roleDistribution.forEach(({ player, role }) => {
    state.roles.set(player, role);
  });
};

const startGame = () => {
  if (state.players.length < 3) {
    logEvent("Mindestens 3 Spieler benötigt, um zu starten.");
    return;
  }
  assignRoles();
  statusText.textContent = "Spiel läuft";
  logEvent("Spiel gestartet. Rollen wurden vergeben.");
  renderRoles();
};

const resetGame = () => {
  state.players = [];
  state.roles.clear();
  state.phase = "Tag";
  statusText.textContent = "Warte auf Spieler";
  phaseStatus.textContent = state.phase;
  eventLog.innerHTML = "";
  renderPlayers();
  renderRoles();
  logEvent("Spiel zurückgesetzt.");
};

const togglePhase = () => {
  state.phase = state.phase === "Tag" ? "Nacht" : "Tag";
  phaseStatus.textContent = state.phase;
  logEvent(`Phase gewechselt zu ${state.phase}.`);
};

playerForm.addEventListener("submit", (event) => {
  event.preventDefault();
  addPlayer(playerNameInput.value.trim());
  playerNameInput.value = "";
});

startGameButton.addEventListener("click", startGame);
resetGameButton.addEventListener("click", resetGame);
togglePhaseButton.addEventListener("click", togglePhase);

renderPlayers();
renderRoles();
logEvent("Gerüst geladen. Spieler hinzufügen, um zu starten.");
