#!/bin/bash

# TIMO Question Parser Tool Runner (macOS version)
# This script builds and runs the macOS version of the TIMO Question Parser tool

# Set the working directory to the script's directory
cd "$(dirname "$0")"

# Check if Swift is installed
if ! command -v swiftc &> /dev/null; then
    echo "Error: Swift is required to build and run this tool."
    echo "Please install Xcode or the Swift command-line tools."
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Check macOS version
OS_VERSION=$(sw_vers -productVersion)
echo "macOS version: $OS_VERSION"

# Determine minimum macOS version based on architecture
if [[ "$ARCH" == "arm64" ]]; then
    # Apple Silicon requires macOS 11.0 or later
    MIN_OS="11.0"
else
    # Intel can use macOS 10.15 or later
    MIN_OS="10.15"
fi

# Build the tool
echo "Building TIMO Question Parser tool (macOS version)..."
swiftc -o TIMOQuestionParserMac TIMOQuestionParserMac.swift -sdk $(xcrun --show-sdk-path --sdk macosx) -target $ARCH-apple-macosx$MIN_OS -parse-as-library

# Check if build was successful
if [ $? -eq 0 ]; then
    # Make the executable file executable
    chmod +x TIMOQuestionParserMac
    
    # Run the tool
    echo "Running TIMO Question Parser tool..."
    echo "Note: A GUI window should open. Close the window when you're done."
    echo "Press Ctrl+C to terminate if needed."
    
    # Run the tool
    ./TIMOQuestionParserMac
    
    # Check exit status
    if [ $? -eq 0 ]; then
        echo "TIMO Question Parser tool has finished running successfully."
    else
        echo "TIMO Question Parser tool exited with an error."
        exit 1
    fi
else
    echo "Failed to build TIMO Question Parser tool."
    exit 1
fi 