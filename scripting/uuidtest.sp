/**
 * uuid_test.sp - Example plugin to test UUID generation
 * 
 * This plugin demonstrates the usage of the uuid.inc include file
 * for generating and validating RFC-4122 compliant UUIDs.
 */

#include <sourcemod>
#include <profiler>
#include <uuid>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
    name = "UUID Test Plugin",
    author = "ampere",
    description = "Tests the UUID generation functionality",
    version = "1.0",
    url = "https://github.com/maxijabase"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_testuuid", Command_TestUUID, ADMFLAG_ROOT, "Tests UUID generation");
    RegAdminCmd("sm_getuuid", Command_GetUUID, ADMFLAG_ROOT, "Generates and prints a UUID");
    RegAdminCmd("sm_validateuuid", Command_ValidateUUID, ADMFLAG_ROOT, "Validates a UUID");
    RegAdminCmd("sm_benchmarkuuid", Command_BenchmarkUUID, ADMFLAG_ROOT, "Benchmarks UUID generation");
    RegAdminCmd("sm_profileuuid", Command_ProfileUUID, ADMFLAG_ROOT, "Profiles UUID generation components");
}

public Action Command_TestUUID(int client, int args)
{
    // Generate a UUID
    char uuid[37];
    GenerateUUIDv4(uuid, sizeof(uuid));
    
    // Print to client and server console
    ReplyToCommand(client, "[UUID Test] Generated UUID v4: %s", uuid);
    ReplyToCommand(client, "[UUID Test] Is valid UUID: %s", IsValidUUID(uuid) ? "yes" : "no");
    
    // Test with an invalid UUID
    char invalidUUID[] = "not-a-valid-uuid-string-at-all";
    ReplyToCommand(client, "[UUID Test] Is '%s' a valid UUID: %s", 
        invalidUUID, IsValidUUID(invalidUUID) ? "yes" : "no");
    
    // Test conversion to bytes and back
    int bytes[UUID_BYTE_LENGTH];
    if (UUIDStringToBytes(uuid, bytes))
    {
        char regeneratedUuid[37];
        BytesToUUIDString(bytes, regeneratedUuid, sizeof(regeneratedUuid));
        
        ReplyToCommand(client, "[UUID Test] UUID string to bytes and back conversion: %s", 
            strcmp(uuid, regeneratedUuid) == 0 ? "successful" : "failed");
    }
    
    // Generate multiple UUIDs to show uniqueness
    ReplyToCommand(client, "[UUID Test] Generating 5 more UUIDs to demonstrate uniqueness:");
    
    for (int i = 0; i < 5; i++)
    {
        GenerateUUIDv4(uuid, sizeof(uuid));
        ReplyToCommand(client, "[UUID Test] UUID #%d: %s", i+1, uuid);
    }
    
    return Plugin_Handled;
}

public Action Command_GetUUID(int client, int args)
{
    char uuid[37];
    GenerateUUIDv4(uuid, sizeof(uuid));
    
    ReplyToCommand(client, "[UUID Test] Generated UUID: %s", uuid);
    return Plugin_Handled;
}

public Action Command_ValidateUUID(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[UUID Test] Usage: sm_validateuuid <uuid>");
        return Plugin_Handled;
    }
    
    char uuid[37];
    GetCmdArg(1, uuid, sizeof(uuid));
    
    bool isValid = IsValidUUID(uuid);
    ReplyToCommand(client, "[UUID Test] UUID validation result for '%s': %s", 
        uuid, isValid ? "Valid" : "Invalid");
    
    if (isValid)
    {
        // Test string to bytes conversion
        int bytes[UUID_BYTE_LENGTH];
        if (UUIDStringToBytes(uuid, bytes))
        {
            // Convert back to string
            char regeneratedUuid[37];
            BytesToUUIDString(bytes, regeneratedUuid, sizeof(regeneratedUuid));
            
            // Compare
            ReplyToCommand(client, "[UUID Test] Round-trip conversion: %s", 
                strcmp(uuid, regeneratedUuid) == 0 ? "successful" : "failed");
                
            // Display bytes (hex)
            char bytesHex[UUID_BYTE_LENGTH * 3 + 1];
            for (int i = 0; i < UUID_BYTE_LENGTH; i++)
            {
                Format(bytesHex[i*3], 4, "%02X ", bytes[i]);
            }
            
            ReplyToCommand(client, "[UUID Test] UUID as bytes: %s", bytesHex);
        }
    }
    
    return Plugin_Handled;
}

