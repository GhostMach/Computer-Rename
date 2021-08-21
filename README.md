# Win10-Computer-Rename
A Powershell script that renames a computer to a (maximum) fifteen character NETBIOS string based on a (eight-character limit) user-defined name and the last seven digits of the machine's serial number.

## Installation
Run the `.ps1` file as an Adminstrater--choosing `Run with Powershell`. <br>
**Note:** If prompted to *trust* the script's execution policy, please enter, `Y` to accept all.

## Usage
Local execution on a virtual or physical computer that is domain-joined; not designed for batch renaming of domain-joined devices.

### Features
Script performs or allows the following:
- User input to enter a unique user logon name that's up to eight characters in length.
- Automatically creates a user logon name, up to eight characters in length, based on the first & last names--including middle initial--provided by the user.
- Modifies the computer's Local Machine (HKLM) registry to change the desktop icon, "This PC" to the renamed computer name.
- Fully compliant with Microsoft's fifteen character limit for NETBIOS names that are domain-joined devices in a Windows Server environment.
- Script has built-in logic to validate user-input where after three unsuccesful attempts, the script will exit without commiting changes.
