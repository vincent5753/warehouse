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
fi
