import pytest
import io
from dotenv import dotenv_values

# ---------------------------------------------------------
# 1. Execute a Custom Command
# ---------------------------------------------------------
def test_custom_command_execution(host):
    # Execute a command and capture the result
    result = host.run("uptime")
    
    # Verify the exit code is 0 (success)
    assert result.rc == 0
    # Verify the output contains expected data
    assert "load average" in result.stdout

# ---------------------------------------------------------
# 2. Verify Symbolic Link Location
# ---------------------------------------------------------
def test_symlink_destination(host):
    # Define the path to the symlink
    symlink_file = host.file("/var/www/html/current")
    
    # Ensure it exists and is actually a symlink
    assert symlink_file.is_symlink
    # Verify it resolves to the correct target directory
    assert symlink_file.linked_to == "/var/www/html/releases/v2.0"

# ---------------------------------------------------------
# 3. Mount a Disk Partition to a Mount Point
# ---------------------------------------------------------
# We use a pytest fixture to handle the state change (mounting).
# The 'yield' ensures the disk is safely unmounted after the test runs.
@pytest.fixture(scope="module")
def mounted_disk(host):
    partition = "/dev/sdb1"
    mount_point = "/mnt/app_data"
    
    # Setup: Create directory and mount the disk
    host.run(f"sudo mkdir -p {mount_point}")
    mount_cmd = host.run(f"sudo mount -t ext4 {partition} {mount_point}")
    assert mount_cmd.rc == 0, f"Failed to mount: {mount_cmd.stderr}"
    
    yield mount_point  # Pass the mount point to the test function
    
    # Teardown: Safely unmount after tests complete
    host.run(f"sudo umount {mount_point}")

def test_disk_partition_is_mounted(host, mounted_disk):
    # Validate the kernel mount table
    mount_info = host.mount_point(mounted_disk)
    
    assert mount_info.exists
    assert mount_info.device == "/dev/sdb1"
    assert mount_info.filesystem == "ext4"
    assert "rw" in mount_info.options

# ---------------------------------------------------------
# 4. Check Content of a Specific File
# ---------------------------------------------------------
def test_specific_file_content(host):
    config_file = host.file("/etc/nginx/nginx.conf")
    
    assert config_file.exists
    assert config_file.is_file
    # Check if the file contains a specific configuration directive
    assert config_file.contains("worker_processes auto;")

# ---------------------------------------------------------
# 5. Check PHP Config (.env) Key Values
# ---------------------------------------------------------
def test_php_env_configuration(host):
    env_file = host.file("/var/www/html/.env")
    assert env_file.exists
    
    # Securely stream the remote file content into local memory
    # as a string without saving it to the local test machine's disk.
    env_content = env_file.content_string
    
    # Wrap the string in StringIO to mimic a file stream, then
    # parse it safely using python-dotenv so we don't pollute local env vars.
    parsed_env = dotenv_values(stream=io.StringIO(env_content))
    
    # Assert specific keys are set to your desired values
    assert parsed_env.get("APP_ENV") == "production"
    assert parsed_env.get("DB_CONNECTION") == "mysql"
    assert parsed_env.get("APP_DEBUG") == "false"

# ---------------------------------------------------------
# 6. Check if a Specific Disk is Mounted at Specific Mount Point
# ---------------------------------------------------------
@pytest.mark.parametrize("device, mount_point, fstype", [
    ("/dev/sdb1", "/mnt/app_data", "ext4"),
    # You can easily add more disks to check here:
    # ("/dev/sdc1", "/mnt/backup", "xfs"),
])
def test_specific_disk_mounted_at_point(host, device, mount_point, fstype):
    # Fetch the mount point information from the host
    mount_info = host.mount_point(mount_point)
    
    # Verify the mount point exists and is actively mounted
    assert mount_info.exists, f"No active mount found at {mount_point}"
    
    # Verify the correct device is mounted at this point
    assert mount_info.device == device, f"Expected device {device} at {mount_point}, but found {mount_info.device}"
    
    # Verify the filesystem matches what we expect
    assert mount_info.filesystem == fstype, f"Expected {fstype} filesystem, but found {mount_info.filesystem}"

# ---------------------------------------------------------
# 7. Check if a Specific File Contains Specific Line of Text
# ---------------------------------------------------------
@pytest.mark.parametrize("file_path, expected_line", [
    ("/etc/ssh/sshd_config", "PermitRootLogin no"),
    ("/etc/timezone", "Australia/Melbourne"),
    # Add more file paths and lines as needed
])
def test_file_contains_exact_line(host, file_path, expected_line):
    target_file = host.file(file_path)
    
    # Ensure the file actually exists before trying to read it
    assert target_file.exists, f"The file {file_path} does not exist"
    assert target_file.is_file, f"The path {file_path} exists but is not a regular file"
    
    # Get the file content as a string and split it into a list of lines.
    # We do this instead of target_file.contains() because .contains() uses regex/substring matching.
    # Splitting into lines ensures we are matching the *exact* line of text, preventing false positives.
    file_lines = target_file.content_string.splitlines()
    
    # Strip whitespace from the lines just in case of trailing spaces, then check for the expected line
    cleaned_lines = [line.strip() for line in file_lines]
    assert expected_line in cleaned_lines, f"Exact line '{expected_line}' was not found in {file_path}"
