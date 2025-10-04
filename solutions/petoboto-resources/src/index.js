document.addEventListener("DOMContentLoaded", () => {
  fetch("/api/pets")
    .then((response) => response.json())
    .then(loadPets);
});

function loadPets(pets) {
  const content = document.getElementById("content");
  pets.forEach((pet) => {
    const slug = "pet.html?id=" + pet.id
    const petCard = document.createElement("div");
    petCard.className = "pet-card";
    petCard.innerHTML = `
      <h1><a href="${slug}">${pet.name}</a></h1>
      <h2>${pet.kind}</h2>
      <a href="${slug}"><img src="/images/pets/${pet.name.toLowerCase()}/${pet.pictures[0]}" alt="Image of ${pet.name}" /></a>
    `;
    content.appendChild(petCard);
  });
}
