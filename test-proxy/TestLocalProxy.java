import java.net.*;
import java.io.*;

public class TestLocalProxy {
    public static void main(String[] args) {
        System.out.println("=== Testing with Local Proxy Wrapper ===\n");

        // Configure for local proxy (no authentication needed)
        System.setProperty("http.proxyHost", "127.0.0.1");
        System.setProperty("http.proxyPort", "8888");
        System.setProperty("https.proxyHost", "127.0.0.1");
        System.setProperty("https.proxyPort", "8888");

        System.out.println("Proxy configured: 127.0.0.1:8888");
        System.out.println();

        // Test Maven Central
        System.out.println("=== Test 1: Maven Central (HTTPS) ===");
        testConnection("https://repo1.maven.org/maven2/");

        // Test Clojars
        System.out.println("\n=== Test 2: Clojars (HTTPS) ===");
        testConnection("https://repo.clojars.org/");

        // Test downloading a specific artifact
        System.out.println("\n=== Test 3: Download a small artifact ===");
        downloadArtifact("https://repo1.maven.org/maven2/org/clojure/clojure/1.11.1/clojure-1.11.1.pom");
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
            System.out.println("   Response Message: " + conn.getResponseMessage());
            System.out.println("   Status: " + (responseCode == 200 ? "SUCCESS ✓" : "FAILED ✗"));
            conn.disconnect();
        } catch (Exception e) {
            System.out.println("   Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }

    private static void downloadArtifact(String urlString) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);

            int responseCode = conn.getResponseCode();
            System.out.println("   URL: " + urlString);
            System.out.println("   Response Code: " + responseCode);

            if (responseCode == 200) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                StringBuilder content = new StringBuilder();
                String line;
                int lines = 0;
                while ((line = reader.readLine()) != null && lines < 5) {
                    content.append(line).append("\n");
                    lines++;
                }
                reader.close();

                System.out.println("   Downloaded successfully! First few lines:");
                System.out.println("   ---");
                System.out.println("   " + content.toString().replace("\n", "\n   "));
                System.out.println("   ---");
                System.out.println("   Status: SUCCESS ✓");
            } else {
                System.out.println("   Status: FAILED ✗");
            }
            conn.disconnect();
        } catch (Exception e) {
            System.out.println("   Error: " + e.getClass().getSimpleName() + " - " + e.getMessage());
        }
    }
}
