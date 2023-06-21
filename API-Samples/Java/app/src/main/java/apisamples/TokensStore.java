package apisamples;

import apisamples.authentication.AccessTokenRequest;
import apisamples.authentication.AccessTokenResponse;
import apisamples.authentication.ArmAccessTokenPermission;
import apisamples.authentication.ArmAccessTokenScope;
import com.azure.core.credential.AccessToken;
import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.LoadingCache;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.http.HttpRequest;
import java.text.MessageFormat;
import java.util.Objects;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

import static apisamples.HttpUtils.Utils.httpStringResponse;
import static apisamples.VideoIndexerClient.*;

public class TokensStore {

    private final LoadingCache<String, TimedEntry> cache;
    private static final String armAccessTokenKey = "armAccessToken";
    private static final String viAccountTokenKey = "viAccountToken";

    private final Gson gson;
    private final ArmAccessTokenPermission permission;
    private final ArmAccessTokenScope scope;


    public TokensStore(ArmAccessTokenPermission permission, ArmAccessTokenScope scope) {
        this.cache = Caffeine.newBuilder()
                .build(key -> new TimedEntry(key, 0, TimeUnit.MILLISECONDS));
        this.gson = new GsonBuilder().setPrettyPrinting().create();
        this.permission = permission;
        this.scope = scope;
        //Generate the First ARM + VI Access Token
        this.generateVIAccessToken();
    }


    /**
     * TimedEntry represents an expiry enabled cache item to be placed in the Loading Cache lib
     */
    private class TimedEntry {
        long expiryTime;
        String value;
        public TimedEntry(String value, long duration, TimeUnit unit) {
            this.value = value;
            this.expiryTime = System.currentTimeMillis() + unit.toMillis(duration);
        }
        public TimedEntry(String value, long expiryTimeEpocMillisec) {
            this.value = value;
            this.expiryTime = expiryTimeEpocMillisec;
        }
        public boolean isExpired() {
            return System.currentTimeMillis() > expiryTime;
        }
    }

    public String getArmAccessToken() {
        return this.getOrCreate(armAccessTokenKey, this::generateArmAccessToken, 55, TimeUnit.MINUTES);
    }

    public String getVIAccessToken() {
        return this.getOrCreate(viAccountTokenKey, this::generateVIAccessToken, 55, TimeUnit.MINUTES);
    }

    public String getOrCreate(String key, Supplier<TimedEntry> valueSupplier, long duration, TimeUnit unit) {
        TimedEntry timedEntry = cache.getIfPresent(key);
        if (timedEntry == null || timedEntry.isExpired()) {
            timedEntry = valueSupplier.get();
            cache.put(key, timedEntry);
        }
        return timedEntry.value;
    }

    /**
     * Generate new Arm Access Token
     * @return the Arm Access Token
     */
    private TimedEntry generateArmAccessToken() {

        var tokenRequestContext = new TokenRequestContext();
        tokenRequestContext.addScopes(String.format("%s/.default", AzureResourceManager));

        DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder().build();
        AccessToken accessToken = Objects.requireNonNull(defaultCredential.getToken(tokenRequestContext).block());
        var odt = accessToken.getExpiresAt();
        long epochNanoExpiry = odt.toInstant().toEpochMilli();
        return new TimedEntry(accessToken.getToken(),accessToken.getExpiresAt().toInstant().toEpochMilli());
    }

    /**
     * Generate Video Indexer Access Token according to Permission and Scope
     * we assume Project ID and Video Id are not used in this sample
     * @return the Video Indexer Account  Access Token according to this Client Permission + Scope ( Default : Contributor /Account)
     */
    private TimedEntry generateVIAccessToken() {

        var accessTokenRequest = new AccessTokenRequest(permission, scope);
        var accessTokenRequestStr = gson.toJson(accessTokenRequest);

        var requestUri = MessageFormat.format("{0}/subscriptions/{1}/resourcegroups/{2}/providers/Microsoft.VideoIndexer/accounts/{3}/generateAccessToken?api-version={4}",
                AzureResourceManager, SubscriptionId, ResourceGroup, AccountName, ApiVersion);
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(new URI(requestUri))
                    .headers("Content-Type", "application/json;charset=UTF-8")
                    .headers("Authorization", "Bearer " + this.getArmAccessToken())
                    .POST(HttpRequest.BodyPublishers.ofString(accessTokenRequestStr))
                    .build();

            var response = httpStringResponse(request);
            AccessTokenResponse accessTokenResponse = gson.fromJson(response.body(), AccessTokenResponse.class);
            long expiry = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(55);
            return new TimedEntry(accessTokenResponse.accessToken, expiry);
        } catch (URISyntaxException | IOException | InterruptedException ex) {
            throw new RuntimeException(ex);
        }
    }
}