public Action Command_BenchmarkUUID(int client, int args)
{
    // Default count
    int count = 1000;
    
    // Check if a custom count was provided
    if (args >= 1)
    {
        char countStr[16];
        GetCmdArg(1, countStr, sizeof(countStr));
        count = StringToInt(countStr);
        
        // Ensure reasonable bounds
        if (count <= 0)
            count = 1;
        else if (count > 10000)
            count = 10000;
    }
    
    ReplyToCommand(client, "[UUID Test] Starting benchmark: generating %d UUIDs...", count);
    
    char uuid[37];
    
    // Create profiler
    Profiler profiler = new Profiler();
    if (profiler == null)
    {
        ReplyToCommand(client, "[UUID Test] Failed to create profiler object!");
        return Plugin_Handled;
    }
    
    // Start profiling
    profiler.Start();
    
    // Generate UUIDs in a loop
    for (int i = 0; i < count; i++)
    {
        GenerateUUIDv4(uuid, sizeof(uuid));
    }
    
    // Stop profiling
    profiler.Stop();
    
    // Get time elapsed
    float elapsedTime = profiler.Time;
    
    // Clean up
    delete profiler;
    
    // Also measure individual UUID generation time
    Profiler singleProfiler = new Profiler();
    singleProfiler.Start();
    GenerateUUIDv4(uuid, sizeof(uuid));
    singleProfiler.Stop();
    float singleTime = singleProfiler.Time;
    delete singleProfiler;
    
    // Report results
    ReplyToCommand(client, "[UUID Test] Benchmark complete!");
    ReplyToCommand(client, "[UUID Test] Total time taken: %.6f seconds", elapsedTime);
    ReplyToCommand(client, "[UUID Test] UUIDs per second: %.2f", float(count) / elapsedTime);
    ReplyToCommand(client, "[UUID Test] Average time per UUID: %.9f seconds", elapsedTime / float(count));
    ReplyToCommand(client, "[UUID Test] Single UUID generation time: %.9f seconds", singleTime);
    
    // Show the last generated UUID as a sample
    ReplyToCommand(client, "[UUID Test] Sample UUID: %s", uuid);
    
    // Detailed profiling with events
    if (IsProfilingActive())
    {
        ReplyToCommand(client, "[UUID Test] Running detailed component profiling...");
        
        char detailedUuid[37];
        int bytes[UUID_BYTE_LENGTH];
        
        // Profile each component of UUID generation
        EnterProfilingEvent("UUID", "RandomBytes");
        for (int i = 0; i < UUID_BYTE_LENGTH; i++)
        {
            bytes[i] = GetRandomInt(0, 255);
        }
        LeaveProfilingEvent();
        
        EnterProfilingEvent("UUID", "VersionBits");
        bytes[6] = (bytes[6] & 0x0F) | 0x40;
        bytes[8] = (bytes[8] & 0x3F) | 0x80;
        LeaveProfilingEvent();
        
        EnterProfilingEvent("UUID", "FormatString");
        BytesToUUIDString(bytes, detailedUuid, sizeof(detailedUuid));
        LeaveProfilingEvent();
        
        ReplyToCommand(client, "[UUID Test] Detailed profiling complete. Check server logs for results.");
    }
    else
    {
        ReplyToCommand(client, "[UUID Test] Note: Enable sm_profile to get detailed component-level profiling.");
    }
    
    return Plugin_Handled;
}

