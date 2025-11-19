import java.net.*;
import java.io.*;
import java.util.Base64;

public class TestProxyManualAuth {
    public static void main(String[] args) {
        System.out.println("=== Testing Proxy with Manual Authorization Header ===\n");

        String proxyUrl = System.getenv("http_proxy");
        if (proxyUrl == null || proxyUrl.isEmpty()) {
            System.out.println("No http_proxy environment variable found!");
            return;
        }

        try {
            // Parse proxy URL
            String[] parts = proxyUrl.split("@");
            String hostPort = parts[parts.length - 1];
            String[] hp = hostPort.split(":");
            String proxyHost = hp[0];
            int proxyPort = Integer.parseInt(hp[1]);

            // Extract credentials
            String authPart = proxyUrl.substring(7, proxyUrl.lastIndexOf("@"));
            String[] credentials = authPart.split(":", 2);
            String username = credentials[0];
            String password = credentials.length > 1 ? credentials[1] : "";

            System.out.println("Proxy: " + proxyHost + ":" + proxyPort);
            System.out.println("Username: " + username.substring(0, Math.min(50, username.length())) + "...");
            System.out.println("Password prefix: " + password.substring(0, Math.min(20, password.length())) + "...");

            // Create Basic auth string
            String auth = username + ":" + password;
            String encodedAuth = Base64.getEncoder().encodeToString(auth.getBytes());
            String authHeader = "Basic " + encodedAuth;

            System.out.println("\nEncoded auth header created (length: " + encodedAuth.length() + ")");

            // Set system properties for proxy
            System.setProperty("http.proxyHost", proxyHost);
            System.setProperty("http.proxyPort", String.valueOf(proxyPort));
            System.setProperty("https.proxyHost", proxyHost);
            System.setProperty("https.proxyPort", String.valueOf(proxyPort));

            // Test 1: HTTP request with manual header
            System.out.println("\n=== Test 1: HTTP with manual Proxy-Authorization ===");
            testConnectionWithHeader("http://example.com/", authHeader);

            // Test 2: HTTPS request (this won't work with manual header due to CONNECT)
            System.out.println("\n=== Test 2: HTTPS (note: manual header may not work for CONNECT) ===");
            testConnectionWithHeader("https://repo1.maven.org/maven2/", authHeader);

        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void testConnectionWithHeader(String urlString, String authHeader) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();

            // Set the Proxy-Authorization header manually
            conn.setRequestProperty("Proxy-Authorization", authHeader);

            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);

            int responseCode = conn.getResponseCode();
            System.out.println("   Response Code: " + responseCode);
            System.out.println("   Response Message: " + conn.getResponseMessage());
            System.out.println("   Status: " + ((responseCode >= 200 && responseCode < 400) ? "SUCCESS ✓" : "FAILED ✗"));
            conn.disconnect();
        } catch (Exception e) {
            System.out.println("   Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }
}
