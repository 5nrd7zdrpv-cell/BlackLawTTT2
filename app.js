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
const playerViewName = document.getElementById("player-view-name");
const playerViewRole = document.getElementById("player-view-role");
const playerViewDescription = document.getElementById("player-view-description");
const playerViewStatus = document.getElementById("player-view-status");
const playerViewAvatar = document.getElementById("player-view-avatar");
const playerViewStats = document.getElementById("player-view-stats");
const focusPlayerButton = document.getElementById("focus-player");
const messagePlayerButton = document.getElementById("message-player");

const state = {
  players: [],
  roles: new Map(),
  phase: "Tag",
  events: [],
  selectedPlayer: null,
};

const rolePool = {
  innocent: { name: "Unschuldiger", description: "Versucht zu überleben." },
  traitor: { name: "Verräter", description: "Täuscht die Gruppe und stiftet Chaos." },
};

const renderEventLog = () => {
  eventLog.innerHTML = "";
  [...state.events].reverse().forEach((message) => {
    const entry = document.createElement("li");
    entry.textContent = message;
    eventLog.appendChild(entry);
  });
};

const logEvent = (message) => {
  state.events.push(message);
  renderEventLog();
};

const renderPlayers = () => {
  playerList.innerHTML = "";
  state.players.forEach((player) => {
    const item = document.createElement("li");
    item.className = "player-row";
    if (player === state.selectedPlayer) {
      item.classList.add("is-active");
    }

    const selectButton = document.createElement("button");
    selectButton.type = "button";
    selectButton.className = "player-select";
    selectButton.textContent = player;
    selectButton.addEventListener("click", () => selectPlayer(player));

    const removeButton = document.createElement("button");
    removeButton.type = "button";
    removeButton.className = "player-remove";
    removeButton.textContent = "Entfernen";
    removeButton.addEventListener("click", () => removePlayer(player));

    item.appendChild(selectButton);
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

const getInitials = (name) => {
  const parts = name.split(" ").filter(Boolean);
  const initials = parts.slice(0, 2).map((part) => part[0]?.toUpperCase() ?? "");
  return initials.join("") || "--";
};

const renderPlayerViewStats = (player) => {
  const playerIndex = state.players.indexOf(player) + 1;
  const traitorCount = getTraitorCount(state.players.length);
  const innocentCount = Math.max(state.players.length - traitorCount, 0);
  const stats = [
    { label: "Spieler-ID", value: playerIndex ? `#${playerIndex}` : "-" },
    { label: "Rundenstatus", value: state.roles.size ? "Aktiv" : "Lobby" },
    { label: "Verräter", value: traitorCount.toString() },
    { label: "Unschuldige", value: innocentCount.toString() },
  ];

  playerViewStats.innerHTML = "";
  stats.forEach(({ label, value }) => {
    const card = document.createElement("div");
    card.className = "stat-card";
    card.innerHTML = `<p>${label}</p><strong>${value}</strong>`;
    playerViewStats.appendChild(card);
  });
};

const renderPlayerView = () => {
  if (!state.selectedPlayer) {
    playerViewName.textContent = "Keine Auswahl";
    playerViewRole.textContent = "Rolle: -";
    playerViewDescription.textContent = "Wähle einen Spieler aus der Liste, um Details zu sehen.";
    playerViewStatus.textContent = "Lobby";
    playerViewAvatar.textContent = "--";
    playerViewStats.innerHTML = "";
    return;
  }

  const role = state.roles.get(state.selectedPlayer);
  const roleName = role ? role.name : "Unbekannt";
  const roleDescription = role
    ? role.description
    : "Rolle wird beim Start des Spiels zugewiesen.";

  playerViewName.textContent = state.selectedPlayer;
  playerViewRole.textContent = `Rolle: ${roleName}`;
  playerViewDescription.textContent = roleDescription;
  playerViewStatus.textContent = state.roles.size ? "Im Einsatz" : "Lobby";
  playerViewAvatar.textContent = getInitials(state.selectedPlayer);
  renderPlayerViewStats(state.selectedPlayer);
};

const selectPlayer = (name) => {
  state.selectedPlayer = name;
  renderPlayers();
  renderPlayerView();
};

const addPlayer = (name) => {
  if (!name || state.players.includes(name)) {
    return;
  }
  state.players.push(name);
  if (!state.selectedPlayer) {
    state.selectedPlayer = name;
  }
  logEvent(`Spieler hinzugefügt: ${name}`);
  renderPlayers();
  renderPlayerView();
};

const removePlayer = (name) => {
  state.players = state.players.filter((player) => player !== name);
  state.roles.delete(name);
  if (state.selectedPlayer === name) {
    state.selectedPlayer = state.players[0] ?? null;
  }
  logEvent(`Spieler entfernt: ${name}`);
  renderPlayers();
  renderRoles();
  renderPlayerView();
};

const shuffle = (items) => {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
};

const getTraitorCount = (playerCount) => {
  if (playerCount < 3) {
    return 0;
  }
  const calculated = Math.max(1, Math.floor(playerCount / 4));
  return Math.min(calculated, playerCount - 1);
};

const assignRoles = () => {
  state.roles.clear();
  const shuffledPlayers = shuffle(state.players);
  const traitorCount = getTraitorCount(shuffledPlayers.length);
  const roleDistribution = shuffledPlayers.map((player, index) => ({
    player,
    role: index < traitorCount ? rolePool.traitor : rolePool.innocent,
  }));

  roleDistribution.forEach(({ player, role }) => {
    state.roles.set(player, role);
  });

  const innocentCount = shuffledPlayers.length - traitorCount;
  logEvent(
    `Rollen verteilt: ${traitorCount} Verräter, ${innocentCount} Unschuldige.`,
  );
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
  renderPlayerView();
};

const resetGame = () => {
  state.players = [];
  state.roles.clear();
  state.phase = "Tag";
  state.events = [];
  state.selectedPlayer = null;
  statusText.textContent = "Warte auf Spieler";
  phaseStatus.textContent = state.phase;
  renderPlayers();
  renderRoles();
  renderPlayerView();
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
focusPlayerButton.addEventListener("click", () => {
  if (!state.selectedPlayer) {
    logEvent("Bitte zuerst einen Spieler auswählen.");
    return;
  }
  logEvent(`Spieler fokussiert: ${state.selectedPlayer}.`);
});

messagePlayerButton.addEventListener("click", () => {
  if (!state.selectedPlayer) {
    logEvent("Bitte zuerst einen Spieler auswählen.");
    return;
  }
  logEvent(`Nachricht gesendet an ${state.selectedPlayer}.`);
});

renderPlayers();
renderRoles();
renderPlayerView();
logEvent("Gerüst geladen. Spieler hinzufügen, um zu starten.");
