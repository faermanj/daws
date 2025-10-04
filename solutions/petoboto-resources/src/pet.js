document.addEventListener("DOMContentLoaded", () => {
  const urlParams = new URLSearchParams(window.location.search);
  const petId = urlParams.get("id");
  
  if (!petId) {
    document.body.innerHTML = "<p>Pet not found</p>";
    return;
  }

  fetch("/api/pet/" + petId)
    .then(response => response.json())
    .then(loadPet);
});

function loadPet(pet) {
  document.title = `${pet.name} - Pet Details`;
  
  const gallery = pet.pictures.map(pic => 
    `<img src="/images/pets/${pet.name.toLowerCase()}/${pic}" alt="${pet.name}">`
  ).join("");

  document.body.innerHTML = `
    <div style="max-width: 800px; margin: 2rem auto; padding: 0 1rem; text-align: center;">
      <a href="index.html" style="color: #666; text-decoration: none; margin-bottom: 1rem; display: inline-block;">&larr; Back to gallery</a>
      <h1>${pet.name}</h1>
      <h2>${pet.kind}</h2>
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-top: 2rem;">
        ${gallery}
      </div>
    </div>
  `;
}
