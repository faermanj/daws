package daws.api;

import java.net.URI;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

@Path("")
public class RootResource {
    
    @GET
    public Response get() {
        // redirect to relative uri /pets
        var uri = URI.create("/pets");
        return Response.status(Response.Status.FOUND)
                       .location(uri)
                       .build();
    }
}
