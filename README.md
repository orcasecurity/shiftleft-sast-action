# Orca Shift Left Security Action

[GitHub Action](https://github.com/features/actions)
for [Orca Shift Left Security](https://orca.security/solutions/shift-left-security/)

#### More info can be found in the official Orca Shift Left Security<a href="https://docs.orcasecurity.io/v1/docs/shift-left-security"> documentation</a>

## Table of Contents

- [Usage](#usage)
  - [Workflow](#workflow)
  - [Inputs](#inputs)
- [Annotations](#annotations)

## Usage

### Workflow

```yaml
name: Sample Orca SAST Scan Workflow
on:
  # Scan for each push event on your protected branch. If you have a different branch configured, please adjust the configuration accordingly by replacing 'main'.
  push:
    branches: ["main"]
  # NOTE: To enable scanning for pull requests, uncomment the section below.
  #pull_request:
  #branches: [ "main" ]
  # NOTE: To schedule a daily scan at midnight, uncomment the section below.
  #schedule:
  #- cron: '0 0 * * *'
jobs:
  orca-sast_scan:
    name: Orca SAST Scan
    runs-on: ubuntu-latest
    env:
      PROJECT_KEY: <project key> # Set the desired project to run the cli scanning with
    steps:
      # Checkout your repository under $GITHUB_WORKSPACE, so your job can access it
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          # Important for pull request diff-awareness report
          fetch-depth: 0
      - name: Run Orca SAST Scan
        uses: orcasecurity/shiftleft-sast-action@v1
        with:
          api_token: ${{ secrets.ORCA_SECURITY_API_TOKEN }}
          project_key: ${{ env.PROJECT_KEY }}
          path:
            # scanning the entire repository
            "."
```

### Inputs

| Variable         | Example Value &nbsp;           | Description &nbsp;                                                                | Type    | Required | Default           |
| ---------------- | ------------------------------ | --------------------------------------------------------------------------------- | ------- | -------- | ----------------- |
| api_token        |                                | Orca API Token used for Authentication                                            | String  | Yes      | N/A               |
| project_key      | my-project-key                 | Project Key name                                                                  | String  | Yes      | N/A               |
| path             | src/main/java,mt-dir/          | Paths or directories to scan (comma-separated)                                    | String  | Yes      | N/A               |
| exclude_paths    | src/test/java,./notToBeScanned | List of paths to be excluded from scan (comma-separated)                          | String  | No       | N/A               |
| format           | json                           | Format for displaying the results                                                 | String  | No       | cli               |
| output           | results/                       | Output directory for scan results                                                 | String  | No       | N/A               |
| no_color         | false                          | Disable color output                                                              | Boolean | No       | false             |
| exit_code        | 10                             | Exit code for failed execution due to policy violations                           | Integer | No       | 3                 |
| silent           | false                          | Disable logs and warnings output                                                  | Boolean | No       | false             |
| console_output   | json                           | Prints results to console in the provided format (only when --output is provided) | String  | No       | cli               |
| config           | config.json                    | Path to configuration file (json, yaml or toml)                                   | String  | No       | N/A               |
| show_annotations | true                           | Show github annotations on pull requests                                          | Boolean | No       | true              |
| max_file_size    | 3                              | Maximum file size to be scanned in MB. Bigger files will be skipped               | Integer | No       | 5                 |
| display_name     | custom-display-name            | Scan log display name (on Orca platform)                                          | String  | No       | N/A               |
| debug            | true                           | Debug mode                                                                        | Boolean | No       | false             |
| log_path         | results/                       | The directory path to specify where the logs should be written to on debug mode.  | String  | No       | working directory |
| custom_sast_controls | custom_control/ | Path to custom SAST controls **directory** | String | No | N/A |

## Annotations

After scanning, the action will add the results as annotations in a pull request:

![](/assets/annotations_preview.png)

> **NOTE:** Annotations can be disabled by setting the "show_annotation" input to "false"
