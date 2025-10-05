package petoboto.api;

import java.util.List;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import static petoboto.api.PetKind.*;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.json.JsonObject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.BadRequestException;

@ApplicationScoped
public class PetResource {

    @Transactional
    public void init(@Observes StartupEvent ev) {
        List<Pet> all = Pet.listAll();
        if (!all.isEmpty()) 
            return;
        Pet.create("Sushi", DOG, List.of("sushi-1.png", "sushi-2.png", "sushi-3.png"));
        Pet.create("Tuna", CAT, List.of("tuna-1.png", "tuna-2.png", "tuna-3.png"));
        Pet.create("Taco", BIRD, List.of("taco-1.png", "taco-2.png", "taco-3.png"));
    }

    //TODO: add a comment for each method, including an CURL line of how to invoke it as shortly as possible, use http://127.0.0.1:8080/pets as base url
    
    /** Lists all pets.
     * curl -s http://127.0.0.1:8080/pets | jq 
     */
    @Path("/pets")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Pet> getList() {
        List<Pet> result = Pet.listAll();
        return result;
    }

    /** Retrieves a pet by id.
     * curl -s http://127.0.0.1:8080/pets/1 | jq
     */
    @GET
    @Path("/pet/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public Pet getOne(@PathParam("id") Long id) {
        Pet pet = Pet.findById(id);
        if (pet == null) throw new NotFoundException();
        return pet;
    }

    /** Creates a new pet.
     * curl -X POST http://127.0.0.1:8080/pets -H 'Content-Type: application/json' -d '{"name":"Sushi","species":"DOG"}'
     */
    @POST
    @Path("/pet/{id}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    public Response create(JsonObject request) {
        var name = request.getString("name");
        var species = request.getString("species");
        Pet pet = new Pet();
        pet.setName(name);
        pet.setKind(parseSpecies(species));
        pet.persist();
        return Response.status(Status.CREATED).entity(pet).build();
    }

    private PetKind parseSpecies(String species) {
        String normalized = species.trim().toUpperCase();
        if (normalized.isEmpty()) {
            throw new BadRequestException("species must not be empty");
        }
        try {
            return PetKind.valueOf(normalized);
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("unknown species " + species);
        }
    }

    /** Updates an existing pet.
     * curl -X PUT http://127.0.0.1:8080/pets/1 -H 'Content-Type: application/json' -d '{"name":"Sushi","kind":"DOG"}'
     */
    @PUT
    @Path("/pet/{id}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    public Pet update(@PathParam("id") Long id, Pet updated) {
        Pet pet = Pet.findById(id);
        if (pet == null) throw new NotFoundException();
        pet.setName(updated.getName());
        pet.setKind(updated.getKind());
        pet.setPictures(updated.getPictures());
        return pet;
    }

    /** Deletes a pet by id.
     * curl -X DELETE http://127.0.0.1:8080/pets/1
     */
    @DELETE
    @Path("/pet/{id}")
    @Transactional
    public Response delete(@PathParam("id") Long id) {
        Pet pet = Pet.findById(id);
        if (pet == null) throw new NotFoundException();
        pet.delete();
        return Response.noContent().build();
    }

}
