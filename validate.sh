#!/usr/bin/env bash

# Enable strict mode with command tracing
set -uex

# ModusToolbox installation directory
# override with "export MTB_DIR=/opt/ModusToolbox"
MTB_DIR="${MTB_DIR:-$HOME/ModusToolbox}"

# Validate modified ModusToolbox manifest
# Arguments:
# $1 - GitHub <namespace>/<repo>, for example: vmedcy/mtb-mw-manifest
# $2 - GitHub branch name, for example: topic/vmedcy-fix
function validate()
{
    if [[ $# -ne 2 ]]; then
        echo "Expected 2 arguments: REPO BRANCH"
        echo "Examples:"
        echo "$0 cypresssemiconductorco/mtb-mw-manifest v2.X"
        echo "$0 \$GITHUB_REPOSITORY \$GITHUB_REF"
        exit 1
    fi

    local github_repo="$1"
    local github_branch="${2#refs/heads/}" # Remove refspec prefix from GITHUB_REF

    # cypresssemiconductorco/mtb-mw-manifest -> mtb-mw-manifest
    local github_reponame="$(basename "$github_repo")"

    # delete test data from previous script runs
    rm -rf expected observed
    mkdir  expected observed

    # Fetch official ModusToolbox super manifests
    curl -LsSfO https://github.com/cypresssemiconductorco/mtb-super-manifest/raw/v2.X/mtb-super-manifest.xml
    curl -LsSfO https://github.com/cypresssemiconductorco/mtb-super-manifest/raw/v2.X/mtb-super-manifest-fv2.xml

    # Tweak the manifest URIs in the super manifest to point to the custom repo/branch
    sed -e "s;https://github.com/cypresssemiconductorco/$github_reponame/raw/v2.X/;https://github.com/$github_repo/raw/$github_branch/;g" -i mtb-super-manifest.xml -i mtb-super-manifest-fv2.xml

    # Test MTB 2.0/2.1 tools with legacy super manifest
    export CyRemoteManifestOverride="file://$PWD/mtb-super-manifest.xml"

    # Test ModusToolbox 2.0 Project Creator CLI output
    "$MTB_DIR/tools_2.0/project-creator/project-creator-cli" --list-boards | sed '1,/List of BSPs:/!d'> observed/mtb20.txt 2>&1
    cat << EOF > expected/mtb20.txt
Getting manifest...
super-manifest: file://$PWD/mtb-super-manifest.xml
Successfully acquired BSP/Application information from remote server.
List of BSPs:
EOF

    # Test ModusToolbox 2.1 Project Creator CLI output
    "$MTB_DIR/tools_2.1/project-creator/project-creator-cli" --list-boards | sed '1,/List of BSPs:/!d'> observed/mtb21.txt 2>&1
    cat << EOF > expected/mtb21.txt
Getting manifest...
Processing super-manifest $CyRemoteManifestOverride...
Successfully acquired the information.
List of BSPs:
EOF

    # Test MTB 2.2/2.3 tools with fv2 super manifest
    export CyRemoteManifestOverride="file://$PWD/mtb-super-manifest-fv2.xml"

    # Test ModusToolbox 2.2 Project Creator CLI output
    "$MTB_DIR/tools_2.2/project-creator/project-creator-cli" --list-boards | sed '1,/List of BSPs:/!d'> observed/mtb22.txt 2>&1
    cat << EOF > expected/mtb22.txt
Getting manifest...
Found environment variable CyRemoteManifestOverride=$CyRemoteManifestOverride
Processing super-manifest $CyRemoteManifestOverride...
Successfully acquired the information.
List of BSPs:
EOF

    # Test ModusToolbox 2.3 Project Creator CLI output
    "$MTB_DIR/tools_2.3/project-creator/project-creator-cli" --list-boards | sed '1,/List of BSPs:/!d'> observed/mtb23.txt 2>&1
    cat << EOF > expected/mtb23.txt
Getting manifest...
Checking if remote manifest is accessible...
Found environment variable CyRemoteManifestOverride=$CyRemoteManifestOverride
Processing super-manifest $CyRemoteManifestOverride...
Successfully acquired the information.
List of BSPs:
EOF

    unset CyRemoteManifestOverride
    echo

    # Analyze whether the observed project-creator-cli output matches the expected patterns
    # Note: diff returns non-zero status code in case the non-empty difference is reported
    diff -ru expected observed
}

validate $@
