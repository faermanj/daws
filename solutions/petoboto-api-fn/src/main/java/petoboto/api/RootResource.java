package petoboto.api;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("")
public class RootResource {
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String ok() {
        return "OK";
    }
}
