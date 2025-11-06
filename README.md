# Scripts

Bunch of scripts - some are useful, some are throwaway, none of them can be
trusted until proven otherwise.

### Relatively safe scripts

- `new-storage-containers`: Create one or more containers in an Azure Storage
  account (defaults to local emulator)
- `new-storage-queues`: Create one or more queues in an Azure Storage account
  (defaults to local emulator)
- `new-storage-tables`: Create one or more tables in an Azure Storage account
  (defaults to local emulator)
- `run-azurite`: Starts a local Azurite container with a host volume mounted for
  the emulator's storage.
- `run-sqlserver`: Starts a local SQL Server container with a valid SA password.
  Probably needless to say, but **don't use this in production** (either the
  script or the password).
- `run-postgres`: Starts a local PostgreSQL container with a password for the
  `postgres` user. Probably needless to say, but **don't use this in
  production** (either the script or the password).
- `rewrite-json`: Rewrites a .json file effectively formatting it nicely
- `presto-solutiono`: Create a .NET solution with unit/integration test projects
  and hook up all the stuff
- `update-pat.sh`: Updates the github personal access token to the personal
  access token stored in `GITHUB_PAT`
- `generate-api.sh`: Generates a Typescript API file from an OpenApi spec
- `merge-repos.sh`: Merge two repositories into one while keeping history
- `create-react-webapp.sh`: Create a React webapp with Tailwind and Shadcn. Uses
  `jq`, `npm` and a bunch of packages to do the job.

### Risky Scripts

The following scripts can (or 'probably will' is better) mess up the files that
the scripts operate on. There is an additional `-force` parameter to indicate
that the operation should be performed.

Best to make a backup of the files before running the scripts. A full backup of
the laptop/desktop is probably even better :)

- `bulk-rename`: Rename files based on regex group matches

    Chop off the word 'Resource' from the filename:

    `bulk-rename.ps1 C:\Folder\With\The\Files '(.*)Resource.cs' '#1.cs'`

- `Move-UnderscoreToPath`: Move files with underscores in the name to a
  subfolder
- `create-buildprops`: Creates a Directory.build.props file at the specified
  path and removed all the information from the .csproj files. Mildly dangerous,
  because it also rewrites all the .csproj files it can find.
- `reinstall-packages`: Reinstall existing packages for all projects in a
  folder. Typically this updates the used packages to the latest version.

### Az CLI

Scripts that use the
[Az CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) and
require an `az login` before anything:

- `gimme-webapp-settings`: List Azure webapp configuration values and convert
  the bunch into an appsettings.development.json format

### Scratch pad

Scripts (or rather, some vague ideas) that need some tweaking and a lot of
testing, but are now still a bit useless:

- `azdevops-yamlify`: Create an Azure Devops .yml wrapper so it can be included
  in a pipeline.
- `azdeploy-stuff`: Deploy Bicep resources & webapp
- `azregister-app`: Create/Update app registration & update roles
