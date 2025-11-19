import java.net.*;
import java.io.*;

public class TestProxyDebug {
    public static void main(String[] args) {
        // Enable Java HTTP debugging
        System.setProperty("java.net.debug", "all");
        System.setProperty("jdk.http.auth.tunneling.disabledSchemes", "");

        System.out.println("=== Java Proxy Debug Test ===\n");

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
            String authPart = proxyUrl.substring(7, proxyUrl.lastIndexOf("@")); // Remove http://
            String[] credentials = authPart.split(":", 2);
            final String username = credentials[0];
            final String password = credentials.length > 1 ? credentials[1] : "";

            System.out.println("Proxy: " + host + ":" + port);
            System.out.println("Username length: " + username.length());
            System.out.println("Password length: " + password.length());

            // Set up authenticator
            Authenticator.setDefault(new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    System.out.println("Authenticator called: " + getRequestorType());
                    if (getRequestorType() == RequestorType.PROXY) {
                        System.out.println("Returning proxy credentials");
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
            System.setProperty("jdk.http.auth.tunneling.disabledSchemes", "");
            System.setProperty("jdk.http.auth.proxying.disabledSchemes", "");

            System.out.println("\nAttempting connection to Maven Central...\n");

            URL url = new URL("https://repo1.maven.org/maven2/");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);

            int responseCode = conn.getResponseCode();
            System.out.println("\n=== RESULT ===");
            System.out.println("Response Code: " + responseCode);
            System.out.println("Status: " + (responseCode == 200 ? "SUCCESS" : "FAILED"));
            conn.disconnect();

        } catch (Exception e) {
            System.out.println("\n=== ERROR ===");
            System.out.println(e.getClass().getSimpleName() + ": " + e.getMessage());
        }
    }
}
