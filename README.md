# File Permissions Management System

A menu-driven Linux file-permissions management project written in Bash Shell Scripting.

## Features

1. View permissions
2. Change permissions using numeric modes (such as `755` or `644`)
3. Change permissions using symbolic modes (such as `u+x`)
4. Add read, write, or execute permissions
5. Remove read, write, or execute permissions
6. Check the current user's read, write, and execute access
7. View file owner and group
8. List files and directories with permissions
9. Search for files by name or pattern
10. Back up permission modes
11. Restore permission modes from a backup
12. View detailed permission information
13. View the activity log
14. Exit

## Requirements

- Linux (Ubuntu recommended)
- Bash and standard utilities: `chmod`, `stat`, `find`, `ls`, and `date`

## Run the project

```bash
chmod +x file_permissions_management.sh
./file_permissions_management.sh
```

Or run it with:

```bash
bash file_permissions_management.sh
```

## Quick test

```bash
touch test.txt
./file_permissions_management.sh
```

Use menu option 2 with `test.txt` and mode `644` to test changing permissions.

## Backup and restore notes

Option 10 creates a timestamped text backup containing permission modes and paths. Option 11 restores saved modes for paths that still exist. This backup does not contain file contents, ownership, ACLs, or SELinux contexts. Restoring permissions may require appropriate privileges. Test on sample files, not important system files.

## Activity log

Actions are recorded in `permission_activity.log` in the directory from which the program is launched.

## Project structure

```text
File-Permissions-Management-System/
├── README.md
└── file_permissions_management.sh
```

## Author

Add your name, course, and university details here.