public Action Command_ProfileUUID(int client, int args)
{
    ReplyToCommand(client, "[UUID Test] Starting detailed UUID generation profiling...");
    
    // Create profilers for each component
    Profiler totalProfiler = new Profiler();
    Profiler randomBytesProfiler = new Profiler();
    Profiler versionBitsProfiler = new Profiler();
    Profiler formatProfiler = new Profiler();
    Profiler validationProfiler = new Profiler();
    
    if (totalProfiler == null || randomBytesProfiler == null || 
        versionBitsProfiler == null || formatProfiler == null || 
        validationProfiler == null)
    {
        ReplyToCommand(client, "[UUID Test] Failed to create profiler objects!");
        return Plugin_Handled;
    }
    
    // Number of iterations to get meaningful results
    int iterations = 1000;
    if (args >= 1)
    {
        char countStr[16];
        GetCmdArg(1, countStr, sizeof(countStr));
        iterations = StringToInt(countStr);
        
        if (iterations <= 0)
            iterations = 1;
        else if (iterations > 10000)
            iterations = 10000;
    }
    
    // Start total profiling
    totalProfiler.Start();
    
    char uuid[37];
    int testBytes[UUID_BYTE_LENGTH];
    
    // Profile each component separately with multiple iterations
    randomBytesProfiler.Start();
    for (int j = 0; j < iterations; j++)
    {
        for (int i = 0; i < UUID_BYTE_LENGTH; i++)
        {
            testBytes[i] = GetRandomInt(0, 255);
        }
    }
    randomBytesProfiler.Stop();
    
    versionBitsProfiler.Start();
    for (int j = 0; j < iterations; j++)
    {
        testBytes[6] = (testBytes[6] & 0x0F) | 0x40;
        testBytes[8] = (testBytes[8] & 0x3F) | 0x80;
    }
    versionBitsProfiler.Stop();
    
    formatProfiler.Start();
    for (int j = 0; j < iterations; j++)
    {
        BytesToUUIDString(testBytes, uuid, sizeof(uuid));
    }
    formatProfiler.Stop();
    
    validationProfiler.Start();
    for (int j = 0; j < iterations; j++)
    {
        IsValidUUID(uuid);
    }
    validationProfiler.Stop();
    
    // Stop total profiling
    totalProfiler.Stop();
    
    // Calculate percentages
    float totalTime = totalProfiler.Time;
    float randomBytesTime = randomBytesProfiler.Time;
    float versionBitsTime = versionBitsProfiler.Time;
    float formatTime = formatProfiler.Time;
    float validationTime = validationProfiler.Time;
    
    float randomBytesPercent = (randomBytesTime / totalTime) * 100.0;
    float versionBitsPercent = (versionBitsTime / totalTime) * 100.0;
    float formatPercent = (formatTime / totalTime) * 100.0;
    float validationPercent = (validationTime / totalTime) * 100.0;
    
    // Display results to client
    ReplyToCommand(client, "[UUID Test] Profiling completed for %d iterations:", iterations);
    ReplyToCommand(client, "-------------------------------------------------------------------------");
    ReplyToCommand(client, "| Component      | Time (sec)    | Avg/UUID (sec) | %% of Total Time  |");
    ReplyToCommand(client, "-------------------------------------------------------------------------");
    ReplyToCommand(client, "| Random bytes   | %.6f      | %.9f   | %.2f%%            |", 
        randomBytesTime, randomBytesTime / float(iterations), randomBytesPercent);
    ReplyToCommand(client, "| Version bits   | %.6f      | %.9f   | %.2f%%            |", 
        versionBitsTime, versionBitsTime / float(iterations), versionBitsPercent);
    ReplyToCommand(client, "| Format string  | %.6f      | %.9f   | %.2f%%            |", 
        formatTime, formatTime / float(iterations), formatPercent);
    ReplyToCommand(client, "| UUID validation| %.6f      | %.9f   | %.2f%%            |", 
        validationTime, validationTime / float(iterations), validationPercent);
    ReplyToCommand(client, "-------------------------------------------------------------------------");
    ReplyToCommand(client, "| Total          | %.6f      | %.9f   | 100.00%%          |", 
        totalTime, totalTime / float(iterations));
    ReplyToCommand(client, "-------------------------------------------------------------------------");
    
    // Generate a full UUID for comparison
    char fullUuid[37];
    Profiler fullUuidProfiler = new Profiler();
    fullUuidProfiler.Start();
    GenerateUUIDv4(fullUuid, sizeof(fullUuid));
    fullUuidProfiler.Stop();
    
    ReplyToCommand(client, "[UUID Test] Single complete UUID generation: %.9f seconds", fullUuidProfiler.Time);
    ReplyToCommand(client, "[UUID Test] Sample UUID: %s", fullUuid);
    
    // Clean up
    delete totalProfiler;
    delete randomBytesProfiler;
    delete versionBitsProfiler;
    delete formatProfiler;
    delete validationProfiler;
    delete fullUuidProfiler;
    
    return Plugin_Handled;
}