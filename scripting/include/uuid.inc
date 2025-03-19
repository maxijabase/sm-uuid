/**
 * uuid.inc - RFC-4122 UUID Generator for SourcePawn
 * 
 * This include provides functions to generate RFC-4122 compliant UUIDs 
 * (Universally Unique Identifiers) for SourceMod plugins.
 * 
 * Currently implements:
 * - UUID version 4 (random)
 */

#if defined _uuid_included
 #endinput
#endif
#define _uuid_included

#include <sourcemod>

#define UUID_STRING_LENGTH 36
#define UUID_BYTE_LENGTH 16

/**
 * Generates a random UUID (version 4) as per RFC-4122.
 *
 * @param buffer        Buffer to store the UUID string.
 * @param maxlen        Maximum length of the buffer.
 * @return              Number of bytes written to the buffer.
 */
stock int GenerateUUIDv4(char[] buffer, int maxlen)
{
    if (maxlen < UUID_STRING_LENGTH + 1)
    {
        return 0;
    }
    
    // Generate random bytes
    int bytes[UUID_BYTE_LENGTH];
    for (int i = 0; i < UUID_BYTE_LENGTH; i++)
    {
        bytes[i] = GetRandomInt(0, 255);
    }
    
    // Set version to 4 (random UUID)
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    
    // Set variant to RFC-4122
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    
    // Convert bytes to UUID string
    return BytesToUUIDString(bytes, buffer, maxlen);
}

/**
 * Converts 16 bytes to a UUID string formatted according to RFC-4122.
 *
 * @param bytes         Array of 16 bytes.
 * @param buffer        Buffer to store the UUID string.
 * @param maxlen        Maximum length of the buffer.
 * @return              Number of bytes written to the buffer.
 */
stock int BytesToUUIDString(const int[] bytes, char[] buffer, int maxlen)
{
    if (maxlen < UUID_STRING_LENGTH + 1)
    {
        return 0;
    }
    
    // Format the UUID string using specific byte positions
    FormatEx(buffer, maxlen, 
        "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        bytes[0] & 0xFF, bytes[1] & 0xFF, bytes[2] & 0xFF, bytes[3] & 0xFF,
        bytes[4] & 0xFF, bytes[5] & 0xFF,
        bytes[6] & 0xFF, bytes[7] & 0xFF,
        bytes[8] & 0xFF, bytes[9] & 0xFF,
        bytes[10] & 0xFF, bytes[11] & 0xFF, bytes[12] & 0xFF, bytes[13] & 0xFF, bytes[14] & 0xFF, bytes[15] & 0xFF
    );
    
    return UUID_STRING_LENGTH;
}

/**
 * Validates if a string is a valid RFC-4122 UUID.
 *
 * @param uuid          String to validate.
 * @return              True if valid, false otherwise.
 */
stock bool IsValidUUID(const char[] uuid)
{
    // Check length
    if (strlen(uuid) != UUID_STRING_LENGTH)
    {
        return false;
    }
    
    // Check format pattern: 8-4-4-4-12 hexadecimal digits with hyphens
    static int hyphenPositions[] = {8, 13, 18, 23};
    
    for (int i = 0; i < sizeof(hyphenPositions); i++)
    {
        if (uuid[hyphenPositions[i]] != '-')
        {
            return false;
        }
    }
    
    // Check that all other positions contain hex digits
    for (int i = 0; i < UUID_STRING_LENGTH; i++)
    {
        // Skip hyphen positions
        bool isHyphenPosition = false;
        for (int j = 0; j < sizeof(hyphenPositions); j++)
        {
            if (i == hyphenPositions[j])
            {
                isHyphenPosition = true;
                break;
            }
        }
        
        if (!isHyphenPosition && !IsCharHex(uuid[i]))
        {
            return false;
        }
    }
    
    // Verify version (position 14, should be 4 for random UUID)
    if (uuid[14] != '4')
    {
        return false;
    }
    
    // Verify variant (position 19, should be 8, 9, A, or B)
    char variantChar = uuid[19];
    if (variantChar != '8' && variantChar != '9' && 
        variantChar != 'a' && variantChar != 'b' && 
        variantChar != 'A' && variantChar != 'B')
    {
        return false;
    }
    
    return true;
}

/**
 * Attempts to parse a UUID string into its component bytes.
 *
 * @param uuid          UUID string to parse.
 * @param bytes         Array to store the resulting bytes (must be size 16 or larger).
 * @return              True if successful, false if the UUID is invalid.
 */
stock bool UUIDStringToBytes(const char[] uuid, int[] bytes)
{
    if (!IsValidUUID(uuid))
    {
        return false;
    }
    
    // Temporary buffer for parsing hex pairs
    char hexPair[3];
    hexPair[2] = '\0';
    
    // Current position in the byte array
    int byteIndex = 0;
    
    // Parse the UUID string
    for (int i = 0; i < UUID_STRING_LENGTH; i++)
    {
        // Skip hyphens
        if (uuid[i] == '-')
        {
            continue;
        }
        
        // Read two characters (one byte)
        hexPair[0] = uuid[i];
        hexPair[1] = uuid[++i];
        
        // Convert hex to integer
        bytes[byteIndex++] = StringToInt(hexPair, 16) & 0xFF;
    }
    
    return true;
}

/**
 * Checks if a character is a hexadecimal digit (0-9, a-f, A-F).
 *
 * @param c             Character to check.
 * @return              True if hexadecimal, false otherwise.
 */
stock bool IsCharHex(char c)
{
    return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

/**
 * Example usage.
 */
public void Example_UUIDv4()
{
    char uuid[37]; // 36 chars + null terminator
    GenerateUUIDv4(uuid, sizeof(uuid));
    
    PrintToServer("Generated UUID v4: %s", uuid);
    PrintToServer("Is valid UUID: %s", IsValidUUID(uuid) ? "yes" : "no");
    
    // Demonstrate parsing
    int bytes[UUID_BYTE_LENGTH];
    if (UUIDStringToBytes(uuid, bytes))
    {
        PrintToServer("Successfully parsed UUID to bytes");
        
        // Convert back to string to verify
        char regeneratedUuid[37];
        BytesToUUIDString(bytes, regeneratedUuid, sizeof(regeneratedUuid));
        
        // Should be the same as the original
        PrintToServer("Regenerated UUID: %s", regeneratedUuid);
        PrintToServer("UUIDs match: %s", strcmp(uuid, regeneratedUuid) == 0 ? "yes" : "no");
    }
}