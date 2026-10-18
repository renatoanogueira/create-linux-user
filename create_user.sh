#!/bin/bash
# Purpose - Script to add a user to Linux system including password
# Author - Vivek Gite <www.cyberciti.biz> under GPL v2.0+
# Copied and changed by Renato Nogueira in 2022/11/25
# Changes added for setting custom permissions for the home directory
# Password is now set through chpasswd (system default hash, e.g. SHA-512/yescrypt)
# ------------------------------------------------------------------
# Am I Root user?
if [ "$(id -u)" -eq 0 ]; then
        echo "Information:"
        echo "This script creates a user to be used as our SFTP partners only. If you need a user for another reason, use the useradd command."
        echo "Press Ctrl-C to cancel"
        read -r -p "Enter username : " username
        read -r -s -p "Enter password : " password
        echo
        read -r -s -p "Confirm password : " password_confirm
        echo
        if [ -z "$username" ] || [ -z "$password" ]; then
                echo "Username and password cannot be empty!"
                exit 1
        fi
        if [ "$password" != "$password_confirm" ]; then
                echo "Passwords do not match!"
                exit 1
        fi
        # Exact match on the username (a prefix match would block e.g. "ana" when "anabela" exists)
        if getent passwd "$username" >/dev/null; then
                echo "$username exists!"
                exit 1
        else
                # Added -b param to change user basedir, -G to add user on such group, and -k to pull empty skel files
                if useradd -b /sftp -m -G sftp -k /dev/null "$username"; then
                        # Set password via stdin so it never shows up in the process list
                        if ! printf '%s:%s\n' "$username" "$password" | chpasswd; then
                                echo "Failed to set password! Removing user $username."
                                userdel -r "$username"
                                exit 1
                        fi
                        echo "User has been added to the system!"

                        # Change permissions of the home directory to 750
                        chmod 750 /sftp/"$username"
                        echo "Permissions for /sftp/$username set to 750."
                else
                        echo "Failed to add a user!"
                        exit 1
                fi
        fi
else
        echo "Only root may add a user to the system."
        exit 2
fi
