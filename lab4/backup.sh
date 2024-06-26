#!/bin/bash

# Set the source and destination directories
source_dir=/home/user/source
backup_dir=/home/user

current_date=$(date +%Y-%m-%d)
# Check if a backup directory for the current date exists
if [ ! -d "$backup_dir/Backup-$current_date" ]; then
    # Check if a backup directory for the last 7 days exists
    for ((i=1; i<=7; i++)); do
        last_date=$(date -d "-$i days" +%Y-%m-%d) # is used to calculate the date for a specific number of days in the past
        if [ -d "$backup_dir/Backup-$last_date" ]; then
            # If a backup directory for the last 7 days exists, use it
            backup_dir_name="Backup-$last_date"
            break
        fi
    done

    # If no backup directory for the last 7 days exists, create new
    if [ -z "$backup_dir_name" ]; then
        backup_dir_name="Backup-$current_date"
        mkdir "$backup_dir/$backup_dir_name"
        echo "Created new backup directory: $backup_dir_name" >> /home/user/backup-report
    fi
else
    backup_dir_name="Backup-$current_date"
fi

# Copy files from the source directory to the backup directory
for file in "$source_dir"/*; do
    pure_filename=$(basename "$file")
    if [ ! -f "$backup_dir/$backup_dir_name/$pure_filename" ]; then
        # If the file doesn't exist in the backup directory -- copy it
        cp "$file" "$backup_dir/$backup_dir_name/"
        echo "Copied file: $pure_filename" >> /home/user/backup-report
    else
        # If the file exists in the backup directory, check it size
        source_size=$(stat -c%s "$file") # -c for easier extracting, %s for total size in bytes
        backup_size=$(stat -c%s "$backup_dir/$backup_dir_name/$pure_filename") # -c for easier extracting, %s for total size in bytes

        if [ "$source_size" -ne "$backup_size" ]; then
            versioned_file="$pure_filename.$current_date"
            mv "$backup_dir/$backup_dir_name/$pure_filename" "$backup_dir/$backup_dir_name/$versioned_file" # rename
            cp "$file" "$backup_dir/$backup_dir_name/"
            echo "Updated file: $pure_filename (previous version: $versioned_file)" >> /home/user/backup-report
        fi
    fi
done

echo "Backup completed: $current_date" >> /home/user/backup-report