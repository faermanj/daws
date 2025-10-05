package petoboto.api;

import jakarta.enterprise.context.RequestScoped;
import jakarta.json.JsonObject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;

@RequestScoped
@Path("/pet/{id}")
public class PetResource {
    
    /** Retrieves a pet by id.
     * curl -s http://127.0.0.1:8080/pets/1 | jq
     */
    @GET
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
    @Transactional
    public Response delete(@PathParam("id") Long id) {
        Pet pet = Pet.findById(id);
        if (pet == null) throw new NotFoundException();
        pet.delete();
        return Response.noContent().build();
    }
}
