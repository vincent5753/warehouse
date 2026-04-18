#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Logging Functions
# =============================================================================

readonly COLOR_INFO='\033[0;32m'
readonly COLOR_ERROR='\033[0;31m'
readonly COLOR_RESET='\033[0m'

# -----------------------------------------------------------------------------
# def _info(message: str) -> None:
# """
# Logs an informational message to STDOUT with a timestamp.
# 
# Args:
#     message (str): The text to log.
# """
# -----------------------------------------------------------------------------
_info() {
    declare -r message="$1"
    echo -e "${COLOR_INFO}[INFO] $(date +'%Y-%m-%d %H:%M:%S') - ${message}${COLOR_RESET}"
}

# -----------------------------------------------------------------------------
# def _error(message: str) -> None:
# """
# Logs an error message to STDERR with a timestamp.
# 
# Args:
#     message (str): The error text to log.
# """
# -----------------------------------------------------------------------------
_error() {
    declare -r message="$1"
    echo -e "${COLOR_ERROR}[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - ${message}${COLOR_RESET}" >&2
}

# =============================================================================
# Helper Functions
# =============================================================================

# -----------------------------------------------------------------------------
# def check_file_exists(file_path: str) -> int:
# """
# Validates whether a given file path exists and is a regular file.
# 
# Args:
#     file_path (str): The absolute or relative path to the file.
# 
# Returns:
#     int: 0 (True) if the file exists, 1 (False) if it does not or is empty.
# """
# -----------------------------------------------------------------------------
check_file_exists() {
    declare -r file_path="$1"
    
    if [[ -z "${file_path}" ]]; then
        _error "No file path provided to check_file_exists()."
        return 1
    fi

    if [[ -f "${file_path}" ]]; then
        _info "File exists: ${file_path}"
        return 0
    else
        _error "File does not exist: ${file_path}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# def mount_device(device: str, mount_point: str) -> int:
# """
# Safely mounts a block device or loopback file to a specified directory.
# Checks existence, directory validity, and unmounts if already in use.
# 
# Args:
#     device (str): Path to the device (e.g., '/dev/sdb1') or loopback file.
#     mount_point (str): Path to the target directory (e.g., '/mnt/data').
# 
# Returns:
#     int: 0 on successful mount, 1 on validation or execution failure.
# """
# -----------------------------------------------------------------------------
mount_device() {
    declare -r device="$1"
    declare -r mount_point="$2"

    if [[ -z "${device}" || -z "${mount_point}" ]]; then
        _error "Usage: mount_device <device> <mount_point>"
        return 1
    fi

    if [[ ! -e "${device}" ]]; then
        _error "Device or file does not exist: ${device}"
        return 1
    fi

    if [[ ! -d "${mount_point}" ]]; then
        _error "Mount point does not exist: ${mount_point}"
        return 1
    fi

    if mountpoint -q "${mount_point}"; then
        _info "Mount point '${mount_point}' is currently in use. Unmounting first..."
        umount "${mount_point}"
        _info "Successfully unmounted '${mount_point}'."
    fi

    _info "Mounting '${device}' to '${mount_point}'..."
    mount "${device}" "${mount_point}"
    _info "Mount successful."
}

# -----------------------------------------------------------------------------
# def read_toml_value(config_file: str, key: str) -> str | int:
# """
# Parses a TOML file to extract the string value of a specific top-level key.
# Outputs the value to STDOUT for capture via command substitution.
# 
# Args:
#     config_file (str): Path to the TOML configuration file.
#     key (str): The exact key name to search for.
# 
# Returns:
#     int: 0 on success, 1 on failure (outputs parsed string value to STDOUT).
# """
# -----------------------------------------------------------------------------
read_toml_value() {
    declare -r config_file="$1"
    declare -r key="$2"

    if [[ -z "${config_file}" || -z "${key}" ]]; then
        _error "Usage: read_toml_value <config_file> <key>"
        return 1
    fi

    check_file_exists "${config_file}" || return 1

    declare val
    val=$(awk -v k="${key}" '
        $0 ~ "^[[:space:]]*" k "[[:space:]]*=" {
            sub("^[[:space:]]*" k "[[:space:]]*=[[:space:]]*", "")
            sub(/^"/, "")
            sub(/"[[:space:]]*$/, "")
            sub(/^'\''/, "")
            sub(/'\''[[:space:]]*$/, "")
            print $0
            exit 0
        }
    ' "${config_file}")

    if [[ -z "${val}" ]]; then
        _error "Key '${key}' not found in ${config_file}"
        return 1
    fi

    echo "${val}"
}

# =============================================================================
# Main Execution
# =============================================================================

# -----------------------------------------------------------------------------
# def main(*args: list[str]) -> None:
# """
# Primary entry point for the script. Executes example workflows.
# """
# -----------------------------------------------------------------------------
main() {
    _info "Starting script execution..."

    declare -r dummy_file="/tmp/dummy_config.toml"
    touch "${dummy_file}"
    check_file_exists "${dummy_file}"

    echo 'server_port = "8080"' > "${dummy_file}"
    declare port
    port=$(read_toml_value "${dummy_file}" "server_port")
    _info "Parsed TOML value for server_port: ${port}"

    _info "Script completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
