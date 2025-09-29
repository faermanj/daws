package daws.api;

import java.util.List;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import static daws.api.PetKind.*;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;

@ApplicationScoped
@Path("/pets")
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
     * curl http://127.0.0.1:8080/pets
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Pet> getList() {
        List<Pet> result = Pet.listAll();
        return result;
    }

    /** Retrieves a pet by id.
     * curl http://127.0.0.1:8080/pets/1
     */
    @GET
    @Path("/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public Pet getOne(@PathParam("id") Long id) {
        Pet pet = Pet.findById(id);
        if (pet == null) throw new NotFoundException();
        return pet;
    }

    /** Creates a new pet.
     * curl -X POST http://127.0.0.1:8080/pets -H 'Content-Type: application/json' -d '{"name":"Sushi","kind":"DOG"}'
     */
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    public Response create(Pet pet) {
        pet.id = null; 
        pet.persist();
        return Response.status(Status.CREATED).entity(pet).build();
    }

    /** Updates an existing pet.
     * curl -X PUT http://127.0.0.1:8080/pets/1 -H 'Content-Type: application/json' -d '{"name":"Sushi","kind":"DOG"}'
     */
    @PUT
    @Path("/{id}")
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
    @Path("/{id}")
    @Transactional
    public Response delete(@PathParam("id") Long id) {
        Pet pet = Pet.findById(id);
        if (pet == null) throw new NotFoundException();
        pet.delete();
        return Response.noContent().build();
    }
}
