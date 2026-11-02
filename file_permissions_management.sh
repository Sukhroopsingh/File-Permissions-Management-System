#!/bin/bash
# FILE PERMISSIONS MANAGEMENT SYSTEM - Bash Shell Scripting

LOG_FILE="$PWD/permission_activity.log"

log_activity() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

pause_screen() { echo; read -r -p 'Press Enter to continue...' _; }

read_existing_path() {
    local path
    read -r -p "$1" path
    if [[ -z "$path" || ! -e "$path" ]]; then
        echo "Error: Please enter an existing file or directory."
        return 1
    fi
    REPLY="$path"
}

view_permissions() {
    echo '----- VIEW PERMISSIONS -----'
    if read_existing_path 'Enter file/directory path: '; then
        ls -ld -- "$REPLY"
        log_activity "Viewed permissions of: $REPLY"
    fi
}

change_numeric_permissions() {
    echo '----- CHANGE PERMISSIONS (NUMERIC) -----'
    read_existing_path 'Enter file/directory path: ' || return
    local path="$REPLY" mode
    read -r -p 'Enter permission value (e.g. 755 or 644): ' mode
    [[ "$mode" =~ ^[0-7]{3,4}$ ]] || { echo 'Invalid permission value.'; return; }
    if chmod "$mode" -- "$path"; then
        echo 'Permissions changed successfully.'; ls -ld -- "$path"
        log_activity "Changed numeric permissions of $path to $mode"
    else echo 'Could not change permissions; check your privileges.'; fi
}

symbolic_permissions() {
    echo '----- SYMBOLIC PERMISSIONS -----'
    read_existing_path 'Enter file/directory path: ' || return
    local path="$REPLY" setting
    read -r -p 'Enter symbolic permission (e.g. u+r, g-w, o+x): ' setting
    [[ "$setting" =~ ^[ugoa]*[+=-][rwxXstugo]*$ ]] || { echo 'Invalid symbolic permission format.'; return; }
    if chmod "$setting" -- "$path"; then
        echo 'Permissions updated successfully.'; ls -ld -- "$path"
        log_activity "Applied symbolic permission $setting to $path"
    else echo 'Could not update permissions.'; fi
}

add_permissions() {
    echo '----- ADD PERMISSIONS -----'
    read_existing_path 'Enter file/directory path: ' || return
    local path="$REPLY" who perms
    read -r -p 'Apply to whom? (u=user, g=group, o=others, a=all): ' who
    read -r -p 'Add permissions (r, w, x or combination): ' perms
    [[ "$who" =~ ^[ugoa]$ && "$perms" =~ ^[rwx]+$ ]] || { echo 'Invalid input.'; return; }
    if chmod "${who}+${perms}" -- "$path"; then
        echo 'Permissions added successfully.'; ls -ld -- "$path"
        log_activity "Added $perms permission(s) for $who on $path"
    else echo 'Could not add permissions.'; fi
}

remove_permissions() {
    echo '----- REMOVE PERMISSIONS -----'
    read_existing_path 'Enter file/directory path: ' || return
    local path="$REPLY" who perms
    read -r -p 'Apply to whom? (u=user, g=group, o=others, a=all): ' who
    read -r -p 'Remove permissions (r, w, x or combination): ' perms
    [[ "$who" =~ ^[ugoa]$ && "$perms" =~ ^[rwx]+$ ]] || { echo 'Invalid input.'; return; }
    if chmod "${who}-${perms}" -- "$path"; then
        echo 'Permissions removed successfully.'; ls -ld -- "$path"
        log_activity "Removed $perms permission(s) for $who on $path"
    else echo 'Could not remove permissions.'; fi
}

check_file_access() {
    echo '----- CHECK FILE ACCESS -----'
    read_existing_path 'Enter file/directory path: ' || return
    local path="$REPLY"
    [[ -r "$path" ]] && echo 'Read access: YES' || echo 'Read access: NO'
    [[ -w "$path" ]] && echo 'Write access: YES' || echo 'Write access: NO'
    [[ -x "$path" ]] && echo 'Execute/search access: YES' || echo 'Execute/search access: NO'
    log_activity "Checked access permissions of: $path"
}

view_owner_group() {
    echo '----- VIEW OWNER AND GROUP -----'
    if read_existing_path 'Enter file/directory path: '; then
        stat -c 'File: %n%nOwner: %U%nGroup: %G' -- "$REPLY"
        log_activity "Viewed owner and group of: $REPLY"
    fi
}

list_files() {
    echo '----- LIST FILES WITH PERMISSIONS -----'
    local dir
    read -r -p 'Enter directory path (Enter for current directory): ' dir
    dir="${dir:-.}"
    [[ -d "$dir" ]] || { echo 'Directory does not exist.'; return; }
    ls -la -- "$dir"
    log_activity "Listed files in directory: $dir"
}

