# Helm chart vulnerability scanner

## Description
This project is a Bash script that scans Helm chart images for vulnerabilities. It leverages [Grype](https://github.com/anchore/grype) as the image scanner.

### Features:
- Outputs a list of images in the chart.
- Generates a CSV file summarizing vulnerabilities by severity: Medium, High, and Critical.
- Ignores whether vulnerabilities are fixed.
- Allows configurable severity thresholds directly in the script.

### Modes:
The script supports two modes of operation:

**Light Mode** (default):
- Searches for the Helm chart on ArtifactHub.
- Extracts a list of images from the Helm chart page without downloading the chart.
- Scans only the base image, making it faster.

**Full Mode:** 
- Downloads the Helm chart.
- Parses the values.yaml file to extract the list of images for scanning.
- Setup and Run Instructions
- Follow these steps to set up and run the project:

### Clone the Repository:

```Bash
git clone https://github.com/demoset01/sc01.git
cd sc01
```

### Install Dependencies: Ensure you have the required dependencies installed:

#### Install **`Grype`**

```bash
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

Or follow the instructions on https://github.com/anchore/grype

#### Install **`Helm`**

Follow the instructions on [helm](https://helm.sh/docs/intro/install/)

#### Install **`jq`**

Follow the instructions on [jq](https://jqlang.github.io/jq/download/) 



### Run the Project: Execute the main script:

```bash
bash scan.sh <helm_name> <helm_version> <mode>
```
**`helm_name`** - helm chart name (e.g., bitnami/nginx)
**`helm_version`** - helm chart version(e.g., 18.2.6)
**`mode`** - *(Optional)* **`light`** or **`full`**. The default is light.

### Design Decisions
1. **Bash over Python**: Initially considered implementing in Python but opted for Bash to simplify system calls, subprocess handling, and output management.
2. **Light mode**: I was curious if it's possible to extract a list of images in a chart without downloading the chart, and I came up with an idea of scraping https://artifacthub.io. Half way through I relalised that there is a descrepancy between what the https://artifacthub.io returns and the list of images in the values.yaml, so I decided to implement both. This added some complexity but I didn't want to give on the light mode.
3. **Choice of Grype**: Selected Grype because it was the first in the list of scanners evaluated and worked seamlessly.
4. **Template**: Added template.tmpl to filter unnecessary data from Grype's output. Grype's JSON output was sometimes invalid, so relying on structured filtering was more reliable.

### Code Suggestions:
AI assistance was used to generate a basic template for this README.md file, saving time on formatting and structuring. 


### Future Improvements
### Given more time, the following enhancements would be implemented:

1. **Argument Handling:** Use getopts for more robust parsing and validation of script arguments.
2. **Input Validation:** Add regular expressions to validate argument values.
3. **Code Reusability:** Refactor the script into modular functions for better maintainability.
4. **Multiple Scanner Options:** Add support for choosing between different image scanners or using both simultaneously.
5. **Logging:** Add logging of each run
6. **Tests:** Add tests to verify output
5. **Documentation and Comments:** Improve inline comments and provide detailed examples for users.