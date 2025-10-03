const { fetchPets, toFolderName } = window.PetsAPI;

function createImageElement(pet) {
  const img = document.createElement("img");
  const pictures = Array.isArray(pet.pictures) ? pet.pictures : [];
  const [primaryPicture] = pictures;
  const folderName = toFolderName(pet.name);
  const kindLabel = typeof pet.kind === "string" ? pet.kind.toLowerCase() : "pet";

  if (primaryPicture) {
    img.src = `images/pets/${folderName}/${primaryPicture}`;
  }

  img.alt = pet.name ? `${pet.name} the ${kindLabel}` : "Pet image";
  img.loading = "lazy";

  return img;
}

function createCard(pet) {
  const cardLink = document.createElement("a");
  cardLink.className = "pet-card";
  const identifier = pet.id ?? toFolderName(pet.name);
  cardLink.href = `pet.html?pet=${encodeURIComponent(identifier)}`;
  cardLink.setAttribute("data-pet-id", identifier);

  const figure = document.createElement("figure");
  figure.className = "pet-card__media";
  figure.appendChild(createImageElement(pet));

  const title = document.createElement("h2");
  title.className = "pet-card__title";
  title.textContent = pet.name || "Unknown";

  const subtitle = document.createElement("p");
  subtitle.className = "pet-card__kind";
  subtitle.textContent = typeof pet.kind === "string" ? pet.kind.toLowerCase() : "";

  cardLink.appendChild(figure);
  cardLink.appendChild(title);
  if (subtitle.textContent) {
    cardLink.appendChild(subtitle);
  }

  return cardLink;
}

async function loadPets() {
  const container = document.getElementById("content");
  container.classList.add("pet-gallery");
  container.innerHTML = "";

  try {
    const pets = await fetchPets();

    if (!Array.isArray(pets) || pets.length === 0) {
      container.innerHTML = '<p class="pet-message">No pets available right now.</p>';
      return;
    }

    pets.forEach((pet, index) => {
      const card = createCard(pet);
      card.style.setProperty("--pet-card-delay", `${index * 0.08}s`);
      container.appendChild(card);
    });
  } catch (error) {
    console.error("Failed to load pets", error);
    container.innerHTML = `<p class="pet-message pet-message--error">We couldn't load the pets. Please try again later.</p>`;
  }
}

document.addEventListener("DOMContentLoaded", loadPets);
