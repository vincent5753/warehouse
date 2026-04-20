#!/usr/bin/env bash

# Enforce strict error handling
set -euo pipefail

# Detect the operating system
OS="$(uname -s)"

# ==============================================================================
# Helper Functions
# ==============================================================================

gen_N_digit_number() {
    local n=$1
    if ! [[ "$n" =~ ^[0-9]+$ ]]; then
        echo "Error: gen_N_digit_number requires a positive integer." >&2
        return 1
    fi

    if [[ "$OS" == "Linux" ]]; then
        # shuf doesn't read an infinite stream here, but || true is added for absolute safety
        shuf -i 0-9 -n "$n" -r | tr -d '\n' || true
    elif [[ "$OS" == "Darwin" ]]; then
        # Catch the SIGPIPE when head closes the urandom stream
        LC_ALL=C tr -dc '0-9' < /dev/urandom | head -c "$n" || true
    else
        echo "Unsupported OS: $OS" >&2
        return 1
    fi
    echo "" # Append newline for output formatting
}

gen_N_digit_alphabets() {
    local n=$1
    local case_opt=${2:-u} # Default to 'u'
    local charset

    if ! [[ "$n" =~ ^[0-9]+$ ]]; then
        echo "Error: gen_N_digit_alphabets requires a positive integer." >&2
        return 1
    fi

    if [[ "$case_opt" == "l" ]]; then
        charset="a-z"
    else
        charset="A-Z"
    fi

    if [[ "$OS" == "Linux" ]] || [[ "$OS" == "Darwin" ]]; then
        # Unified for both OS since LC_ALL=C is safe and good practice on Linux urandom too
        LC_ALL=C tr -dc "$charset" < /dev/urandom | head -c "$n" || true
    else
        echo "Unsupported OS: $OS" >&2
        return 1
    fi
    echo ""
}

gen_N_digit_string() {
    local n=$1

    if ! [[ "$n" =~ ^[0-9]+$ ]]; then
        echo "Error: gen_N_digit_string requires a positive integer." >&2
        return 1
    fi

    if [[ "$OS" == "Linux" ]] || [[ "$OS" == "Darwin" ]]; then
        LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c "$n" || true
    else
        echo "Unsupported OS: $OS" >&2
        return 1
    fi
    echo ""
}

random_number_in_range() {
    local min=$1
    local max=$2

    # Validate that both inputs are integers (supports negative numbers too)
    if ! [[ "$min" =~ ^-?[0-9]+$ ]] || ! [[ "$max" =~ ^-?[0-9]+$ ]]; then
        echo "Error: random_number_in_range requires two integers." >&2
        return 1
    fi

    # Ensure min is actually less than or equal to max
    if (( min > max )); then
        echo "Error: lower bound ($min) cannot be greater than upper bound ($max)." >&2
        return 1
    fi

    if [[ "$OS" == "Linux" ]]; then
        # GNU shuf handles ranges natively
        shuf -i "$min"-"$max" -n 1 || true
    elif [[ "$OS" == "Darwin" ]]; then
        # BSD jot is standard on macOS and perfect for generating random data in a range
        jot -r 1 "$min" "$max" || true
    else
        echo "Unsupported OS: $OS" >&2
        return 1
    fi
}

gen_url_encoded_iso_date() {
    if [[ "$OS" == "Linux" ]]; then
        # GNU date natively supports %3N for milliseconds. 
        # We output standard ISO format and pipe to sed for URL-encoding the colons.
        date -u +"%Y-%m-%dT%H:%M:%S.%3NZ" | sed 's/:/%3A/g'
    elif [[ "$OS" == "Darwin" ]]; then
        # BSD date lacks native millisecond support. 
        # Using Python3 for precision, replacing colons with %3A directly in the format string.
        python3 -c 'from datetime import datetime, timezone; print(datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%%3A%M%%3A%S.%f")[:-3] + "Z")'
    else
        echo "Unsupported OS: $OS" >&2
        return 1
    fi
}

get_php_session_id() {
    local target_url=${1:-}

    if [[ -z "$target_url" ]]; then
        echo "Error: get_php_session_id requires a target URL." >&2
        return 1
    fi

    local session_id
    # Fetch headers, match case-insensitively (HTTP/2 forces lowercase headers), 
    # split by '=' or ';', and strip the HTTP carriage return (\r)
    session_id=$(curl -s -I "$target_url" | awk -F'[=;]' 'tolower($0) ~ /^set-cookie:[ \t]*phpsessid/ {print $2}' | tr -d '\r')

    if [[ -n "$session_id" ]]; then
        echo "$session_id"
    else
        echo "Error: No PHPSESSID cookie was returned by $target_url" >&2
        return 1
    fi
}

gen_random_ipv4() {
    # Uses Bash's native $RANDOM (0-32767) modulo 256 to generate octets between 0-255.
    # We restrict the first octet to 1-254 to avoid generating strictly invalid IPs (like 0.x.x.x).
    local octet1=$(( (RANDOM % 254) + 1 ))
    local octet2=$(( RANDOM % 256 ))
    local octet3=$(( RANDOM % 256 ))
    local octet4=$(( RANDOM % 256 ))

    echo "${octet1}.${octet2}.${octet3}.${octet4}"
}

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
        echo "No file path provided to check_file_exists()."
        return 1
    fi

    if [[ -f "${file_path}" ]]; then
        echo "File exists: ${file_path}"
        return 0
    else
        echo "File does not exist: ${file_path}"
        return 1
    fi
}

# ==============================================================================
# Execution & Testing
# ==============================================================================

# Only run tests if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    echo "Host OS detected: $OS"
    echo "-----------------------------------"

    echo "1. gen_N_digit_number (10 digits):"
    gen_N_digit_number 10
    echo ""

    echo "2. gen_N_digit_alphabets (10 alphabets, upper [default]):"
    gen_N_digit_alphabets 10
    echo ""

    echo "3. gen_N_digit_alphabets (10 alphabets, lower):"
    gen_N_digit_alphabets 10 l
    echo ""

    echo "4. gen_N_digit_string (15 characters, lowercase alpha + numeric):"
    gen_N_digit_string 15

    echo "5. random_number_in_range (between 6 and 20):"
    random_number_in_range 6 20
    echo ""

    echo "6. random_number_in_range (between 100000 and 999999):"
    random_number_in_range 100000 999999
    echo ""

    echo "7. gen_url_encoded_iso_date (URL-encoded ISO 8601 with ms):"
    gen_url_encoded_iso_date
    echo ""

    echo "8. get_php_session_id (Valid attempt - requires a real PHP site to return an ID):"
    #get_php_session_id "https://somedomain/some.php"
    echo ""

    echo "9. gen_random_ipv4 (Generate a random IP address):"
    gen_random_ipv4
    echo ""

    echo "10. check_file_exists"
    declare file_exist=0
    check_file_exists "/tmp/somefile" || file_exist=$?
    echo ${file_exist}
    echo ""

fi
