#!/bin/bash

# Function to print a message with asterisks
print_message_with_asterisks() {
    local message="$1"
    local message_length=${#message}
    local asterisks=""

    for ((i = 0; i < message_length + 4; i++)); do
        asterisks+="*"
    done

    echo "$asterisks"
    echo "* $message *"
    echo "$asterisks"
}

# Function to print the asterisk notification
print_asterisk_notification() {
    clear
    local notification="Python 3.10 is not installed on this system."
    print_message_with_asterisks "$notification"
    exit 1
}

# Function to validate the Python version
validate_python_version() {
    if command -v python3.10 &>/dev/null; then
        print_message_with_asterisks "Python 3.10 is installed."
    else
        print_asterisk_notification
    fi
}

# Function to print the banner
print_banner() {
    local today_date=$(date +"%m/%d/%Y")
    local credits="Don Irwin ($today_date) Inspired by John Danson's work"
    
    print_message_with_asterisks "AWS Layer Helper"
    echo
    
    # Calculate the center alignment for the credits
    local align=$(( (30 - ${#credits}) / 2 ))
    print_message_with_asterisks "$credits"
    echo
}

# Function to install c9 globally if not already installed
install_c9() {
    if ! command -v c9 &>/dev/null; then
        print_message_with_asterisks "Installing c9 globally using npm..."
        npm install -g c9
        print_message_with_asterisks "c9 has been installed."
    else
        print_message_with_asterisks "c9 is already installed."
    fi
}

# Function to set up the virtual environment
setup_virtual_environment() {
    print_message_with_asterisks "Setting up virtual environment"
    
    rm -rf python
    mkdir python
    python -m venv "$1"
    source "./$1/bin/activate"
    
}

#function to open requirements.txt
open_requirements(){
    
    if [ ! -f "requirements.txt" ]; then
        touch requirements.txt
    fi
    
    c9 requirements.txt
    
    print_message_with_asterisks "The requirements have been opened. Once you are finished, press Enter to continue."
    read -p "Press Enter to continue..."

}

# Function to check if the requirements.txt file exists and has valid contents
check_requirements() {
    if [ -f "requirements.txt" ]; then
        if [ ! -s "requirements.txt" ]; then
            print_message_with_asterisks "requirements.txt exists but is empty. Please add requirements to the file."
            exit 1
        else
            # Check if the file contains at least one line that is not a comment or empty
            if grep -q -vE "^\s*#|^\s*$" "requirements.txt"; then
                print_message_with_asterisks "requirements.txt has valid contents."
            else
                print_message_with_asterisks "requirements.txt is empty or contains only comments. Please add valid requirements."
                exit 1
            fi
        fi
    else
        print_message_with_asterisks "requirements.txt does not exist. Please create and add requirements to the file."
        exit 1
    fi
}


# Function to prompt user to confirm they want to move forward
are_you_sure() {
    print_message_with_asterisks "Are you sure you want to proceed?"
    read -p "Type 'yes' to continue or 'no' to exit: " confirmation
    if [ "$confirmation" != "yes" ]; then
        exit 0
    fi
}


# Function to validate AWS S3 LS command response with asterisks
validate_aws_s3_ls() {
    # Run the AWS S3 LS command and capture the output
    aws_s3_ls_output=$(aws s3 ls 2>&1)

    # Check if the command was successful (exit code 0) and the output is not empty
    if [ $? -eq 0 ] && [ -n "$aws_s3_ls_output" ]; then
        print_message_with_asterisks "AWS S3 LS command returned a valid response:"
        echo "$aws_s3_ls_output"
    else
        print_message_with_asterisks "AWS S3 LS command did not return a valid response."
        exit 1
    fi
}


# Function to configure AWS CLI
configure_aws() {
    print_message_with_asterisks "Configuring AWS CLI"
    aws configure

    # Check if the AWS configuration was successful
    if [ $? -eq 0 ]; then
        print_message_with_asterisks "AWS CLI configuration completed successfully."
    else
        print_message_with_asterisks "AWS CLI configuration failed. Please check your input and try again."
    fi
}


# Function to validate the layer name format (allows periods)
validate_layer_name() {
    read -p "Enter the layer name (a-z, A-Z, 0-9, hyphens, and periods allowed): " layer_name
    if [[ "$layer_name" =~ ^[a-zA-Z0-9-.]+$ ]]; then
        echo "Layer name is valid: $layer_name"
    else
        print_message_with_asterisks "Invalid layer name format. Please use only a-z, A-Z, 0-9, hyphens, and periods."
        validate_layer_name
    fi
}



# Main script
print_banner

# Check if Python 3.10 is installed
validate_python_version

# Install c9 globally if not already installed
install_c9

# Prompt the user for the layer name (including periods)
validate_layer_name

# Set up the virtual environment
setup_virtual_environment "$layer_name"

#open requirements for editing
open_requirements

# Check requirements and open if there's an error
check_requirements
if [ $? -eq 1 ]; then
    open_requirements
fi

# Prompt user to confirm if they want to proceed
are_you_sure

# Validate AWS S3 LS command response
validate_aws_s3_ls

do_loop=true
# Check if the validation was successful
if [ $? -ne 0 ]; then
    # Main loop
    while do_loop; do
        # Configure AWS CLI
        configure_aws
        # Validate AWS S3 LS command response
        validate_aws_s3_ls        
        if [ $? -ne 0 ]; then
            print_message_with_asterisks "The AWS credentials may still not be correct."
            # Ask the user if they want to continue
            print_message_with_asterisks "Do you want to proceed? (Type 'yes' to continue or 'no' to exit): "
            read -p "" confirmation
            if [ "$confirmation" != "yes" ]; then
                exit 0
            fi
        else
            do_loop=false
            
        fi
    done
fi
