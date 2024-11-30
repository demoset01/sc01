#!/bin/bash
# source ./shtdlib.sh


# Checking if a chart name and a version specified
if [ -z "$2" ]; then echo "Please specify a helm chart name and a version"; exit 1; fi
# Checking if Grype is installed
if [ ! $(which grype) ]; then echo "Grype has not been found. Please follow the README instructions"; exit 1; fi
# Checking if Grype is installed
if [ ! $(which curl) ]; then echo "curl has not been found. Please install curl"; exit 1; fi
# Checking if Grype is installed
if [ ! $(which jq) ]; then echo "jq has not been found. Please install jq"; exit 1; fi


# Checking the mode
if [ ! $3 == "" ] && [ ! "$3" == 'full' ] && [ ! $3 == 'light' ]; then echo "The mode name is incorrect. Please specity light or full, or ignore it completely"; exit 1; fi


# Setting constants
SEVERITY_LIST=("Medium" "High" "Critical")
HEADERS='Image:tag Component/library Vulnerability Severity'
CSV_FILE=$(date "+%Y-%m-%d_%H:%M:%S")_$(echo $1 | sed -r 's/\//_/g')_output.csv
ARTIFACTHUB_URL=https://artifacthub.io/api/v1/packages/helm

# setting variables
IMAGES=""
MODE="light"


# Selecting the mode: full or just search in https://artifacthub.io
if [ "$3" == "full" ]; then
    MODE=$3
    echo "Downloading the helm chart $1"
else
    echo "Searching for the helm chart $1 in artifacthub.io..."
    json_data=$(curl -s "$ARTIFACTHUB_URL/$1/$2")
    echo "$json_data" | jq empty >/dev/null 2>&1 
    if [ $? -eq 0 ] && [[ $(echo $json_data | grep "package_id") ]]; then json_verified=1; fi
fi

# Extracting list of images
if [ "$MODE" == "full" ] || [ ! $json_verified ]; then
    echo "The helm chart $1 has not been found in artifacthub.io. Attempting to download the chart"
    TMPDIR=$(mktemp -d)

    if [ -n "$2" ]; then
        result=$(helm search repo $1 --version $2 | awk '{print $1}' | grep -x $1)
        if [ -n "$result" ]; then
            helm pull $1 --version $2 --untar --destination $TMPDIR
        fi
    else 
        result=$(helm search repo $1 | awk '{print $1}' | grep -x $1)
        if [ -n "$result" ]; then
            helm pull $1 --untar --destination $TMPDIR
        fi
    fi
    if [ -z "$result" ]; then echo "The helm chart $1 has not been found. Please add the chart repo."; exit 1; fi

    # parsing values.yaml
    while read line; do
        IMAGES=$IMAGES"#"$(echo $line | awk '{print $2":"$4}')
    done <<< $(cat $TMPDIR/*/values.yaml | grep 'repository: \|tag: ' | tr '\n' ' ' | sed -r 's/(repository: )/#\1/g' | sed -r 's/#/\n/g' | grep tag)
    if [ -d "$TMPDIR" ]; then rm -rf $TMPDIR; fi
else
    IMAGES=$(echo $json_data | jq .containers_images[].image | sed -r 's/"//g' | tr '\n' '#')
fi

echo "---"

# Just in case print the list in advance according to the instructions.
# This block can be completely removed if output image name right before scanning
image_number=$(echo $IMAGES | sed -r 's/#/\n/g' | sed -r '/^[[:space:]]*$/d' | wc -l)
if [ $image_number -gt 0 ]; then
    echo "There is(are) $image_number image(s) in the helm chart $1"
    echo $IMAGES | sed -r 's/#/\n/g' | sed -r '/^[[:space:]]*$/d' | while read image_item; do
        if [ -n "$image_item" ]; then echo $image_item; fi
    done
fi

echo "---"
echo "Scanning images..." 

# Creating csv file with headers
echo "$HEADERS" | sed -r 's/[[:space:]]/,/g' >> "$CSV_FILE"

# iterate through images to scan them and save the result
echo $IMAGES | sed -r 's/#/\n/g' | while read image; do
    if [ -n "$image" ]; then
        grype $image --scope all-layers -o template -t template.tmpl | sed -r '/^[[:space:]]*$/d' | while read item; do
            severity=$(echo $item | awk '{print $3}')
            # Filtering by the severity
            if [[ " ${SEVERITY_LIST[@]} " =~ " $severity " ]]; then
                echo "$image $item" | sed -r 's/[[:space:]]/,/g' >> "$CSV_FILE"
            fi
        done
    fi
done

echo "---"
echo "The reports saved in $CSV_FILE"

