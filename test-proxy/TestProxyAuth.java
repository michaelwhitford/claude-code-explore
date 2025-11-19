import java.net.*;
import java.io.*;

public class TestProxyAuth {
    public static void main(String[] args) {
        System.out.println("=== Java Proxy with Authentication Test ===\n");

        String proxyUrl = System.getenv("http_proxy");
        if (proxyUrl == null || proxyUrl.isEmpty()) {
            System.out.println("No http_proxy environment variable found!");
            return;
        }

        System.out.println("Parsing proxy configuration from environment...");

        try {
            // Parse proxy URL: http://username:password@host:port
            URI uri = new URI(proxyUrl);
            String userInfo = uri.getUserInfo();
            String host = null;
            int port = -1;

            // Extract host and port from the part after @
            String[] parts = proxyUrl.split("@");
            if (parts.length > 1) {
                String hostPort = parts[parts.length - 1];
                String[] hp = hostPort.split(":");
                host = hp[0];
                port = Integer.parseInt(hp[1]);
            }

            String username = null;
            String password = null;

            if (userInfo != null) {
                String[] credentials = userInfo.split(":", 2);
                username = credentials[0];
                if (credentials.length > 1) {
                    password = credentials[1];
                }
            }

            System.out.println("Proxy Host: " + host);
            System.out.println("Proxy Port: " + port);
            System.out.println("Username: " + (username != null ? username.substring(0, Math.min(30, username.length())) + "..." : "null"));
            System.out.println("Password: " + (password != null ? password.substring(0, Math.min(30, password.length())) + "..." : "null"));

            // Set up authenticator
            if (username != null && password != null) {
                final String finalUsername = username;
                final String finalPassword = password;

                Authenticator.setDefault(new Authenticator() {
                    @Override
                    protected PasswordAuthentication getPasswordAuthentication() {
                        if (getRequestorType() == RequestorType.PROXY) {
                            return new PasswordAuthentication(finalUsername, finalPassword.toCharArray());
                        }
                        return null;
                    }
                });
                System.out.println("\nProxy authenticator configured.");
            }

            // Set system properties as well
            System.setProperty("http.proxyHost", host);
            System.setProperty("http.proxyPort", String.valueOf(port));
            System.setProperty("https.proxyHost", host);
            System.setProperty("https.proxyPort", String.valueOf(port));

            // Test connections
            System.out.println("\n=== Testing Maven Central ===");
            testConnection("https://repo1.maven.org/maven2/");

            System.out.println("\n=== Testing Clojars ===");
            testConnection("https://repo.clojars.org/");

            System.out.println("\n=== Testing with explicit Proxy object ===");
            Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(host, port));
            testConnectionWithProxy("https://repo1.maven.org/maven2/", proxy);

        } catch (Exception e) {
            System.out.println("Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void testConnection(String urlString) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);

            int responseCode = conn.getResponseCode();
            System.out.println("Response Code: " + responseCode);
            System.out.println("Response Message: " + conn.getResponseMessage());
            System.out.println("Status: " + (responseCode == 200 ? "SUCCESS ✓" : "FAILED ✗"));
            conn.disconnect();
        } catch (Exception e) {
            System.out.println("Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void testConnectionWithProxy(String urlString, Proxy proxy) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection(proxy);
            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);

            int responseCode = conn.getResponseCode();
            System.out.println("Response Code: " + responseCode);
            System.out.println("Status: " + (responseCode == 200 ? "SUCCESS ✓" : "FAILED ✗"));
            conn.disconnect();
        } catch (Exception e) {
            System.out.println("Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }
}
