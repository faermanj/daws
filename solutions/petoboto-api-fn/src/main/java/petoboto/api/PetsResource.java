package petoboto.api;

import static petoboto.api.PetKind.BIRD;
import static petoboto.api.PetKind.CAT;
import static petoboto.api.PetKind.DOG;

import java.util.List;

import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@ApplicationScoped
@Path("/pets")
public class PetsResource {

    @Transactional
    public synchronized void init(@Observes StartupEvent ev) {
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
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<Pet> getList() {
        List<Pet> result = Pet.listAll();
        return result;
    }

    /** Delete all pets.
     * curl -X DELETE http://127.0.0.1:8080/pets
     */
    @Transactional
    public void deleteAll() {
        Pet.deleteAll();
        
    }

}
