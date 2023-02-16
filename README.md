# Scripts

Bunch of scripts - some are useful, some are throwaway, none of them can be trusted until proven otherwise.

### Relatively safe scripts

- `new-storage-containers.ps1`: Create one or more containers in an Azure Storage account (defaults to local emulator)
- `new-storage-queues.ps1`: Create one or more queues in an Azure Storage account (defaults to local emulator)
- `new-storage-tables.ps1`: Create one or more tables in an Azure Storage account (defaults to local emulator)
- `run-azurite.ps1`: Starts a local Azurite container with a host volume mounted for the emulator's storage.
- `run-sqlserver.ps1`: Starts a local SQL Server container with a valid SA password. Probably needless to say, but **don't use this in production** (either the script or the password).
- `rewrite-json.ps1`: Rewrites a .json file effectively formatting it nicely
- `presto-solutiono.ps1`: Create a .NET solution with unit/integration test projects and hook up all the stuff

### Risky Scripts

The following scripts can (or 'probably will' is better) mess up the files that the scripts operate on. There is an additional `-force` parameter to indicate that the operation should be performed.

Best to make a backup of the files before running the scripts. A full backup of the laptop/desktop is probably even better :)

- `bulk-rename.ps1`: Rename files based on regex group matches

  Chop off the word 'Resource' from the filename:

  `bulk-rename.ps1 C:\Folder\With\The\Files '(.*)Resource.cs' '#1.cs'`

- `Move-UnderscoreToPath.ps1`: Move files with underscores in the name to a subfolder
- `create-buildprops`: Creates a Directory.build.props file at the specified path and removed all the information from the .csproj files. Mildly dangerous, because it also rewrites all the .csproj files it can find.
