package petoboto.api;

import java.net.URI;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

@Path("")
public class RootResource {
    
    @GET
    public Response get() {
        var uri = URI.create("/api/pets");
        return Response.status(Response.Status.FOUND)
                       .location(uri)
                       .build();
    }
}
