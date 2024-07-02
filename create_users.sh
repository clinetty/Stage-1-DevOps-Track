#!/bin/bash

# Define the log & password file variables

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create and set permissions for log and password files

touch $LOG_FILE
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Generate a random password for a user

generate_password() {
 tr -dc A-Za-z0-9 </dev/urandom | head -c 12
}

# Check if the file is provided

if [ -z "$1" ]; then
 echo "Usage: $0 <user_file>"
 exit 1
fi
USER_FILE="$1"

# Process each line of the user file

while IFS=";" read -r username groups; do
 # Remove leading and trailing whitespace from username and groups

 username=$(echo $username | xargs)
 groups=$(echo $groups | xargs)
 
 # If a user do not exist, create user and personal group

 if ! id -u $username >/dev/null 2>&1; then
 useradd -m -s /bin/bash $username
 echo "$(date) - Created user: $username" >> $LOG_FILE
 
 # Generate a password for the user

 password=$(generate_password)
 echo "$username,$password" >> $PASSWORD_FILE
 echo "$username:$password" | chpasswd
 
 # Assign the user to the specified groups

 if [ -n "$groups" ]; then
 IFS=',' read -r -a group_array <<< "$groups"
 for group in "${group_array[@]}"; do
 if ! getent group $group >/dev/null; then
 groupadd $group
 echo "$(date) - Created group: $group" >> $LOG_FILE
 fi
 usermod -aG $group $username
 echo "$(date) - Added $username to group: $group" >> $LOG_FILE
 done
 fi
 else
 echo "$(date) - User $username already exists" >> $LOG_FILE
 fi
done < "$USER_FILE"
echo "User creation process completed. Check $LOG_FILE for details."
