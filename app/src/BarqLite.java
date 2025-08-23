import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import java.io.*;
import java.net.InetSocketAddress;
import java.nio.file.*;
import java.time.*;
import java.time.format.DateTimeFormatter;

public class BarqLite {
    private static final String DEFAULT_LOG = "/var/log/barq/barq.log";
    private static BufferedWriter writer;

    public static void main(String[] args) throws Exception {
        String logPath = System.getenv().getOrDefault("LOG_FILE", DEFAULT_LOG);
        Path p = Paths.get(logPath);
        Files.createDirectories(p.getParent());
        writer = Files.newBufferedWriter(p, StandardOpenOption.CREATE, StandardOpenOption.APPEND);

        log("Starting BARQ Lite…");

        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", port), 0);
        server.createContext("/", BarqLite::handleRoot);
        server.setExecutor(null);
        server.start();

        log("Listening on port " + port);
    }

    private static void handleRoot(HttpExchange ex) throws IOException {
        String response = "BARQ Lite OK: " + Instant.now().toString() + "\n";
        log("Request from " + ex.getRemoteAddress() + " " + ex.getRequestMethod() + " " + ex.getRequestURI());
        ex.sendResponseHeaders(200, response.getBytes().length);
        try (OutputStream os = ex.getResponseBody()) {
            os.write(response.getBytes());
        }
    }

    private static synchronized void log(String msg) {
        try {
            String stamp = DateTimeFormatter.ISO_OFFSET_DATE_TIME.format(OffsetDateTime.now());
            writer.write(stamp + " " + msg);
            writer.newLine();
            writer.flush();
        } catch (IOException ignored) {}
    }
}

