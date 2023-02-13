package videoindexersamples.HttpUtils;

import com.google.gson.JsonSyntaxException;
import com.google.gson.internal.Primitives;
import com.google.gson.reflect.TypeToken;

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

    public static String toQueryParamString(Map<String,String> map){
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

    public static HttpResponse<String> httpStringResponse(HttpRequest httpRequest) throws IOException, InterruptedException {
        return HttpClient.
                newBuilder().
                build().
                send(httpRequest, HttpResponse.BodyHandlers.ofString());
    }

}
