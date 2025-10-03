(function initializePetsAPI(global) {
  const SAMPLE_PETS = [
    {
      id: 1,
      name: "Sushi",
      kind: "DOG",
      pictures: ["sushi-1.png", "sushi-2.png", "sushi-3.png"],
    },
    {
      id: 2,
      name: "Tuna",
      kind: "CAT",
      pictures: ["tuna-1.png", "tuna-2.png", "tuna-3.png"],
    },
    {
      id: 3,
      name: "Taco",
      kind: "BIRD",
      pictures: ["taco-1.png", "taco-2.png", "taco-3.png"],
    },
  ];

  function isFileProtocol() {
    return global.location?.protocol === "file:";
  }

  async function fetchPets() {
    if (isFileProtocol()) {
      console.warn(
        "Running from the local file system. Serving bundled sample data; start a local HTTP server to hit the real API."
      );
      return SAMPLE_PETS;
    }

    const response = await fetch("api/pets");
    if (!response.ok) {
      throw new Error(`Request failed with status ${response.status}`);
    }

    try {
      return await response.json();
    } catch (error) {
      throw new Error("Invalid JSON response from pets API");
    }
  }

  function toFolderName(name) {
    return (name || "")
      .trim()
      .toLowerCase()
      .replace(/\s+/g, "-");
  }

  function findPetByIdentifier(pets, identifier) {
    if (!identifier) return undefined;

    const numericId = Number(identifier);
    if (!Number.isNaN(numericId)) {
      const byId = pets.find((pet) => Number(pet.id) === numericId);
      if (byId) {
        return byId;
      }
    }

    const slug = toFolderName(identifier);
    return pets.find((pet) => toFolderName(pet.name) === slug);
  }

  global.PetsAPI = {
    fetchPets,
    toFolderName,
    findPetByIdentifier,
    getSamplePets: () => SAMPLE_PETS.slice(),
  };
})(window);
