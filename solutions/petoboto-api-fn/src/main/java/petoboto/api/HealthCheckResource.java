package petoboto.api;

import java.util.Map;

import javax.sql.DataSource;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@ApplicationScoped
@Path("/_hc")
public class HealthCheckResource {
    private static final int DATABASE_TIMEOUT_SECONDS = 10;

    @Inject
    DataSource ds;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, String> check() {
        var healthMap = Map.of(
            "isDatabaseValid", isDatabaseValid()
        );
        return healthMap;
    }

    private String isDatabaseValid() {
        try (var conn = ds.getConnection();) {
            if (!conn.isValid(DATABASE_TIMEOUT_SECONDS)){
                return "INVALID";
            }    
            return "VALID";
        } catch (Exception e) { 
            return "ERROR: " + e.getMessage();
        }
    }
}
