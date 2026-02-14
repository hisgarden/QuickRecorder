# SKILLS.md

Project diagnostic resolution patterns for IDE/editor tooling.

## Python: basedpyright `reportMissingImports`

**Symptom**: basedpyright flags `Import "X" could not be resolved` even though the package is installed in the project `.venv`.

**Root cause**: basedpyright uses the system Python interpreter instead of the project venv.

**Fix**:
1. Create `pyrightconfig.json` in the project directory:
   ```json
   {
     "venvPath": ".",
     "venv": ".venv"
   }
   ```
2. Create `requirements.txt` to pin third-party dependencies for reproducibility.

## YAML: Taskfile.yml schema validation errors

**Symptom**: Hundreds of YAML Language Server errors in `Taskfile.yml` — property validation failures and type mismatches.

**Root cause**: SchemaStore auto-applies the Taskfile JSON schema (`https://taskfile.dev/schema.json`). Go template `{{ }}` syntax is incompatible with JSON Schema validation, producing false positives. Any non-standard top-level properties (e.g., `chaindotenv`) also trigger errors.

**Fix**:
1. Add as the first line of `Taskfile.yml`:
   ```yaml
   # yaml-language-server: $schema=
   ```
   This disables auto-applied schema validation.
2. Remove any invalid top-level properties. Valid Taskfile v3 top-level properties:
   `version`, `dotenv`, `env`, `includes`, `interval`, `method`, `output`, `run`, `set`, `shopt`, `silent`, `tasks`, `vars`

