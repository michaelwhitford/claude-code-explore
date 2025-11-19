import java.net.*;
import java.io.*;
import java.util.*;

public class TestProxy {
    public static void main(String[] args) {
        System.out.println("=== Java Proxy Configuration Test ===\n");

        // Test 1: Check system properties
        System.out.println("1. System Properties:");
        System.out.println("   http.proxyHost: " + System.getProperty("http.proxyHost"));
        System.out.println("   http.proxyPort: " + System.getProperty("http.proxyPort"));
        System.out.println("   https.proxyHost: " + System.getProperty("https.proxyHost"));
        System.out.println("   https.proxyPort: " + System.getProperty("https.proxyPort"));

        // Test 2: Check environment variables
        System.out.println("\n2. Environment Variables:");
        System.out.println("   HTTP_PROXY: " + (System.getenv("HTTP_PROXY") != null ? "SET" : "NOT SET"));
        System.out.println("   http_proxy: " + (System.getenv("http_proxy") != null ? "SET" : "NOT SET"));

        // Test 3: Parse proxy from environment
        String proxyUrl = System.getenv("http_proxy");
        if (proxyUrl != null && !proxyUrl.isEmpty()) {
            System.out.println("\n3. Parsing http_proxy environment variable:");
            try {
                // Extract host and port from proxy URL
                // Format: http://user:pass@host:port
                String[] parts = proxyUrl.split("@");
                if (parts.length > 1) {
                    String hostPort = parts[parts.length - 1];
                    String[] hp = hostPort.split(":");
                    String proxyHost = hp[0];
                    String proxyPort = hp[1];
                    System.out.println("   Proxy Host: " + proxyHost);
                    System.out.println("   Proxy Port: " + proxyPort);

                    // Test 4: Try to connect using the proxy
                    System.out.println("\n4. Testing connection to Maven Central via proxy:");
                    testConnection("https://repo1.maven.org/maven2/", proxyHost, Integer.parseInt(proxyPort));

                    System.out.println("\n5. Testing connection to Clojars via proxy:");
                    testConnection("https://repo.clojars.org/", proxyHost, Integer.parseInt(proxyPort));
                }
            } catch (Exception e) {
                System.out.println("   Error parsing proxy: " + e.getMessage());
            }
        }

        // Test 6: Try with system properties set
        System.out.println("\n6. Testing with environment proxy via system properties:");
        if (proxyUrl != null) {
            parseAndSetProxy(proxyUrl);
            testConnectionWithSystemProps("https://repo1.maven.org/maven2/");
        }
    }

    private static void parseAndSetProxy(String proxyUrl) {
        try {
            String[] parts = proxyUrl.split("@");
            if (parts.length > 1) {
                String hostPort = parts[parts.length - 1];
                String[] hp = hostPort.split(":");
                System.setProperty("http.proxyHost", hp[0]);
                System.setProperty("http.proxyPort", hp[1]);
                System.setProperty("https.proxyHost", hp[0]);
                System.setProperty("https.proxyPort", hp[1]);
                System.out.println("   Set proxy system properties: " + hp[0] + ":" + hp[1]);
            }
        } catch (Exception e) {
            System.out.println("   Error setting proxy: " + e.getMessage());
        }
    }

    private static void testConnection(String urlString, String proxyHost, int proxyPort) {
        try {
            URL url = new URL(urlString);
            Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(proxyHost, proxyPort));
            HttpURLConnection conn = (HttpURLConnection) url.openConnection(proxy);
            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);

            int responseCode = conn.getResponseCode();
            System.out.println("   Response Code: " + responseCode);
            System.out.println("   Status: " + (responseCode == 200 ? "SUCCESS" : "FAILED"));
            conn.disconnect();
        } catch (Exception e) {
            System.out.println("   Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }

    private static void testConnectionWithSystemProps(String urlString) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);

            int responseCode = conn.getResponseCode();
            System.out.println("   Response Code: " + responseCode);
            System.out.println("   Status: " + (responseCode == 200 ? "SUCCESS" : "FAILED"));
            conn.disconnect();
        } catch (Exception e) {
            System.out.println("   Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }
}
