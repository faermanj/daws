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

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Pet> getList() {
        List<Pet> result = Pet.listAll();
        return result;
    }

    @GET
    @Path("/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public Pet getOne(@PathParam("id") Long id) {
        Pet pet = Pet.findById(id);
        if (pet == null) throw new NotFoundException();
        return pet;
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    public Response create(Pet pet) {
        pet.id = null; 
        pet.persist();
        return Response.status(Status.CREATED).entity(pet).build();
    }

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
