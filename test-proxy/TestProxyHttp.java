import java.net.*;
import java.io.*;

public class TestProxyHttp {
    public static void main(String[] args) {
        System.out.println("=== Testing HTTP (non-HTTPS) with Proxy ===\n");

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
            final String host = hp[0];
            final int port = Integer.parseInt(hp[1]);

            // Extract credentials
            String authPart = proxyUrl.substring(7, proxyUrl.lastIndexOf("@"));
            String[] credentials = authPart.split(":", 2);
            final String username = credentials[0];
            final String password = credentials.length > 1 ? credentials[1] : "";

            System.out.println("Proxy: " + host + ":" + port);
            System.out.println("Credentials configured: Yes");

            // Set up authenticator
            Authenticator.setDefault(new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    if (getRequestorType() == RequestorType.PROXY) {
                        return new PasswordAuthentication(username, password.toCharArray());
                    }
                    return null;
                }
            });

            // Set system properties
            System.setProperty("http.proxyHost", host);
            System.setProperty("http.proxyPort", String.valueOf(port));
            System.setProperty("https.proxyHost", host);
            System.setProperty("https.proxyPort", String.valueOf(port));

            // Try HTTP connection (no SSL tunneling needed)
            System.out.println("\n1. Testing plain HTTP connection:");
            testConnection("http://example.com/");

            // Try HTTPS with system properties
            System.out.println("\n2. Testing HTTPS connection:");
            testConnection("https://repo1.maven.org/maven2/");

        } catch (Exception e) {
            System.out.println("Error: " + e.getMessage());
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
            System.out.println("   URL: " + urlString);
            System.out.println("   Response Code: " + responseCode);
            System.out.println("   Status: " + (responseCode == 200 || responseCode == 301 || responseCode == 302 ? "SUCCESS ✓" : "FAILED ✗"));
            conn.disconnect();
        } catch (Exception e) {
            System.out.println("   Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }
}
