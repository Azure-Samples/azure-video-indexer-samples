package apisamples.HttpUtils;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Map;

public class Utils {
    public static final int HTTP_OK = 200;
    public static final int NO_CONTENT = 204;

    public static String toQueryParamString(Map<String, String> map) {
        return map.entrySet().stream()
                .map(p -> urlEncodeUTF8(p.getKey()) + "=" + urlEncodeUTF8(p.getValue()))
                .reduce((p1, p2) -> p1 + "&" + p2).orElse("");
    }

    public static String urlEncodeUTF8(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    public static HttpRequest httpGetRequest(String uriRequest) throws URISyntaxException {
        return HttpRequest.newBuilder()
                .uri(new URI(uriRequest))
                .headers("Content-Type", "application/json;charset=UTF-8")
                .GET()
                .build();
    }
    public static HttpRequest httpGetRequestWithBearer(String uriRequest,String token) throws URISyntaxException {
        return HttpRequest.newBuilder()
                .uri(new URI(uriRequest))
                .headers("Content-Type", "application/json;charset=UTF-8")
                .headers("Authorization", "Bearer " + token)
                .GET()
                .build();
    }

    public static HttpResponse<String> httpStringResponse(HttpRequest httpRequest) throws IOException, InterruptedException {
        var response = HttpClient
                .newBuilder()
                .build()
                .send(httpRequest, HttpResponse.BodyHandlers.ofString());
        VerifyStatus(response, HTTP_OK);
        return response;
    }

    public static void VerifyStatus(HttpResponse response, int expectedResult) {
        if (response.statusCode() != expectedResult) {
            throw new RuntimeException(response.toString());
        }
    }
}