search_files() {
    echo '----- SEARCH FILES -----'
    local dir pattern
    read -r -p 'Directory to search (Enter for current directory): ' dir
    dir="${dir:-.}"
    [[ -d "$dir" ]] || { echo 'Directory does not exist.'; return; }
    read -r -p 'File name or pattern (e.g. report.txt or *.txt): ' pattern
    [[ -n "$pattern" ]] || { echo 'No pattern entered.'; return; }
    find "$dir" -name "$pattern" -print
    log_activity "Searched for '$pattern' inside: $dir"
}

backup_permissions() {
    echo '----- BACKUP PERMISSIONS -----'
    read_existing_path 'Enter file/directory to back up: ' || return
    local target="$REPLY" backup_file
    backup_file="permissions_backup_$(date '+%Y%m%d_%H%M%S').txt"
    if find "$target" \( -type f -o -type d \) -print0 |
        while IFS= read -r -d '' item; do
            mode=$(stat -c '%a' -- "$item") || exit 1
            printf '%s\t%s\n' "$mode" "$item"
        done > "$backup_file"; then
        echo "Backup created: $backup_file"
        log_activity "Created permission backup of $target in $backup_file"
    else
        echo 'Backup failed.'; rm -f -- "$backup_file"
    fi
}

restore_permissions() {
    echo '----- RESTORE PERMISSIONS -----'
    local backup_file mode path restored=0 failed=0
    read -r -p 'Enter backup file path: ' backup_file
    [[ -f "$backup_file" && -r "$backup_file" ]] || { echo 'Backup file not found or unreadable.'; return; }
    while IFS=$'\t' read -r mode path; do
        [[ -n "$mode" && -n "$path" ]] || continue
        if [[ "$mode" =~ ^[0-7]{3,4}$ && -e "$path" ]]; then
            if chmod "$mode" -- "$path"; then ((restored+=1)); else ((failed+=1)); echo "Could not restore: $path"; fi
        else ((failed+=1)); echo "Skipped missing/invalid entry: $path"; fi
    done < "$backup_file"
    echo "Restore completed. Restored: $restored | Failed/skipped: $failed"
    log_activity "Restored permissions from $backup_file (restored=$restored, failed=$failed)"
}

permission_details() {
    echo '----- PERMISSION DETAILS -----'
    read_existing_path 'Enter file/directory path: ' || return
    local path="$REPLY"
    stat -- "$path"
    echo; stat -c 'Numeric permission: %a%nSymbolic permission: %A' -- "$path"
    echo 'r = read, w = write, x = execute/search'
    log_activity "Viewed detailed permission information of: $path"
}

show_activity_log() {
    echo '----- ACTIVITY LOG -----'
    [[ -f "$LOG_FILE" ]] && cat -- "$LOG_FILE" || echo 'No activity recorded yet.'
}

show_menu() {
    clear
    echo '================================================'
    echo '       FILE PERMISSIONS MANAGEMENT SYSTEM'
    echo '             Using Bash Shell Scripting'
    echo '================================================'
    echo '1.  View Permissions'
    echo '2.  Change Permissions (Numeric)'
    echo '3.  Symbolic Permissions'
    echo '4.  Add Permissions'
    echo '5.  Remove Permissions'
    echo '6.  Check File Access'
    echo '7.  View Owner and Group'
    echo '8.  List Files'
    echo '9.  Search Files'
    echo '10. Backup Permissions'
    echo '11. Restore Permissions'
    echo '12. Permission Details'
    echo '13. Activity Log'
    echo '14. Exit'
    echo '================================================'
}

while true; do
    show_menu
    read -r -p 'Enter your choice (1-14): ' choice
    case "$choice" in
        1) view_permissions; pause_screen ;;
        2) change_numeric_permissions; pause_screen ;;
        3) symbolic_permissions; pause_screen ;;
        4) add_permissions; pause_screen ;;
        5) remove_permissions; pause_screen ;;
        6) check_file_access; pause_screen ;;
        7) view_owner_group; pause_screen ;;
        8) list_files; pause_screen ;;
        9) search_files; pause_screen ;;
        10) backup_permissions; pause_screen ;;
        11) restore_permissions; pause_screen ;;
        12) permission_details; pause_screen ;;
        13) show_activity_log; pause_screen ;;
        14) echo 'Thank you for using the system.'; log_activity 'Exited the program'; exit 0 ;;
        *) echo 'Invalid choice. Enter a number from 1 to 14.'; pause_screen ;;
    esac
done
