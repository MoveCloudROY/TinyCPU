#!/bin/bash

ldscript="linker.ld"
opt="-O2"


# Get the directory path where the shell script is located
script_directory=$(dirname "$(readlink -f "$0")")

# Check if file paths are provided as parameters
if [ "$#" -lt 1 ]; then
    echo "Please provide the paths to the C and assembly files as parameters."
    exit 1
fi

# Get the output file name if provided as an optional parameter
output_file_name="output"
if [ "$#" -gt 1 ]; then
    output_file_name="${!#}"
fi

# Change to the script directory
cd "$script_directory" || exit

# Create an array to store the object files
object_files=()

# Iterate over the provided file paths
for file_path in "${@:1:(( $# > 1 ? $# - 1 : $# ))}"; do
    # Construct the full path of the file
    full_path="$script_directory/$file_path"

    # Check if the provided file exists
    if [ ! -f "$full_path" ]; then
        echo "File $file_path does not exist."
        continue
    fi

    # Get the file extension
    extension="${file_path##*.}"

    # Check if the file has a .c or .s extension
    if [ "$extension" != "c" ] && [ "$extension" != "s" ]; then
        echo "Invalid file type. Only C and assembly (.s) files are supported."
        continue
    fi

    # Extract the filename without extension
    filename=$(basename "$file_path")
    filename="${filename%.*}"

    # Compile the file to an object file
    if [ "$extension" == "c" ]; then
        loongarch32r-linux-gnusf-gcc ${opt} -fno-pie -fno-builtin -mabi=ilp32s -nostdinc -nostdlib -ffreestanding -nostartfiles --sysroot=${LOONGTARGETSYSROOT} -o "$filename.S" -S "$full_path"
        loongarch32r-linux-gnusf-gcc ${opt} -fno-pie -fno-builtin -mabi=ilp32s -nostdinc -nostdlib -ffreestanding -nostartfiles --sysroot=${LOONGTARGETSYSROOT} -o "$filename.o" "$full_path"
    else
        loongarch32r-linux-gnusf-gcc ${opt} -fno-pie -fno-builtin -mabi=ilp32s -nostdinc -nostdlib -ffreestanding -nostartfiles --sysroot=${LOONGTARGETSYSROOT} -c -o "$filename.o" "$full_path"
    fi

    # Check if the compilation was successful
    if [ $? -eq 0 ]; then
        echo "Compilation successful for $file_path."
        object_files+=("$filename.o")
    else
        echo "Compilation failed for $file_path."
    fi
done

# Link the object files into a single executable
if [ "${#object_files[@]}" -gt 0 ]; then

    loongarch32r-linux-gnusf-gcc ${opt} -static -nostdinc -nostdlib -ffreestanding -nostartfiles --sysroot=${LOONGTARGETSYSROOT} -o "$output_file_name.elf" "${object_files[@]}" -T $ldscript
    if [ $? -eq 0 ]; then
        echo "Linking successful. The executable '$output_file_name.elf' is created."
    else
        echo "Linking failed."
    fi
fi


# Strip the Binary file
# loongarch32r-linux-gnusf-strip --strip-all "$output_file_name.elf"
# Check if the strip was successful
if [ $? -eq 0 ]; then
    echo "Strip successful."
else
    echo "Strip failed."
fi

# Preview the RAW Binary file
loongarch32r-linux-gnusf-objdump -fd "$output_file_name.elf"

# Dump the code into a RAW Binary file
loongarch32r-linux-gnusf-objcopy -O binary -j .text "$output_file_name.elf" "${output_file_name}_inst.bin"
loongarch32r-linux-gnusf-objcopy -O binary -j .data "$output_file_name.elf" "${output_file_name}_data.bin"
# Check if the strip was successful
if [ $? -eq 0 ]; then
    echo "Dump successful. The RAW Binary is created."
else
    echo "Dump failed."
fi

# clear *.o
echo rm -- *.o
rm *.o
