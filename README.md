# SourcePawn UUID Generator

A lightweight, RFC-4122 compliant UUID (Universally Unique Identifier) generator for SourceMod plugins.

## Features

- Generates version 4 (random) UUIDs
- Validates UUID strings against RFC-4122 standard
- Converts between UUID strings and byte representation
- High performance (1+ million UUIDs per second)

## Installation

1. Copy `uuid.inc` to your `addons/sourcemod/scripting/include` directory
2. Include it in your plugins with `#include <uuid>`

## Usage

```cpp
// Generate a new UUID
char uuid[37];
GenerateUUIDv4(uuid, sizeof(uuid));
PrintToServer("Generated UUID: %s", uuid);

// Validate a UUID
bool isValid = IsValidUUID(uuid);

// Convert UUID to bytes and back
int bytes[16];
UUIDStringToBytes(uuid, bytes);

char regenerated[37];
BytesToUUIDString(bytes, regenerated, sizeof(regenerated));
```

## Example Plugin

The repository includes a test plugin (`uuid_test.sp`) with commands:

- `sm_testuuid` - Tests basic UUID functionality
- `sm_getuuid` - Generates and prints a single UUID
- `sm_validateuuid <uuid>` - Validates a UUID string
- `sm_benchmarkuuid [count]` - Benchmarks UUID generation
- `sm_profileuuid [count]` - Profiles performance of each UUID component

## Performance

Test results show that the generator can create more than 1 million UUIDs per second on typical server hardware:

```
[UUID Test] Profiling completed for 1000 iterations:
-------------------------------------------------------------------------
| Component      | Time (sec)    | Avg/UUID (sec) | % of Total Time  |
-------------------------------------------------------------------------
| Random bytes   | 0.000434      | 0.000000435   | 28.56%            |
| Version bits   | 0.000003      | 0.000000003   | 0.26%            |
| Format string  | 0.000330      | 0.000000330   | 21.66%            |
| UUID validation| 0.000753      | 0.000000753   | 49.50%            |
-------------------------------------------------------------------------
| Total          | 0.001522      | 0.000001522   | 100.00%          |
-------------------------------------------------------------------------
[UUID Test] Single complete UUID generation: 0.000003000 seconds
[UUID Test] UUIDs per second: 1088139.25
```

## License

GPL-3.0 License (same as SourceMod)