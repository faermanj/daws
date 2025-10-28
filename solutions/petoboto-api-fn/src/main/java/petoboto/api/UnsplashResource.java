package petoboto.api;

import java.net.HttpURLConnection;
import java.net.URI;

import jakarta.json.Json;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/unsplash")
public class UnsplashResource {

    // Avoid hard coding sensitive data such as API keys
    private static final String UNSPLASH_ACCESS_KEY = System.getenv("UNSPLASH_ACCESS_KEY");

    @GET
    @Produces(MediaType.TEXT_HTML)
    public Response getPetImages() {
        if (UNSPLASH_ACCESS_KEY == null || UNSPLASH_ACCESS_KEY.isEmpty()) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\":\"Missing Unsplash access key\"}")
                    .build();
        }
        try {
            var apiUrl = "https://api.unsplash.com/search/photos?query=pet&per_page=3&client_id=" + UNSPLASH_ACCESS_KEY;
            var url = URI.create(apiUrl).toURL();
            var conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(60000);
            conn.setReadTimeout(60000);
            conn.connect();

            var responseCode = conn.getResponseCode();
            if (responseCode != 200) {
                return Response.status(responseCode)
                        .entity("{\"error\":\"Failed to fetch images\"}")
                        .build();
            }

            var responseBody = new String(conn.getInputStream().readAllBytes());
            var reader = Json.createReader(new java.io.StringReader(responseBody));
            var json = reader.readObject();
            var results = json.getJsonArray("results");
            return Response.ok(buildHtml(results)).build();
        } catch (Exception e) {
            e.printStackTrace();
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("{\"error\":\"" + e.getMessage() + "\"}")
                    .build();
        }
    }

    private String buildHtml(jakarta.json.JsonArray results) {
        var html = new StringBuilder();
        html.append("<html><head><title>Pet Photos</title><style>body{background:#f7f7fa;font-family:sans-serif;color:#222;}h1{color:#4a90e2;} .card{background:#fff;border-radius:8px;box-shadow:0 2px 8px #0001;display:inline-block;margin:16px;padding:12px;text-align:center;width:320px;} .card img{border-radius:6px;max-width:100%;max-height:220px;} .alt{font-size:1.1em;color:#555;margin-top:8px;}</style></head><body><h1>Pet Photos from Unsplash</h1>");
        for (var i = 0; i < results.size(); i++) {
            html.append(buildPhotoCard(results.getJsonObject(i)));
        }
        html.append("</body></html>");
        return html.toString();
    }

    private String buildPhotoCard(jakarta.json.JsonObject photo) {
        var imgUrl = photo.getJsonObject("urls").getString("small", "");
        var alt = photo.containsKey("alt_description") ? photo.getString("alt_description") : "pet photo";
        return "<div class='card'><img src='" + imgUrl + "' alt='" + alt + "'/><div class='alt'>" + alt + "</div></div>";
    }
}