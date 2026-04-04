import argparse
import logging
from email import policy
from email.parser import BytesParser
from pathlib import Path
from typing import Optional, Dict, Any
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

def parse_eml(file_path: Path) -> Optional[Dict[str, Any]]:
    """
    Safely parses an .eml file and extracts headers, plain text, and HTML body.

    Args:
        file_path (Path): The path to the target .eml file.

    Returns:
        Optional[Dict[str, Any]]: A dictionary containing parsed email data,
                                  or None if parsing fails.
    """
    if not file_path.is_file():
        logging.error(f"File not found or is not a valid file: {file_path}")
        return None

    try:
        with open(file_path, 'rb') as f:
            msg = BytesParser(policy=policy.default).parse(f)

        email_data = {
            'subject': msg.get('subject', '(No Subject)'),
            'sender': msg.get('from', '(Unknown Sender)'),
            'recipient': msg.get('to', '(Unknown Recipient)'),
            'date': msg.get('date', '(Unknown Date)'),
            'body': {'plain': '', 'html': ''}
        }

        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                content_disposition = str(part.get("Content-Disposition", ""))

                if "attachment" in content_disposition:
                    continue

                try:
                    if content_type == "text/plain":
                        email_data['body']['plain'] += part.get_content()
                    elif content_type == "text/html":
                        email_data['body']['html'] += part.get_content()
                except KeyError:
                    logging.warning(f"Failed to decode a {content_type} part in {file_path}.")
        else:
            content_type = msg.get_content_type()
            if content_type == "text/html":
                email_data['body']['html'] = msg.get_content()
            else:
                email_data['body']['plain'] = msg.get_content()

        return email_data

    except Exception as e:
        logging.error(f"Unexpected error parsing {file_path}: {e}", exc_info=True)
        return None

def main():
    # Set up CLI argument parsing
    parser = argparse.ArgumentParser(
        description="A utility to parse and extract data from .eml files."
    )
    parser.add_argument(
        "-f", "--file",
        type=Path,
        required=True,
        help="Path to the .eml file you want to read."
    )
    
    args = parser.parse_args()
    target_file = args.file

    logging.info(f"Processing file: {target_file}")
    
    result = parse_eml(target_file)

    if result:
        print("\n--- Parsed Email Details ---")
        print(f"Subject: {result['subject']}")
        print(f"From:    {result['sender']}")
        print(f"To:      {result['recipient']}")
        print(f"Date:    {result['date']}")
        print("\n--- Plain Text Body ---")
        print(result['body']['plain'].strip())
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
