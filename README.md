# Scripts

Bunch of scripts - some are useful, some are throwaway, none of them can be trusted until proven otherwise.

### Relatively safe scripts

- `new-storage-containers.ps1`: Create one or more containers in an Azure Storage account (defaults to local emulator)
- `new-storage-queues.ps1`: Create one or more queues in an Azure Storage account (defaults to local emulator)
- `new-storage-tables.ps1`: Create one or more tables in an Azure Storage account (defaults to local emulator)
- `run-localazurite.ps1`: Starts a local Azurite container with a host volume mounted for the emulator's storage.
- `rewrite-json.ps1`: Rewrites a .json file effectively formatting it nicely

### Risky Scripts

The following scripts can (or 'probably will' is better) mess up the files that the scripts operate on. There is an additional `-force` parameter to indicate that the operation should be performed.

Best to make a backup of the files before running the scripts. A full backup of the laptop/desktop is probably even better :)

- `bulk-rename.ps1`: Rename files based on regex group matches

  Chop off the word 'Resource' from the filename:

  `bulk-rename.ps1 C:\Folder\With\The\Files '(.*)Resource.cs' '#1.cs'`
