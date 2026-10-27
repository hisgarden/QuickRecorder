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



## File Changelog Convention

**Rule**: All `Taskfile.yml` and `*.sh` scripts must include a changelog block at the end of the file.

**Format** (shell scripts and Taskfile.yml):
```
################################################################################
# Changelog:
# YYYY-MM-DD  Brief description of change
# YYYY-MM-DD  Another change (most recent first)
################################################################################
```

For YAML files (Taskfile.yml), use `#` comment prefix:
```yaml
# ##############################################################################
# Changelog:
# YYYY-MM-DD  Brief description of change
# ##############################################################################
```

**Rules**:
- Most recent entry first (reverse chronological)
- One line per change, date + 2-space gap + description
- Keep descriptions concise (< 80 chars)
- Add an entry for every commit that modifies the file

