package petoboto.api;

import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

import javax.sql.DataSource;

import io.quarkus.logging.Log;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Default;
import jakarta.inject.Inject;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.concurrent.ThreadLocalRandom;

@ApplicationScoped
@Path("/_stress")
public class StressResource {
    @Inject
    DataSource ds;

    @Path("/sleep")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response stressSleep(@QueryParam("duration") @DefaultValue("15") Integer duration
    ) {
        try {
            Thread.sleep( duration * 1_000L);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
        var body = Map.of(
                "stress", "sleep",
                "duration", "" + duration,
                "status", "OK");
        return Response.ok(body).build();
    }

    @Path("/cpu")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response stressCpu(@QueryParam("duration") @DefaultValue("15") Integer duration) {
        runCpuStressAllCoresAsync(duration);
        var body = Map.of(
                "stress", "cpu",
                "duration", "" + duration,
                "status", "OK");
        return Response.ok(body).build();
    }

    public static void doStressCpu(int durationSeconds) {
        long end = System.currentTimeMillis() + durationSeconds * 1_000L;

        double x = 0;
        while (System.currentTimeMillis() < end) {
            x += Math.sqrt(x + 1.2345);
            if (x > 1e9)
                x = 0;
        }
    }

    /** Start one CPU stressor asynchronously on a virtual thread. */
    public static CompletableFuture<Void> runCpuStressAsync(int durationSeconds) {
        return startVirtualThreadAsync(() -> doStressCpu(durationSeconds));
    }

    /**
     * Start one task per available core, all on virtual threads, and complete when
     * all finish.
     */
    public static CompletableFuture<Void> runCpuStressAllCoresAsync(int durationSeconds) {
        int n = Runtime.getRuntime().availableProcessors();
        var tasks = new ArrayList<CompletableFuture<Void>>(n);
        for (int i = 0; i < n; i++) {
            tasks.add(runCpuStressAsync(durationSeconds));
        }
        return CompletableFuture.allOf(tasks.toArray(CompletableFuture[]::new));
    }

    // --- helpers ---

    private static CompletableFuture<Void> startVirtualThreadAsync(Runnable r) {
        var cf = new CompletableFuture<Void>();
        Thread.startVirtualThread(() -> {
            try {
                r.run();
                cf.complete(null);
            } catch (Throwable t) {
                cf.completeExceptionally(t);
            }
        });
        return cf;
    }
    // ---------------- MEMORY ----------------

    @Path("/mem")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response stressMemory(@QueryParam("duration") @DefaultValue("15") Integer duration,
            @QueryParam("targetPercentage") @DefaultValue("95") Integer targetPercentage) {
        long maxHeap = Runtime.getRuntime().maxMemory();
        int targetMB = (int) (maxHeap * targetPercentage / (1024 * 1024)); // 95% of max heap, in MB

        doMemoryStressAsync(duration, targetMB);
        var body = Map.of(
                "stress", "memory",
                "duration", "" + duration,
                "targetMB", "" + targetMB,
                "status", "OK");
        return Response.ok(body).build();
    }

    /** Start one memory stressor asynchronously on a virtual thread. */
    public static CompletableFuture<Void> doMemoryStressAsync(int durationSeconds, int targetMB) {
        return startVirtualThreadAsync(() -> doStressMemory(durationSeconds, targetMB));
    }

    public static void doStressMemory(int durationSeconds, int targetMB) {
        long end = System.currentTimeMillis() + durationSeconds * 1_000L;

        final int chunkSize = 1 * 1024 * 1024; // 1 MB chunks
        long requestedBytes = Math.max(1, targetMB) * 1_000_000L;

        var held = new ArrayList<byte[]>((int) Math.max(1, requestedBytes / chunkSize));
        long allocated = 0;

        try {
            while (allocated + chunkSize <= requestedBytes) {
                var block = new byte[chunkSize];
                block[0] = 1;
                block[chunkSize - 1] = 1;
                held.add(block);
                allocated += chunkSize;
            }
        } catch (OutOfMemoryError oom) {
            // Stop allocating, keep what we got
        }

        int idx = 0;
        while (System.currentTimeMillis() < end) {
            if (!held.isEmpty()) {
                var b = held.get(idx);
                b[(int) (System.nanoTime() & (chunkSize - 1))] ^= 1;
                idx = (idx + 1) % held.size();
            }
            try {
                Thread.sleep(5);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
                break;
            }
        }

        held.clear(); // release
    }

    @Path("/io")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response stressIO(@QueryParam("duration") @DefaultValue("15") Integer duration) {
        java.nio.file.Path dir = Paths.get(System.getProperty("java.io.tmpdir")); // or pick a data disk mount
        runIOStressAllCoresAsync(duration, dir.toString());
        var body = Map.of(
                "stress", "io",
                "duration", "" + duration,
                "dir", dir.toString(),
                "status", "OK");
        return Response.ok(body).build();
    }

    /** Start N I/O stressors (one per CPU) on virtual threads. */
    public static CompletableFuture<Void> runIOStressAllCoresAsync(int durationSeconds, String dir) {
        int n = Math.max(1, Runtime.getRuntime().availableProcessors());
        var tasks = new ArrayList<CompletableFuture<Void>>(n);
        for (int i = 0; i < n; i++) {
            tasks.add(runIOStressAsync(durationSeconds, dir));
        }
        return CompletableFuture.allOf(tasks.toArray(CompletableFuture[]::new));
    }

    /** Start a single I/O stressor asynchronously on a virtual thread. */
    public static CompletableFuture<Void> runIOStressAsync(int durationSeconds, String dir) {
        return startVirtualThreadAsync(() -> doStressIO(durationSeconds, Paths.get(dir)));
    }

    /**
     * Stresses disk I/O by repeatedly writing fsynced blocks, then reading them
     * back,
     * until duration elapses. Keeps file size bounded to avoid filling the disk.
     */
    public static void doStressIO(int durationSeconds, java.nio.file.Path dir) {
        long end = System.currentTimeMillis() + durationSeconds * 1_000L;
        final int BLOCK = 4 * 1024 * 1024; // 4 MiB blocks
        final long MAX_FILE_BYTES = 2L * 1024 * 1024 * 1024; // cap each file at ~2 GiB

        try {
            Files.createDirectories(dir);
        } catch (IOException ignored) {
            /* best effort */ }

        String fileName = "io-stress-" + System.currentTimeMillis() + "-" + Thread.currentThread().threadId() + ".dat";
        java.nio.file.Path file = dir.resolve(fileName);

        // Prepare a direct buffer (off-heap) to reduce GC noise during I/O tests
        ByteBuffer buf = ByteBuffer.allocateDirect(BLOCK);

        // Randomize initial contents so the OS can't trivially short-circuit writes
        ThreadLocalRandom tlr = ThreadLocalRandom.current();
        for (int i = 0; i < BLOCK / Long.BYTES; i++) {
            buf.putLong(tlr.nextLong());
        }
        buf.flip();

        try (FileChannel ch = FileChannel.open(
                file,
                StandardOpenOption.CREATE,
                StandardOpenOption.WRITE,
                StandardOpenOption.READ,
                StandardOpenOption.TRUNCATE_EXISTING)) {

            long written = 0;
            int writesSinceFsync = 0;

            // WRITE PHASE (with periodic fsync) until ~half the duration
            long writeUntil = System.currentTimeMillis() + (durationSeconds * 500L);
            while (System.currentTimeMillis() < writeUntil) {
                buf.position(0); // rewind for next write
                while (buf.hasRemaining()) {
                    ch.write(buf);
                }
                written += BLOCK;
                writesSinceFsync++;

                // Force to disk every ~64 MiB to ensure real I/O
                if (writesSinceFsync >= (64 * 1024 * 1024) / BLOCK) {
                    ch.force(false);
                    writesSinceFsync = 0;
                }

                // Keep file size bounded; wrap back to start
                if (written >= MAX_FILE_BYTES) {
                    ch.truncate(0);
                    ch.position(0);
                    written = 0;
                }
            }
            ch.force(true); // final flush

            // READ PHASE for the remaining time (sequential scans)
            try (FileChannel rd = FileChannel.open(file, StandardOpenOption.READ)) {
                long size = rd.size();
                if (size == 0) {
                    // nothing to read; fall back to small writes to keep device busy
                    while (System.currentTimeMillis() < end) {
                        buf.position(0);
                        ch.write(buf);
                        ch.force(false);
                    }
                } else {
                    ByteBuffer rbuf = ByteBuffer.allocateDirect(BLOCK);
                    long pos = 0;
                    while (System.currentTimeMillis() < end) {
                        rbuf.clear();
                        int n = rd.read(rbuf, pos);
                        if (n < 0) { // EOF → wrap
                            pos = 0;
                            continue;
                        }
                        pos += n;
                        if (pos >= size)
                            pos = 0;
                    }
                }
            }

        } catch (IOException e) {
            // swallow for stress purpose; production might log
        } finally {
            try {
                Files.deleteIfExists(file);
            } catch (IOException ignored) {
            }
        }
    }

    /**
     * /_stress/jdbc/write?duration=15&concurrency=8
     * Each worker connection creates its own TEMPORARY TABLE,
     * inserts random payloads for <duration> seconds, commits often,
     * and drops automatically on connection close.
     */
    @Path("/jdbc/write")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response stressJdbcWrite(
            @QueryParam("duration") @DefaultValue("15") Integer duration,
            @QueryParam("concurrency") Integer concurrencyParam) {
        int concurrency = (concurrencyParam == null)
                ? Math.max(1, Runtime.getRuntime().availableProcessors() * 2)
                : Math.max(1, concurrencyParam);

        runMysqlJdbcTempStressAsync(duration, concurrency);

        var body = Map.of(
                "stress", "jdbc-write",
                "duration", String.valueOf(duration),
                "concurrency", String.valueOf(concurrency),
                "mode", "mysql-temporary-table",
                "status", "OK");
        return Response.ok(body).build();
    }

    /** Launch N virtual-thread workers, each with its own temp table. */
    public CompletableFuture<Void> runMysqlJdbcTempStressAsync(int durationSeconds, int concurrency) {
        var tasks = new ArrayList<CompletableFuture<Void>>(concurrency);
        for (int i = 0; i < concurrency; i++) {
            tasks.add(startVirtualThreadAsync(() -> doStressMysqlTempTable(durationSeconds, ds)));
        }
        return CompletableFuture.allOf(tasks.toArray(CompletableFuture[]::new));
    }

    /** Worker: create TEMPORARY TABLE, batch INSERT random bytes, commit. */
    public static void doStressMysqlTempTable(int durationSeconds, DataSource ds) {
        long end = System.currentTimeMillis() + durationSeconds * 1_000L;
        final int BATCH = 200, PAYLOAD = 256;
        var rnd = new java.security.SecureRandom();

        try (Connection c = ds.getConnection()) {
            c.setAutoCommit(false);

            // Create TEMPORARY TABLE (auto-dropped when connection closes)
            try (Statement s = c.createStatement()) {
                s.executeUpdate(
                        "CREATE TEMPORARY TABLE stress_tmp (" +
                                "  id BIGINT PRIMARY KEY AUTO_INCREMENT," +
                                "  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                                "  payload VARBINARY(256) NOT NULL" +
                                ") ENGINE=InnoDB");
            }

            String insSql = "INSERT INTO stress_tmp (created_at, payload) VALUES (NOW(), ?)";
            try (PreparedStatement ins = c.prepareStatement(insSql)) {
                byte[] buf = new byte[PAYLOAD];
                while (System.currentTimeMillis() < end) {
                    ins.clearBatch();
                    for (int i = 0; i < BATCH; i++) {
                        rnd.nextBytes(buf);
                        ins.setBytes(1, buf);
                        ins.addBatch();
                    }
                    ins.executeBatch();
                    c.commit(); // flush redo/binlog pressure
                }
            }
        } catch (SQLException ignore) {
            Log.error("Error occurred while stressing MySQL temporary table", ignore);
        }
    }

    /**
     * /_stress/jdbc/read?duration=15&concurrency=8
     * Spawns <concurrency> virtual-thread workers that loop BENCHMARK queries until
     * <duration> elapses.
     */
    @Path("/jdbc/read")
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Response stressJdbcRead(
            @QueryParam("duration") @DefaultValue("15") Integer duration,
            @QueryParam("concurrency") Integer concurrencyParam) {
        int concurrency = (concurrencyParam == null)
                ? Math.max(1, Runtime.getRuntime().availableProcessors() * 2)
                : Math.max(1, concurrencyParam);

        runMysqlJdbcReadStressAsync(duration, concurrency);

        var body = Map.of(
                "stress", "jdbc-read",
                "duration", String.valueOf(duration),
                "concurrency", String.valueOf(concurrency),
                "query", "BENCHMARK(10000, SHA2(RAND(),512))",
                "status", "OK");
        return Response.ok(body).build();
    }

    /** Launch N readers on virtual threads. */
    public CompletableFuture<Void> runMysqlJdbcReadStressAsync(int durationSeconds, int concurrency) {
        var tasks = new ArrayList<CompletableFuture<Void>>(concurrency);
        for (int i = 0; i < concurrency; i++) {
            tasks.add(startVirtualThreadAsync(() -> doStressMysqlRead(durationSeconds, ds)));
        }
        return CompletableFuture.allOf(tasks.toArray(CompletableFuture[]::new));
    }

    /** Worker: heavier SELECT loop with BENCHMARK. */
    public static void doStressMysqlRead(int durationSeconds, DataSource ds) {
        long end = System.currentTimeMillis() + durationSeconds * 1_000L;

        // This query burns CPU inside MySQL
        final String sql = "SELECT BENCHMARK(10000, SHA2(RAND(),512))";

        try (var c = ds.getConnection()) {
            c.setAutoCommit(true);
            try (var ps = c.prepareStatement(sql)) {
                while (System.currentTimeMillis() < end) {
                    try (var rs = ps.executeQuery()) {
                        if (rs.next()) {
                            rs.getInt(1);
                        }
                    }
                }
            }
        } catch (SQLException e) {
            Log.error("Error during JDBC read stress", e);
        }
    }

}
