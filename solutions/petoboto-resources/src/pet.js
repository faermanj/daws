const { fetchPets, toFolderName, findPetByIdentifier } = window.PetsAPI;

document.addEventListener("DOMContentLoaded", () => {
  renderPetPage().catch((error) => {
    console.error("Failed to render pet page", error);
    showStatus("We couldn't load this pet right now. Please try again later.", true);
  });
});

async function renderPetPage() {
  const identifier = new URLSearchParams(window.location.search).get("pet");

  if (!identifier) {
    showStatus("Missing pet identifier in the page URL.", true);
    return;
  }

  const pets = await fetchPets();
  const pet = findPetByIdentifier(pets, identifier);

  if (!pet) {
    showStatus("We couldn't find that pet.", true);
    return;
  }

  updatePageMetadata(pet);
  renderPetInformation(pet);
  renderGallery(pet);
}

function updatePageMetadata(pet) {
  if (pet.name) {
    document.title = `${pet.name} — Pet Details`;
  }
}

function renderPetInformation(pet) {
  const nameEl = document.getElementById("pet-name");
  const kindEl = document.getElementById("pet-kind");
  const statusEl = document.getElementById("pet-status");

  nameEl.textContent = pet.name || "Unnamed friend";
  if (pet.kind) {
    kindEl.textContent = formatKindLabel(pet.kind);
    kindEl.hidden = false;
  } else {
    kindEl.hidden = true;
  }

  if (statusEl) {
    statusEl.hidden = true;
    statusEl.textContent = "";
  }
}

function renderGallery(pet) {
  const galleryEl = document.getElementById("pet-gallery");
  galleryEl.innerHTML = "";

  const pictures = Array.isArray(pet.pictures) ? pet.pictures : [];
  const folder = toFolderName(pet.name);

  if (pictures.length === 0) {
    showStatus("No photos yet. Check back soon!");
    return;
  }

  pictures.forEach((filename, index) => {
    const figure = document.createElement("figure");
    figure.className = "pet-detail__photo";

    const img = document.createElement("img");
    img.src = `images/pets/${folder}/${filename}`;
    img.alt = pet.name ? `${pet.name} photo ${index + 1}` : `Pet photo ${index + 1}`;
    img.loading = index === 0 ? "eager" : "lazy";

    figure.appendChild(img);
    galleryEl.appendChild(figure);
  });
}

function showStatus(message, isError = false) {
  const statusEl = document.getElementById("pet-status");
  if (!statusEl) return;

  statusEl.textContent = message;
  statusEl.hidden = false;
  statusEl.classList.toggle("pet-message--error", Boolean(isError));
}

function formatKindLabel(kind) {
  return String(kind).toLowerCase().replace(/(^|\s)\w/g, (letter) => letter.toUpperCase());
}
