#!/bin/sh

# Default Base Folder
BaseFolder="/Users/Shared/SIC"
# Default Configurations Folder
ConfigurationFolder="${BaseFolder}/Configurations"
# Default Library Folder
LibraryFolder="${BaseFolder}/Library"
# Default Packages Folder
PackageFolder="${BaseFolder}/Packages"
# Default Masters Folder
MasterFolder="${BaseFolder}/Masters"
# Default Image Size (GB)
ImageSize="56.5"
# Minimum Image Size
minImageSize="5"
# Maximum Image Size
maxImageSize="2048"
# Default Volume Name
VolumeName="Macintosh HD"
# Default Export Option for Recovery Partition (Include in Master)
ExportType=1
# Default for ASR Scan on Masters
ScanImage=1
# FirstBoot Script Path
FirstBootPath="/usr/libexec/FirstBoot"
# Default System Configuration
Language="English"
SACountryCode="US"
InputSourceID="US"
NTPServerName="Apple Americas/U.S. (time.apple.com)"
NTPServer="time.apple.com"
NTPEnabled=1
GeonameID=5341145
TZAuto=0
RemoteLogin=0
RemoteManagement=0

# Additional System Settings, menus not yet implemented
# Display host info at login window
AdminHostInfo=0					# 0 (Off) | 1 (On)
# Display login window as Name and password
ShowFullName=0					# 0 (Off) | 1 (On)
# Allow guests to connect to shared folders
AllowGuestAccess=1				# 1 (On)  | 0 (Off)
# Allow managed users to add or delete printers
ManagedUserPrinters=0			# 0 (Off) | 1 (On)
# Automatically check for updates
SoftwareUpdateCheck=1			# 1 (On)  | 0 (Off)

# Additional User Settings, menus not yet implemented
UserSettings=1					# 0 (Off) | 1 (On)
# General: Show scroll bars
AppleShowScrollBars="Always"	# Automatic | WhenScrolling | Always
# Finder: Show Status Bar
ShowStatusBar=TRUE
# Finder: New Finder windows show: Computer; Volume; Home; Desktop; Documents; All My Files
NewWindowTarget="PfHm"			# PfCm | PfVo | PfHm | PfDe | PfDo | PfAF
# Setup Assistant: Gesture Movie
GestureMovieSeen="trackpad"		# trackpad | 
# iCloud Setup
SuppressCloudSetup=1			# 1 (On)  | 0 (Off)

# Version
SICVersion="1.5b9"

# ${0}:	Path to this script
ScriptName=`basename "${0}"`

# Resize Terminal Window
printf "\e[8;36;80;t"

# Section: Common

spin="/-\|"

function display_Title {
	clear
	printf "\033[1mSystem Image Creator (SIC) ${SICVersion}\033[m\n"
	printf "Copyright (c) 2011-2012 Mondada Pty Ltd. All rights reserved.\n"
}

function display_Subtitle {
	# ${1}:	Subtitle
	display_Title
	printf "\n\033[1m${1}\033[m\n\n"
}

function privelege_Check {
	if [ `id -u` -ne 0 ] ; then
		display_Title
		printf "\n${ScriptName} must be run with root privileges, exiting.\n\n"
		exit 1
	fi
}

function display_Options {
	# ${1}:	Text above selection list
	# ${2}:	Text for prompt
	printf "${1}\n\n"
	PS3=`printf "\n${2}"`
}

function press_anyKey {
	# ${1}:	Message to display above prompt
	if [ -n "${1}" ] ; then echo "${1}" ; echo ; fi
	read -sn 1 -p "Press any key to continue..." anyKey < /dev/tty
	echo
}

function get_SystemOSVersion {
	SystemOSMajor=`sw_vers -productVersion | awk -F "." '{print $1}'`
	SystemOSMinor=`sw_vers -productVersion | awk -F "." '{print $2}'`
	SystemOSPoint=`sw_vers -productVersion | awk -F "." '{print $3}'`
	if [ -z "${SystemOSPoint}" ] ; then SystemOSPoint=0 ; fi
	SystemOSBuild=`sw_vers -buildVersion`
}

function get_LocalUsers {
	unset LocalRecordNames[@]
	unset LocalRealNames[@]
	unset LocalUniqueIDs[@]
	unset LocalNFSHomeDirectories[@]
	LocalUsers=( `dscl -f "/var/db/dslocal/nodes/Default" localonly -list /Local/Target/Users` )
	i=0 ; for Element in "${LocalUsers[@]}" ; do
		AuthenticationAuthority=`dscl -f "/var/db/dslocal/nodes/Default" localonly -read /Local/Target/Users/${Element} "AuthenticationAuthority" 2>/dev/null`
		if [ "${Element}" != "root" ] && [ -n "${AuthenticationAuthority}" ] ; then
			LocalRecordNames[i]="${Element}"
			LocalRealNames[i]=`dscl -f "/var/db/dslocal/nodes/Default" localonly -read /Local/Target/Users/${Element} "RealName" 2>/dev/null | grep -v "RealName:" | sed "s/^ *//g"`
			LocalUniqueIDs[i]=`dscl -f "/var/db/dslocal/nodes/Default" localonly -read /Local/Target/Users/${Element} "UniqueID" 2>/dev/null | awk -F "UniqueID: " '{print $NF}'`
			LocalNFSHomeDirectories[i]=`dscl -f "/var/db/dslocal/nodes/Default" localonly -read /Local/Target/Users/${Element} "NFSHomeDirectory" 2>/dev/null | awk -F "NFSHomeDirectory: " '{print $NF}'`
			let i++
		fi
	done
}

function set_Target {
	# ${1}: Volume
	if [ -n "${1}" ] ; then
		Target="/Volumes/${1}"
	else
		unset Target
		TargetType=0
	fi
}

# Section: License & Copyright

function get_LicenseStatus {
	LicenseStatus=`defaults read ~/Library/Preferences/au.com.mondada.SIC "LicenseStatus" 2>/dev/null`
}

function display_License {
	display_Title
	echo
	echo "This program is free software: you can redistribute it and/or modify"
	echo "it under the terms of the GNU General Public License as published by"
	echo "the Free Software Foundation, either version 3 of the License, or"
	echo "(at your option) any later version."
	echo
	echo "This program is distributed in the hope that it will be useful,"
	echo "but WITHOUT ANY WARRANTY; without even the implied warranty of"
	echo "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
	echo "GNU General Public License for more details."
	echo
	echo "You should have received a copy of the GNU General Public License"
	echo "along with this program.  If not, see <http://www.gnu.org/licenses/>."
	echo
	echo "Report bugs to <duncan.mccracken@mondada.com.au>"
	echo
}

function display_Copyright {
	display_Title
	echo
	echo "This program comes with ABSOLUTELY NO WARRANTY."
	echo "This is free software, and you are welcome to redistribute it"
	echo "under certain conditions; See the GNU General Public License for"
	echo "details."
	echo
	echo "Report bugs to <duncan.mccracken@mondada.com.au>"
	echo
	sleep 1
}

function menu_License {
	if [ "${LicenseStatus}" != "1" ] ; then
		display_License
		LicenseOptions=( "Agree" "Disagree" )
		display_Options "To continue you must agree to the terms of the license agreement" "Select an option: "
		select LicenseOption in "${LicenseOptions[@]}" ; do
			if [ -n "${LicenseOption}" ] ; then break ; fi
		done
		if [ "${LicenseOption}" == "Disagree" ] ; then echo ; exit 1 ; fi
		defaults write ~/Library/Preferences/au.com.mondada.SIC "LicenseStatus" -bool TRUE
	else
		display_Copyright
	fi
}

# Section: Help

function help_Preferences {
	display_Subtitle "Preferences"
	echo "Default Folders: The locations in which SIC stores things."
	echo
	echo "Configurations: Plists that contain all of your settings for an image."
	echo
	echo "Library: 'Vanilla' system images, configurations are applied to these to create"
	echo "your masters."
	echo
	echo "Packages: If you want to add software to your image, place OS X installer"
	echo "packages in this folder."
	echo
	echo "Masters: Where SIC exports the restore-ready images."
	echo
	echo "Image Settings: Set the default image size & volume name."
	echo
	echo "Export Settings: Allows you to select the default export behaviours for"
	echo "masters. Splitting the recovery partition away from the image is the default"
	echo "behaviour for DeployStudio."
	echo
	press_anyKey
}

function help_Creating {
	display_Subtitle "Creating Images"
	echo "SIC will create images from two sources:"
	echo " - An un-booted, un-configured system volume attached to your computer."
	echo " - An OS X install ESD or DVD."
	echo
	echo "These images will be saved to SIC's Library. These images are un-configured"
	echo "and used to create masters by applying configuration(s) to them."
	echo
	echo "Once a version of OS X is in the library, you don't need to capture/install"
	echo "that version again."
	echo
	echo "Note: When performing an installation, you will only be able to select an"
	echo "      installer of the same version of OS X your are running."
	echo "      eg. If you are running Mountain Lion, you can only perform Mountain Lion"
	echo "          installations."
	echo
	press_anyKey
}

function help_Configuring {
	display_Subtitle "Configuring Images"
	echo "The System Setup section will allow you to configure the system settings you"
	echo "wish to apply to your image(s). If you have an un-configured system attached to"
	echo "your computer, you may also apply your system settings to this volume allowing"
	echo "you to use SIC for a 'No-Imaging' workflow."
	echo
	echo "Select Target: Allows you to choose an image from the Library, or an attached"
	echo "volume to configure. You don't need to select a target to create a"
	echo "configuration, but you must have a target selected to apply a configuration."
	echo
	echo "Configurations: Files which contain the settings which you wish to apply to"
	echo "un-configured images/volumes. You may apply a configuration to multiple OS X"
	echo "versions, but remember to check your settings are being displayed correctly in"
	echo "each section, particularly System Preferences."
	echo
	echo "System Preferences: This simply creates the settings achieved by running the"
	echo "Setup Assistant at 1st boot. There are a few additional options, which are"
	echo "helpful when creating images for mass-deployment"
	echo
	echo "Users: Create and edit User Accounts on your image."
	echo
	echo "Packages: Allows you to select packages to install software on your image."
	echo "If the package is unable to be installed, it will be copied to the image and"
	echo "installation attempted on first boot."
	echo
	echo "Remove Software: To reduce your image size, particularly when creating an image"
	echo "of a new (factory) system, you may want to remove some of the pre-installed"
	echo "software."
	echo
	press_anyKey
	display_Subtitle "Configuring Images"
	echo "Apply Configuration: This will export a master image or configure an attached"
	echo "volume, with the settings displayed in the previous sections."
	echo
	echo "Note: Applying a configuration is non-destructive to images in your Library"
	echo "      the configured image will be exported to the Masters folder, ready for"
	echo "      restore."
	echo
	echo "Note: Applying a configuration to a volume will cause SIC to ignore it once"
	echo "      the configuration is complete, the volume is seen as a configured"
	echo "      system which SIC can do nothing with."
	echo
	press_anyKey
}

function menu_Help {
	HelpOptions=( "Main Menu" "Preferences" "Creating Images" "Configuring Images" )
	while [ "${Option}" != "Main Menu" ] ; do
		display_Subtitle "Help"
		echo "SIC is a tool to assist with the creation of OS X images for mass deployment."
		echo
		echo "The workflow is designed to prevent the need to create everything from scratch"
		echo "when a new version of OS X is released. Additionally, once a build of OS X is"
		echo "captured it can be re-used to create multiple images, without the need to"
		echo "re-install the base operating system."
		echo
		echo "The simplest possible workflow for SIC is:"
		echo " - Mount your OS X installer (or insert disc)"
		echo " - Select Create Image"
		echo " - Follow the prompts (Once this is captured, you may use it as many times as"
		echo "   you wish)"
		echo " - Return to the Main Menu, select System Setup"
		echo " - Select your Target (the image you just created)"
		echo " - Set your System Preferences"
		echo " - Create your User(s)"
		echo " - Apply your Configuration"
		echo
		echo "For detailed information, select from the options below."
		echo
		display_Options "Options" "Select an option: "
		select Option in "${HelpOptions[@]}" ; do
			case "${Option}" in
				"Main Menu" ) break ;;
				"Preferences" ) help_Preferences ; unset Option ; break ;;
				"Creating Images" ) help_Creating ; unset Option ; break ;;
				"Configuring Images" ) help_Configuring ; unset Option ; break ;;
			esac
		done
	done
	unset Option
}

# Section: Preferences

function check_Path {
	# ${1}:	Path to validate
	validPath=0
	# Check for invalid characters
	escapedPath="${1//[\$\(\)\[\]\`\~\?\*\#\\\!\|\'\"]/_}"
	if [ "${1}" != "${escapedPath}" ] ; then
		printf "\nThe specified path cannot contain the following characters: \033[1m\$()[]\`~?*#\!|'\"\033[m\n" ; validPath=1 ; return 1
	fi
	# Check that it's absolute
	relativePath=`echo "${1}" | awk -F "/" '{print $1}'`
	if [ -n "${relativePath}" ] ; then
		printf "\nThe specified path must be absolute, please enter an absolute path\n" ; validPath=1 ; return 1
	fi
	# Check the volume exists
	if echo "${1}" | grep -q "/Volumes/" ; then
		volumeName=`echo "${1}" | awk -F "/Volumes/" '{print $NF}' | awk -F "/" '{print $1}'`
		if [ ! -d "/Volumes/${volumeName}" ] ; then
			printf "\nThe specified volume cannot be found, please enter a valid path\n" ; validPath=1 ; return 1
		fi
	fi
	# Check that the path is not a file
	if [ -f "${1}" ] ; then
		printf "\nThe specified path is to a file, please enter a path to a folder\n" ; validPath=1 ; return 1
	fi
	# Check that the path is unique
	if [ "${1}" == "${ConfigurationFolder}" ] || [ "${1}" == "${LibraryFolder}" ] || [ "${1}" == "${PackageFolder}" ] || [ "${1}" == "${MasterFolder}" ] ; then
		printf "\nThe folders must be unique, please enter a different path\n" ; validPath=1 ; return 1
	fi
	return 0
}

function get_ConfigurationFolder {
	prefConfigurationFolder=`defaults read ~/Library/Preferences/au.com.mondada.SIC "ConfigurationFolder" 2>/dev/null`
	if [ -n "${prefConfigurationFolder}" ] ; then
		if [ -d "${prefConfigurationFolder}" ] ; then
			ConfigurationFolder="${prefConfigurationFolder}"
		else
			printf "Warning:		Configurations Folder missing, reverting to default\n"
		fi
	fi
}

function set_ConfigurationFolder {
	display_Subtitle "Default Folders"
	printf "Configurations Folder (${ConfigurationFolder}): " ; read newConfigurationFolder
	if [ -z "${newConfigurationFolder}" ] || [ "${newConfigurationFolder}" == "${ConfigurationFolder}" ] ; then return 0 ; fi
	check_Path "${newConfigurationFolder}"
	while [ ${validPath} -ne 0 ] ; do
		printf "\nConfiguration Folder (${ConfigurationFolder}): " ; read newConfigurationFolder
		if [ -z "${newConfigurationFolder}" ] || [ "${newConfigurationFolder}" == "${ConfigurationFolder}" ] ; then return 0 ; fi
		check_Path "${newConfigurationFolder}"
	done
	ConfigurationFolder="${newConfigurationFolder}"
}

function get_LibraryFolder {
	prefLibraryFolder=`defaults read ~/Library/Preferences/au.com.mondada.SIC "LibraryFolder" 2>/dev/null`
	if [ -n "${prefLibraryFolder}" ] ; then
		if [ -d "${prefLibraryFolder}" ] ; then
			LibraryFolder="${prefLibraryFolder}"
		else
			printf "Warning:		Library Folder missing, reverting to default\n"
		fi
	fi
}

function set_LibraryFolder {
	display_Subtitle "Default Folders"
	printf "Library Folder (${LibraryFolder}): " ; read newLibraryFolder
	if [ -z "${newLibraryFolder}" ] || [ "${newLibraryFolder}" == "${LibraryFolder}" ] ; then return 0 ; fi
	check_Path "${newLibraryFolder}"
	while [ ${validPath} -ne 0 ] ; do
		printf "\nLibrary Folder (${LibraryFolder}): " ; read newLibraryFolder
		if [ -z "${newLibraryFolder}" ] || [ "${newLibraryFolder}" == "${LibraryFolder}" ] ; then return 0 ; fi
		check_Path "${newLibraryFolder}"
	done
	LibraryFolder="${newLibraryFolder}"
}

function get_PackageFolder {
	prefPackageFolder=`defaults read ~/Library/Preferences/au.com.mondada.SIC "PackageFolder" 2>/dev/null`
	if [ -n "${prefPackageFolder}" ] ; then
		if [ -d "${prefPackageFolder}" ] ; then
			PackageFolder="${prefPackageFolder}"
		else
			printf "Warning:		Packages Folder missing, reverting to default\n"
		fi
	fi
}

function set_PackageFolder {
	display_Subtitle "Default Folders"
	printf "Packages Folder (${PackageFolder}): " ; read newPackageFolder
	if [ -z "${newPackageFolder}" ] || [ "${newPackageFolder}" == "${PackageFolder}" ] ; then return 0 ; fi
	check_Path "${newPackageFolder}"
	while [ ${validPath} -ne 0 ] ; do
		printf "\nPackage Folder (${PackageFolder}): " ; read newPackageFolder
		if [ -z "${newPackageFolder}" ] || [ "${newPackageFolder}" == "${PackageFolder}" ] ; then return 0 ; fi
		check_Path "${newPackageFolder}"
	done
	PackageFolder="${newPackageFolder}"
}

function get_MasterFolder {
	prefMasterFolder=`defaults read ~/Library/Preferences/au.com.mondada.SIC "MasterFolder" 2>/dev/null`
	if [ -n "${prefMasterFolder}" ] ; then
		if [ -d "${prefMasterFolder}" ] ; then
			MasterFolder="${prefMasterFolder}"
		else
			printf "Warning:		Masters Folder missing, reverting to default\n"
		fi
	fi
}

function set_MasterFolder {
	display_Subtitle "Default Folders"
	printf "Masters Folder (${MasterFolder}): " ; read newMasterFolder
	if [ -z "${newMasterFolder}" ] || [ "${newMasterFolder}" == "${MasterFolder}" ] ; then return 0 ; fi
	check_Path "${newMasterFolder}"
	while [ ${validPath} -ne 0 ] ; do
		printf "\nMaster Folder (${MasterFolder}): " ; read newMasterFolder
		if [ -z "${newMasterFolder}" ] || [ "${newMasterFolder}" == "${MasterFolder}" ] ; then return 0 ; fi
		check_Path "${newMasterFolder}"
	done
	MasterFolder="${newMasterFolder}"
}

function display_DefaultFolders {
	printf "Configurations:		${ConfigurationFolder}\n"
	printf "Library:		${LibraryFolder}\n"
	printf "Packages:		${PackageFolder}\n"
	printf "Masters:		${MasterFolder}\n"
	printf "\n"
}

function save_DefaultFolders {
	defaults write ~/Library/Preferences/au.com.mondada.SIC "ConfigurationFolder" -string "${ConfigurationFolder}"
	if [ ! -d "${ConfigurationFolder}" ] ; then mkdir -p "${ConfigurationFolder}" ; fi
	defaults write ~/Library/Preferences/au.com.mondada.SIC "LibraryFolder" -string "${LibraryFolder}"
	if [ ! -d "${LibraryFolder}" ] ; then mkdir -p "${LibraryFolder}" ; fi
	defaults write ~/Library/Preferences/au.com.mondada.SIC "PackageFolder" -string "${PackageFolder}"
	if [ ! -d "${PackageFolder}" ] ; then mkdir -p "${PackageFolder}" ; fi
	defaults write ~/Library/Preferences/au.com.mondada.SIC "MasterFolder" -string "${MasterFolder}"
	if [ ! -d "${MasterFolder}" ] ; then mkdir -p "${MasterFolder}" ; fi
}

function menu_DefaultFolders {
	FolderOptions=( "Preferences Menu" "Configurations" "Library" "Packages" "Masters" )
	while [ "${Option}" != "Preferences Menu" ] ; do
		display_Subtitle "Default Folders"
		display_DefaultFolders
		display_Options "Options" "Select an option: "
		select Option in "${FolderOptions[@]}" ; do
			case "${Option}" in
				"Preferences Menu" ) break ;;
				"Configurations" ) set_ConfigurationFolder ; unset Option ; break ;;
				"Library" ) set_LibraryFolder ; unset Option ; break ;;
				"Packages" ) set_PackageFolder ; unset Option ; break ;;
				"Masters" ) set_MasterFolder ; unset Option ; break ;;
			esac
		done
	done
	unset Option
	unset SaveDefaults
	while [ -z "${SaveDefaults}" ] ; do
		echo
		read -sn 1 -p "Save as default settings (Y/n)? " SaveDefaults < /dev/tty
		echo
		if [ -z "${SaveDefaults}" ] ; then SaveDefaults="y" ; fi
		case "${SaveDefaults}" in
			"Y" | "y" ) save_DefaultFolders ; echo ;;
			"N" | "n" ) echo ;;
			* ) echo ; unset SaveDefaults ;;
		esac
	done
	unset SaveDefaults
}

function get_ImageSize {
	prefImageSize=`defaults read ~/Library/Preferences/au.com.mondada.SIC "ImageSize" 2>/dev/null`
	if [ -n "${prefImageSize}" ] ; then ImageSize="${prefImageSize}" ; fi
}

function check_Size {
	# ${1}:	Size to validate
	validSize=0
	# Remove invalid characters
	newImageSize="${1//[^0-9.]/}"
	# Validate the clean string to ensure its numeric
	isValid=$( echo "scale=0; ${newImageSize}/${newImageSize} + 1" | bc -l 2>/dev/null )
	if [ ${isValid} -gt 1 ] ; then
		# Check that it's larger than 5 GB
		if [ $( echo "${newImageSize} < ${minImageSize}" | bc 2>/dev/null ) -ne 0 ] ; then printf "\nMac OS X requires at least \033[1m${minImageSize}\033[m GB of free space to install.\n" ; ImageSize="${minImageSize}" ; validSize=1 ; return 1 ; fi
		# Check that it's smaller than 2 TB
		if [ $( echo "${newImageSize} > ${maxImageSize}" | bc 2>/dev/null ) -ne 0 ] ; then printf "\nThe maximum image size is \033[1m${maxImageSize}\033[m GB.\n" ; ImageSize="${maxImageSize}" ; validSize=1 ; return 1 ; fi
		return 0
	else
		printf "\n\033[1m${1}\033[m is not a valid value, please enter a numeric value.\n" ; validSize=1 ; return 1
	fi
}

function set_ImageSize {
	display_Subtitle "Image Settings"
	printf "Image Size (${ImageSize}): " ; read newImageSize
	if [ -z "${newImageSize}" ] || [ "${newImageSize}" == "${ImageSize}" ] ; then return 0 ; fi
	check_Size "${newImageSize}"
	while [ ${validSize} -ne 0 ] ; do
		printf "\nImage Size (${ImageSize} GB): " ; read newImageSize
		if [ -z "${newImageSize}" ] || [ "${newImageSize}" == "${ImageSize}" ] ; then return 0 ; fi
		check_Size "${newImageSize}"
	done
	ImageSize="${newImageSize}"
}

function get_VolumeName {
	prefVolumeName=`defaults read ~/Library/Preferences/au.com.mondada.SIC "VolumeName" 2>/dev/null`
	if [ -n "${prefVolumeName}" ] ; then VolumeName="${prefVolumeName}" ; fi
}

function check_VolumeName {
	# ${1}:	Volume Name to validate
	validName=0
	# Check for invalid characters
	escapedName="${1//[\$\(\)\[\]\`\~\?\*\#\\\!\|\'\"]/_}"
	if [ "${1}" != "${escapedName}" ] ; then printf "\nThe volume name cannot contain the following characters: \033[1m\$()[]\`~?*#\!|'\"\033[m\n" ; validName=1 ; return 1 ; fi
	return 0
}

function set_VolumeName {
	display_Subtitle "Image Settings"
	printf "Volume Name (${VolumeName}): " ; read newVolumeName
	if [ -z "${newVolumeName}" ] || [ "${newVolumeName}" == "${VolumeName}" ] ; then return 0 ; fi
	newVolumeName="${newVolumeName//\//:}"
	check_VolumeName "${newVolumeName}"
	while [ ${validName} -ne 0 ] ; do
		printf "Volume Name (${VolumeName}): " ; read newVolumeName
		if [ -z "${newVolumeName}" ] || [ "${newVolumeName}" == "${VolumeName}" ] ; then return 0 ; fi
		newVolumeName="${newVolumeName//\//:}"
		check_VolumeName "${newVolumeName}"
	done
	VolumeName="${newVolumeName}"
}

function display_ImageSettings {
	printf "Image Size:	${ImageSize} GB\n"
	printf "Volume Name:	${VolumeName}\n"
	printf "\n"
}

function save_ImageSettings {
	defaults write ~/Library/Preferences/au.com.mondada.SIC "ImageSize" -float "${ImageSize}"
	defaults write ~/Library/Preferences/au.com.mondada.SIC "VolumeName" -string "${VolumeName}"
}

function menu_ImageSettings {
	ImageOptions=( "Preferences Menu" "Image Size" "Volume Name" )
	while [ "${Option}" != "Preferences Menu" ] ; do
		display_Subtitle "Image Settings"
		display_ImageSettings
		display_Options "Options" "Select an option: "
		select Option in "${ImageOptions[@]}" ; do
			case "${Option}" in
				"Preferences Menu" ) break ;;
				"Image Size" ) set_ImageSize ; unset Option ; break ;;
				"Volume Name" ) set_VolumeName ; unset Option ; break ;;
			esac
		done
	done
	unset Option
	unset SaveDefaults
	while [ -z "${SaveDefaults}" ] ; do
		echo
		read -sn 1 -p "Save as default settings (Y/n)? " SaveDefaults < /dev/tty
		echo
		if [ -z "${SaveDefaults}" ] ; then SaveDefaults="y" ; fi
		case "${SaveDefaults}" in
			"Y" | "y" ) save_ImageSettings ; echo ;;
			"N" | "n" ) echo ;;
			* ) echo ; unset SaveDefaults ;;
		esac
	done
	unset SaveDefaults
}

function get_ExportType {
	prefExportType=`defaults read ~/Library/Preferences/au.com.mondada.SIC "ExportType" 2>/dev/null`
	if [ -n "${prefExportType}" ] ; then ExportType="${prefExportType}" ; fi
}

function display_RecoveryPartition {
	printf "	["
	if [ ${ExportType} -eq 1 ] ; then printf "*" ; else printf " " ; fi
	printf "] Include Recovery Partition in Master\n"
	printf "	["
	if [ ${ExportType} -eq 2 ] ; then printf "*" ; else printf " " ; fi
	printf "] Remove Recovery Partition from Master\n"
	printf "	["
	if [ ${ExportType} -eq 3 ] ; then printf "*" ; else printf " " ; fi
	printf "] Create separate image for Recovery Partition\n"
	printf "\n"
}

function set_RecoveryPartition {
	RecoveryOptions=( "Include Recovery Partition in Master" "Remove Recovery Partition from Master" "Create separate image for Recovery Partition" )
	display_Subtitle "Export Settings"
	display_RecoveryPartition
	display_Options "Options" "Select an option: "
	select Option in "${RecoveryOptions[@]}" ; do
		case "${Option}" in
			"Include Recovery Partition in Master" ) ExportType=1 ; break ;;
			"Remove Recovery Partition from Master" ) ExportType=2 ; break ;;
			"Create separate image for Recovery Partition" ) ExportType=3 ; break ;;
		esac
	done
	unset Option
}

function get_ScanImage {
	prefScanImage=`defaults read ~/Library/Preferences/au.com.mondada.SIC "ScanImage" 2>/dev/null`
	if [ -n "${prefScanImage}" ] ; then ScanImage="${prefScanImage}" ; fi
}

function display_ScanImage {
	printf "	["
	if [ ${ScanImage} -eq 1 ] ; then printf "*" ; else printf " " ; fi
	printf "] Scan masters for restore\n"
	printf "\n"
}

function set_ScanImage {
	display_Subtitle "Export Settings"
	display_ScanImage
	while [ -z "${ASR}" ] ; do
		read -sn 1 -p "Scan masters for restore (Y/n)? " ASR < /dev/tty
		if [ -z "${ASR}" ] ; then ASR="y" ; fi
		case "${ASR}" in
			"Y" | "y" ) echo ; ScanImage=1 ;;
			"N" | "n" ) echo ; ScanImage=0 ;;
			* ) echo ; unset ASR ;;
		esac
	done
	unset ASR
}

function display_ExportSettings {
	display_RecoveryPartition
	display_ScanImage
}

function save_ExportSettings {
	defaults write ~/Library/Preferences/au.com.mondada.SIC "ExportType" -int ${ExportType}
	defaults write ~/Library/Preferences/au.com.mondada.SIC "ScanImage" -int ${ScanImage}
}

function menu_ExportSettings {
	ExportOptions=( "Preferences Menu" "Recovery Partition" "Scan for Restore" )
	while [ "${Option}" != "Preferences Menu" ] ; do
		display_Subtitle "Export Settings"
		display_ExportSettings
		display_Options "Options" "Select an option: "
		select Option in "${ExportOptions[@]}" ; do
			case "${Option}" in
				"Preferences Menu" ) break ;;
				"Recovery Partition" ) set_RecoveryPartition ; unset Option ; break ;;
				"Scan for Restore" ) set_ScanImage ; unset Option ; break ;;
			esac
		done
	done
	unset Option
	unset SaveDefaults
	while [ -z "${SaveDefaults}" ] ; do
		echo
		read -sn 1 -p "Save as default settings (Y/n)? " SaveDefaults < /dev/tty
		echo
		if [ -z "${SaveDefaults}" ] ; then SaveDefaults="y" ; fi
		case "${SaveDefaults}" in
			"Y" | "y" ) save_ExportSettings ; echo ;;
			"N" | "n" ) echo ;;
			* ) echo ; unset SaveDefaults ;;
		esac
	done
	unset SaveDefaults
}

function get_Preferences {
	get_ConfigurationFolder
	get_LibraryFolder
	get_PackageFolder
	get_MasterFolder
	get_VolumeName
	get_ImageSize
	get_ExportType
	get_ScanImage
}

function menu_Preferences {
	PrefOptions=( "Main Menu" "Default Folders" "Image Settings" "Export Settings" )
	while [ "${Option}" != "Main Menu" ] ; do
		display_Subtitle "Preferences"
		display_Options "Options" "Select an option: "
		select Option in "${PrefOptions[@]}" ; do
			case "${Option}" in
				"Main Menu" ) break ;;
				"Default Folders" ) menu_DefaultFolders ; unset Option ; break ;;
				"Image Settings" ) menu_ImageSettings ; unset Option ; break ;;
				"Export Settings" ) menu_ExportSettings ; unset Option ; break ;;
			esac
		done
	done
	unset Option
}

# Section: Create Image

function detect_Sources {
	unset SourceVersions[@]
	unset SourceBuilds[@]
	unset SourceVolumes[@]
	unset ImageNames[@]
	IFS=$'\n'
	Volumes=( `df | grep "/Volumes/" | awk -F "/Volumes/" '{print $NF}'` )
	unset IFS
	for Volume in "${Volumes[@]}" ; do
		if [ ! -e "/Volumes/${Volume}/var/db/.AppleSetupDone" ] && [ -e "/Volumes/${Volume}/System/Library/CoreServices/SystemVersion.plist" ] ; then
			SourceOSMinor=`defaults read "/Volumes/${Volume}/System/Library/CoreServices/SystemVersion" ProductVersion | awk -F "." '{print $2}'`
			SourceOSPoint=`defaults read "/Volumes/${Volume}/System/Library/CoreServices/SystemVersion" ProductVersion | awk -F "." '{print $3}'`
			if [ -z "${SourceOSPoint}" ] ; then SourceOSPoint=0 ; fi
			case ${SourceOSMinor} in
				5 ) OSname="leopard" ;;
				6 ) OSname="snowleopard" ;;
				7 ) OSname="lion" ;;
				8 ) OSname="mountainlion" ;;
			esac
			if [ -e "/Volumes/${Volume}/System/Library/CoreServices/ServerVersion.plist" ] || [ -e "/Volumes/${Volume}/Applications/Server.app" ] || [ -e "/Volumes/${Volume}/Packages/Server.pkg" ] ; then
				ProductName="Mac OS X Server"
				ProductType="server"
			else
				ProductName="Mac OS X"
				ProductType="user"
			fi
			ProductVersion=`defaults read "/Volumes/${Volume}/System/Library/CoreServices/SystemVersion" ProductVersion`
			ProductBuildVersion=`defaults read "/Volumes/${Volume}/System/Library/CoreServices/SystemVersion" ProductBuildVersion`
			if [ -e "/Volumes/${Volume}/System/Installation/Packages/OSInstall.mpkg" ] || [ -e "/Volumes/${Volume}/Packages/OSInstall.mpkg" ] ; then
				if [ ${SourceOSMinor} -eq ${SystemOSMinor} ] ; then
					if [ ${SystemOSMinor} -eq 7 -a ${SystemOSPoint} -gt 3 ] ; then
						if [ ${SourceOSPoint} -gt 3 ] ; then
							SourceVersions=( "${SourceVersions[@]}" "${ProductName} ${ProductVersion} (${ProductBuildVersion}) Installer" )
							SourceBuilds=( "${SourceBuilds[@]}" "${ProductBuildVersion}" )
							SourceVolumes=( "${SourceVolumes[@]}" "${Volume}" )
							ImageNames=( "${ImageNames[@]}" `echo "${OSname}_${ProductBuildVersion}_${ProductType}" | awk {'print tolower()'}` )
						fi
					else
						SourceVersions=( "${SourceVersions[@]}" "${ProductName} ${ProductVersion} (${ProductBuildVersion}) Installer" )
						SourceBuilds=( "${SourceBuilds[@]}" "${ProductBuildVersion}" )
						SourceVolumes=( "${SourceVolumes[@]}" "${Volume}" )
						ImageNames=( "${ImageNames[@]}" `echo "${OSname}_${ProductBuildVersion}_${ProductType}" | awk {'print tolower()'}` )
					fi
				fi
			else
				SourceVersions=( "${SourceVersions[@]}" "${ProductName} ${ProductVersion} (${ProductBuildVersion})" )
				SourceBuilds=( "${SourceBuilds[@]}" "${ProductBuildVersion}" )
				SourceVolumes=( "${SourceVolumes[@]}" "${Volume}" )
				ImageNames=( "${ImageNames[@]}" `echo "${OSname}_${ProductBuildVersion}_${ProductType}" | awk {'print tolower()'}` )
			fi
		fi
	done
}

function display_Source {
	printf "Source:		"
	if [ -n "${SourceVersion}" ] ; then printf "${SourceVersion}" ; else printf "-" ; fi
	printf "\nImage Name:	"
	if [ -n "${ImageName}" ] ; then printf "${ImageName}.dmg" ; else printf "-" ; fi
	printf "\n"
	printf "\n"
}

function select_Source {
	detect_Sources
	display_Subtitle "Select Source"
	if [ ${#SourceVersions[@]} -eq 0 ] ; then
		unset SourceVersion
		unset SourceBuild
		unset SourceVolume
		unset ImageName
		press_anyKey "No sources available, please insert or mount an OS X Installer, or attach or mount an un-booted system volume."
	else
		display_Source
		display_Options "Sources" "Select a source: "
		select SourceVersion in "${SourceVersions[@]}" ; do
			if [ -n "${SourceVersion}" ] ; then break ; fi
		done
		i=0 ; for Element in "${SourceVersions[@]}" ; do
			if [ "${Element}" == "${SourceVersion}" ] ; then
				SourceVolume="${SourceVolumes[i]}"
				SourceBuild="${SourceBuilds[i]}"
				ImageName="${ImageNames[i]}"
				break
			fi
			let i++
		done
	fi
}

function install_Package {
	# ${1}: Path to package
	# ${2}: Installation target
	# ${3}: InstallType
	unset allowUntrusted
	if [ ${SystemOSMinor} -eq 7 -a ${SystemOSPoint} -gt 3 ] || [ ${SystemOSMinor} -gt 7 ] ; then GateKeeper="-allowUntrusted" ; fi
	if [ -e "${1}" ] ; then
		IFS=$'\n'
		PackageTitles=( `installer -pkginfo -pkg "${1}"` )
		unset IFS
		s=1
		if [ ${3} -eq 1 ] ; then
			printf "\ninstaller: Package name is ${PackageTitles[0]}\n"
			open "${1}"
			printf "installer:PHASE:Waiting for installation to complete…\n"
			while [ `ps eax | grep -i "Installer.app" | grep -v "grep" | awk '{print $1}'` ] ; do
				printf "\b${spin:s++%${#spin}:1}"
			done
			printf "\binstaller: The install is complete.\n"
		else
			unset Previous
			unset InstallerStatus
			unset InstallerProgress
			installer -verboseR "${GateKeeper}" -pkg "${1}" -target "${2}" 2>/dev/null | while read Line ; do
				if echo "${Line}" | grep -q "installer: " ; then printf "${Line}\n" ; fi
				if echo "${Line}" | grep -q "\(installer:PHASE:\|installer:STATUS:\)" ; then
					if [ "${InstallerStatus}" != "${Line}" ] ; then
						InstallerStatus="${Line}"
						if echo "${Previous}" | grep -q "installer:%" ; then
							printf "\n${InstallerStatus}\n"
						else
							printf "${InstallerStatus}\n"
						fi
					fi
				fi
				if echo "${Line}" | grep -q "installer:%" ; then
					if [ "${InstallerProgress}" != "${Line}" ] ; then
						InstallerProgress="${Line//%/%%}"
						printf "\r${InstallerProgress}"
					fi
				fi
				Previous="${Line}"
			done
		fi
		echo
	else
		press_anyKey "The package selection is invalid, please review your settings."
	fi
}

function create_Image {
	display_Subtitle "Create Image"
	display_Source
	if [ -z "${SourceVersion}" ] ; then press_anyKey "No source selected, please select a source first." ; return 1 ; fi
	if [ ! -e "/Volumes/${SourceVolume}" ] ; then press_anyKey "The source volume is no longer available, please re-select the source." ; return 1 ; fi
	ProductBuildVersion=`defaults read "/Volumes/${SourceVolume}/System/Library/CoreServices/SystemVersion" ProductBuildVersion`
	if [ "${SourceBuild}" != "${ProductBuildVersion}" ] ; then press_anyKey "The source volume is no longer available, please re-select the source." ; return 1 ; fi
	while [ -e "${LibraryFolder}/${ImageName}.dmg" ] ; do
		printf "An image already exists named \033[1m${ImageName}.dmg\033[m.\n"
		read -sn 1 -p "Would you like to overwrite it (y/N)? " Overwrite < /dev/tty ; echo
		if [ -z "${Overwrite}" ] ; then Overwrite="n" ; fi
		case "${Overwrite}" in
			"Y" | "y" ) echo ; rm -f "${LibraryFolder}/${ImageName}.dmg" ; break ;;
			"N" | "n" ) echo ; break ;;
		esac
	done
	unset Overwrite
	if [ ! -e "${LibraryFolder}/${ImageName}.dmg" ] ; then
		Removables=(
			".Spotlight-V100"
			".Trashes"
			".fseventsd"
		)
		if [ ! -e "${LibraryFolder}" ] ; then mkdir -p "${LibraryFolder}" ; chown 99:99 "${LibraryFolder}" ; fi
		if [ -e "/Volumes/${SourceVolume}/System/Installation/Packages/OSInstall.mpkg" ] || [ -e "/Volumes/${SourceVolume}/Packages/OSInstall.mpkg" ] ; then
			rm -f "/tmp/${ImageName}.sparseimage" &>/dev/null
			hdiutil create -size "${ImageSize}g" -type SPARSE -fs HFS+J -volname "${VolumeName}" "/tmp/${ImageName}.sparseimage"
			Volume=`hdiutil attach -owners on -noverify "/tmp/${ImageName}.sparseimage" | grep "/Volumes/${VolumeName}" | awk -F "/Volumes/" '{print $NF}'`
			set_Target "${Volume}"
			chown 0:80 "${Target}"
			chmod 1775 "${Target}"
			if [ -e "/Volumes/${SourceVolume}/System/Installation/Packages/OSInstall.mpkg" ] ; then
				unset Customize
				while [ -z "${Customize}" ] ; do
					echo
					read -sn 1 -p "Customize Installation (y/N)? " Customize < /dev/tty
					if [ -z "${Customize}" ] ; then Customize="n" ; fi ; echo
					case "${Customize}" in
						"Y" | "y" ) InstallType=1 ; break ;;
						"N" | "n" ) InstallType=0 ; break ;;
						* ) unset Customize ;;
					esac
					echo
				done
				install_Package "/Volumes/${SourceVolume}/System/Installation/Packages/OSInstall.mpkg" "${Target}" ${InstallType}
			else
				install_Package "/Volumes/${SourceVolume}/Packages/OSInstall.mpkg" "${Target}" 0
			fi
			bless --folder "${Target}/System/Library/CoreServices" --bootefi 2>/dev/null
			touch "${Target}/private/var/db/.RunLanguageChooserToo"
			for Removable in "${Removables[@]}" ; do
				if [ -e "${Target}/${Removable}" ] ; then rm -rf "${Target}/${Removable}" ; fi
			done
			Device=`diskutil info "${Target}" | grep "Part of Whole:" | awk '{print $NF}'`
			diskutil unmountDisk force "/dev/${Device}" &>/dev/null
			printf "Unmount of all volumes on ${Device} was successful\n"
			diskutil eject "/dev/${Device}" &>/dev/null
			printf "Disk /dev/${Device} ejected\n"
			hdiutil convert -format UDZO "/tmp/${ImageName}.sparseimage" -o "${LibraryFolder}/${ImageName}.dmg"
			rm -f "/tmp/${ImageName}.sparseimage" &>/dev/null
			echo
			press_anyKey
		else
			for Removable in "${Removables[@]}" ; do
				if [ -e "/Volumes/${SourceVolume}/${Removable}" ] ; then rm -rf "/Volumes/${SourceVolume}/${Removable}" ; fi
			done
			Device=`diskutil info "/Volumes/${SourceVolume}" | grep "Part of Whole:" | awk '{print $NF}'`
			DeviceNodes=`diskutil list "/dev/${Device}" | grep -c "Apple_HFS"`
			if [ ${DeviceNodes} -gt 1 ] ; then
				Device=`diskutil info "/Volumes/${SourceVolume}" | grep "Device Node:" | awk -F "/dev/" '{print $NF}'`
				diskutil unmount force "/dev/${Device}" &>/dev/null
				printf "Volume ${SourceVolume} on ${Device} unmounted\n"
			else
				diskutil unmountDisk force "/dev/${Device}" &>/dev/null
				printf "Unmount of all volumes on ${Device} was successful\n"
			fi
			hdiutil create -srcdevice "/dev/${Device}" -o "${LibraryFolder}/${ImageName}.dmg"
			diskutil mountDisk "/dev/${Device}"
			echo
			press_anyKey
		fi
	fi
}

function display_Images {
	printf "Images:		${Images[0]}\n"
	i=0 ; for Image in "${Images[@]}" ; do
		if [ ${i} -ne 0 ] ; then printf "		${Image}\n" ; fi
		let i++
	done
	printf "\n"
}

function menu_CreateImage {
	CreateOptions=( "Main Menu" "Select Source" "Create Image" )
	while [ "${Option}" != "Main Menu" ] ; do
		get_Images
		display_Subtitle "Create Image"
		display_Source
		display_Images
		display_Options "Options" "Select an option: "
		select Option in "${CreateOptions[@]}" ; do
			case "${Option}" in
				"Main Menu" ) break ;;
				"Select Source" ) select_Source ; unset Option ; break ;;
				"Create Image" ) create_Image ; unset Option ; break ;;
			esac
		done
	done
	unset SourceVersion
	unset SourceBuild
	unset SourceVolume
	unset ImageName
	unset Option
}

# Section: Target

function get_Volumes {
	unset Volumes[@]
	IFS=$'\n'
	Volumes=( `df | grep "/Volumes/" | awk -F "/Volumes/" '{print $NF}'` )
	unset IFS
	i=0 ; for Volume in "${Volumes[@]}" ; do
		if [ ! -e "/Volumes/${Volume}/System/Library/CoreServices/SystemVersion.plist" ] || [ -e "/Volumes/${Volume}/var/db/.AppleSetupDone" ] || [ -e "/Volumes/${Volume}/System/Installation/Packages/OSInstall.mpkg" ] || [ -e "/Volumes/${Volume}/Packages/OSInstall.mpkg" ] ; then
			unset Volumes[i]
		fi
		ReadOnly=`diskutil info "/Volumes/${Volume}" | grep "Read-Only Volume:" | awk '{print $NF}'`
		if [ "${ReadOnly}" == "Yes" ] ; then
			unset Volumes[i]
		fi
		let i++
	done
}

function get_Images {
	unset Images[@]
	IFS=$'\n'
	Images=( `find "${LibraryFolder}" -name "*.dmg" -exec basename {} \;` )
	unset IFS
}

function get_Targets {
	TargetNames=( "None" )
	TargetTypes=( 0 )
	get_Volumes
	i=1 ; for Element in "${Volumes[@]}" ; do
		TargetNames[i]="${Element}"
		TargetTypes[i]=1
		let i++
	done
	get_Images
	for Element in "${Images[@]}" ; do
		TargetNames[i]="${Element}"
		TargetTypes[i]=2
		let i++
	done
}

function set_TargetOSVersion {
	TargetOSMajor=`defaults read "${Target}/System/Library/CoreServices/SystemVersion" "ProductVersion" | awk -F "." '{print $1}'`
	TargetOSMinor=`defaults read "${Target}/System/Library/CoreServices/SystemVersion" "ProductVersion" | awk -F "." '{print $2}'`
	TargetOSPoint=`defaults read "${Target}/System/Library/CoreServices/SystemVersion" "ProductVersion" | awk -F "." '{print $3}'`
	if [ -z "${TargetOSPoint}" ] ; then TargetOSPoint=0 ; fi
	TargetOSBuild=`defaults read "${Target}/System/Library/CoreServices/SystemVersion" "ProductBuildVersion"`
	case ${TargetOSMinor} in
		6 | 7 ) PLACES="ZGEOPLACE" ;;
		8 ) PLACES="ZGEOKITPLACE" ;;
	esac
}

function set_TargetProperties {
	# ${1}: Volume
	set_Target "${1}"
	set_TargetOSVersion
	refresh_Language
	refresh_Country
	refresh_Keyboard
	refresh_GeonameID
}

function display_Target {
	printf "Target:		"
	if [ -n "${TargetName}" ] ; then printf "${TargetName}" ; else printf "-" ; fi
	printf "\n"
	# Begin: Debug Output
	# echo "MountPoint:	${Target}"
	# echo "TargetType:	${TargetType}"
	# End: Debug Output
	printf "System:		"
	if [ -n "${TargetOSBuild}" ] ; then
		printf "Mac OS X ${TargetOSMajor}.${TargetOSMinor}"
		if [ ${TargetOSPoint} -ne 0 ] ; then printf ".${TargetOSPoint}" ; fi
		printf " (${TargetOSBuild})"
	else
		printf "-"
	fi
	printf "\n\n"
}

function select_Target {
	if [ ${TargetType} -eq 2 ] ; then hdiutil eject "${Target}" &>/dev/null ; fi
	get_Targets
	display_Subtitle "Select Target"
	display_Target
	if [ ${#TargetNames[@]} -eq 0 ] ; then
		press_anyKey "No targets available, please create an image, or attach an un-booted system volume."
	else
		display_Options "Available Targets" "Select a target: "
		select TargetName in "${TargetNames[@]}" ; do
			if [ -n "${TargetName}" ] ; then break ; fi
		done
	fi
	i=0 ; for Element in "${TargetNames[@]}" ; do
		if [ "${TargetName}" == "${Element}" ] ; then TargetType="${TargetTypes[i]}" ; break ; fi
		let i++
	done
	if [ ${TargetType} -eq 0 ] ; then unset TargetName ; unset Volume ; fi
	if [ ${TargetType} -eq 1 ] ; then Volume="${TargetName}" ; fi
	if [ ${TargetType} -eq 2 ] ; then Volume=`hdiutil attach -owners on -noverify "${LibraryFolder}/${TargetName}" | grep "Apple_HFS" | awk -F "/Volumes/" '{print $NF}'` ; fi
	set_TargetProperties "${Volume}"
}

# Section: Language

function set_Languages {
	Languages=( "English" "Japanese" "French" "German" "Spanish" "Italian" "Portuguese" "Portuguese (Portugal)" "Dutch" "Swedish" "Norwegian" "Danish" "Finnish" "Russian" "Polish" )
	case ${TargetOSMinor} in
		8 ) Languages=( "${Languages[@]}" "Turkish" "Chinese (Simplified)" "Chinese (Traditional)" "Korean" "Arabic" "Czech" "Hungarian" "Catalan" "Croatian" "Romanian" "Hebrew" "Ukrainian" "Thai" "Slovak" "Greek" ) ;;
		7 ) Languages=( "${Languages[@]}" "Turkish" "Chinese (Simplified)" "Chinese (Traditional)" "Korean" "Arabic" "Czech" "Hungarian" )
			if [ ${TargetOSPoint} -ge 3 ] ; then
				Languages=( "${Languages[@]}" "Catalan" "Croatian" "Romanian" "Hebrew" "Ukrainian" "Thai" "Slovak" "Greek" )
			fi ;;
		* ) Languages=( "${Languages[@]}" "Chinese (Simplified)" "Chinese (Traditional)" "Korean" ) ;;
	esac
}

function set_LanguageCode {
	# ${1}:	Language Name
	case "${1}" in
		"Japanese" ) LanguageCode="ja" ;;
		"French" ) LanguageCode="fr" ;;
		"German" ) LanguageCode="de" ;;
		"Spanish" ) LanguageCode="es" ;;
		"Italian" ) LanguageCode="it" ;;
		"Portuguese" ) LanguageCode="pt" ;;
		"Portuguese (Portugal)" ) LanguageCode="pt-PT" ;;
		"Dutch" ) LanguageCode="nl" ;;
		"Swedish" ) LanguageCode="sv" ;;
		"Norwegian" ) LanguageCode="nb" ;;
		"Danish" ) LanguageCode="da" ;;
		"Finnish" ) LanguageCode="fi" ;;
		"Russian" ) LanguageCode="ru" ;;
		"Polish" ) LanguageCode="pl" ;;
		"Turkish" ) LanguageCode="tr" ;;
		"Chinese (Simplified)" ) LanguageCode="zh-Hans" ;;
		"Chinese (Traditional)" ) LanguageCode="zh-Hant" ;;
		"Korean" ) LanguageCode="ko" ;;
		"Arabic" ) LanguageCode="ar" ;;
		"Czech" ) LanguageCode="cs" ;;
		"Hungarian" ) LanguageCode="hu" ;;
		"Catalan" ) LanguageCode="ca" ;;
		"Croatian" ) LanguageCode="hr" ;;
		"Romanian" ) LanguageCode="ro" ;;
		"Hebrew" ) LanguageCode="he" ;;
		"Ukrainian" ) LanguageCode="uk" ;;
		"Thai" ) LanguageCode="th" ;;
		"Slovak" ) LanguageCode="sk" ;;
		"Greek" ) LanguageCode="el" ;;
		* ) LanguageCode="en" ;;
	esac
}

function refresh_Language {
	set_Languages
	i=0 ; for LANGUAGE in "${Languages[@]}" ; do if [ "${LANGUAGE}" == "${Language}" ] ; then i=1 ; break ; fi ; done
	if [ ${i} -eq 0 ] ; then Language="English" ; fi
	set_LanguageCode "${Language}"
	set_AppleLanguages "${LanguageCode}"
}

function set_Localization {
	# ${1}: Language Name
	case "${1}" in
		"Japanese" ) Localization="Japanese" ;;
		"French" ) Localization="French" ;;
		"German" ) Localization="German" ;;
		"Spanish" ) Localization="Spanish" ;;
		"Italian" ) Localization="Italian" ;;
		"Portuguese" ) Localization="pt" ;;
		"Portuguese (Portugal)" ) Localization="pt_PT" ;;
		"Dutch" ) Localization="Dutch" ;;
		"Swedish" ) Localization="sv" ;;
		"Norwegian" ) Localization="no" ;;
		"Danish" ) Localization="da" ;;
		"Finnish" ) Localization="fi" ;;
		"Russian" ) Localization="ru" ;;
		"Polish" ) Localization="pl" ;;
		"Turkish" ) Localization="tr" ;;
		"Chinese (Simplified)" ) Localization="zh_CN" ;;
		"Chinese (Traditional)" ) Localization="zh_TW" ;;
		"Korean" ) Localization="ko" ;;
		"Arabic" ) Localization="ar" ;;
		"Czech" ) Localization="cs" ;;
		"Hungarian" ) Localization="hu" ;;
		"Catalan" ) Localization="ca" ;;
		"Croatian" ) Localization="hr" ;;
		"Romanian" ) Localization="ro" ;;
		"Hebrew" ) Localization="he" ;;
		"Ukrainian" ) Localization="uk" ;;
		"Thai" ) Localization="th" ;;
		"Slovak" ) Localization="sk" ;;
		"Greek" ) Localization="el" ;;
		* ) Localization="English" ;;
	esac
}

function set_AppleLanguages {
	# ${1}: Language Code
	if [ ${TargetOSMinor} -ge 8 ] ; then
		AppleLanguages=( "ar" "ca" "cs" "da" "nl" "el" "en" "fi" "fr" "de" "he" "hr" "hu" "it" "ja" "ko" "nb" "pl" "pt" "pt-PT" "ro" "ru" "sk" "es" "sv" "th" "tr" "uk" "zh-Hans" "zh-Hant" )
	else
		AppleLanguages=( "en" "ja" "fr" "de" "es" "it" "nl" "sv" "nb" "da" "fi" "pl" "pt" "pt-PT" "ru" "zh-Hans" "zh-Hant" "ko" )
	fi
	i=0
	for Element in "${AppleLanguages[@]}" ; do
		if [ "${1}" == "${Element}" ] ; then unset AppleLanguages[i] ; break ; fi
		let i++
	done
	AppleLanguages=( "${1}" "${AppleLanguages[@]}" )
}

function set_ScriptManager {
	# ${1}: Language Code
	case "${1}" in
		"ja" ) ScriptManager="smJapanese" ;;
		"ru" ) ScriptManager="smCyrillic" ;;
		"pl" ) ScriptManager="smCentralEuroRoman" ;;
		"zh-Hans" ) ScriptManager="smSimpChinese" ;;
		"zh-Hant" ) ScriptManager="smTradChinese" ;;
		"ko" ) ScriptManager="smKorean" ;;
		* ) ScriptManager="smRoman" ;;
	esac
}

function set_ITLB {
	# ${1}: Language Code
	case "${1}" in
		"ja" ) ITLB=16895 ;;
		"ru" ) ITLB=19967 ;;
		"pl" ) ITLB=31231 ;;
		"zh-Hans" ) ITLB=29183 ;;
		"zh-Hant" ) ITLB=17407 ;;
		"ko" ) ITLB=17919 ;;
		* ) ITLB=16383 ;;
	esac
}

# Section: Country

function set_AllCountryCodes {
	case ${TargetOSMinor} in
		5 ) AllCountryCodes=( "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AN" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BM" "BN" "BO" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CV" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IN" "IO" "IQ" "IS" "IT" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "MA" "MC" "MD" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RU" "RW" "SA" "SB" "SC" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "ST" "SV" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TM" "TN" "TO" "TP" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "YU" "ZA" "ZM" "ZW" ) ;;
		6 ) AllCountryCodes=( "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AN" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BM" "BN" "BO" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CV" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IN" "IO" "IQ" "IS" "IT" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "MA" "MC" "MD" "ME" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RU" "RS" "RW" "SA" "SB" "SC" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "ST" "SV" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW" ) ;;
		* ) AllCountryCodes=( "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AN" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BM" "BN" "BO" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CV" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IN" "IO" "IQ" "IS" "IT" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "MA" "MC" "MD" "ME" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "ST" "SV" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "YE" "YT" "ZA" "ZM" "ZW" ) ;;
	esac
}

function convert_SACountryCodeToName {
	# ${1}:	OS Minor Version
	# ${2}:	Country Code
	case "${2}" in
		"AD" ) echo "Andorra" ;;
		"AE" ) echo "United Arab Emirates" ;;
		"AF" ) echo "Afghanistan" ;;
		"AG" ) echo "Antigua and Barbuda" ;;
		"AI" ) echo "Anguilla" ;;
		"AL" ) echo "Albania" ;;
		"AM" ) echo "Armenia" ;;
		"AN" ) echo "Netherlands Antilles" ;;
		"AO" ) echo "Angola" ;;
		"AQ" ) echo "Antarctica" ;;
		"AR" ) echo "Argentina" ;;
		"AS" ) echo "American Samoa" ;;
		"AT" ) echo "Austria" ;;
		"AU" ) echo "Australia" ;;
		"AW" ) echo "Aruba" ;;
		"AZ" ) echo "Azerbaijan" ;;
		"BA" ) echo "Bosnia and Herzegovina" ;;
		"BB" ) echo "Barbados" ;;
		"BD" ) echo "Bangladesh" ;;
		"BE" ) echo "Belgium" ;;
		"BF" ) echo "Burkina Faso" ;;
		"BG" ) echo "Bulgaria" ;;
		"BH" ) echo "Bahrain" ;;
		"BI" ) echo "Burundi" ;;
		"BJ" ) echo "Benin" ;;
		"BM" ) echo "Bermuda" ;;
		"BN" )
			case ${1} in
				5 ) echo "Brunei Darussalam" ;;
				* ) echo "Brunei" ;;
			esac ;;
		"BO" ) echo "Bolivia" ;;
		"BR" ) echo "Brazil" ;;
		"BS" ) echo "Bahamas" ;;
		"BT" ) echo "Bhutan" ;;
		"BV" ) echo "Bouvet Island" ;;
		"BW" ) echo "Botswana" ;;
		"BY" ) echo "Belarus" ;;
		"BZ" ) echo "Belize" ;;
		"CA" ) echo "Canada" ;;
		"CC" )
			case ${1} in
				5 ) echo "Cocos (Keeling) Islands" ;;
				6 ) echo "Cocos Islands" ;;
				* ) echo "Cocos [Keeling] Islands" ;;
			esac ;;
		"CD" )
			case ${1} in
				5 ) echo "Congo, The Democratic Republic Of The" ;;
				* ) echo "Congo - Kinshasa" ;;
			esac ;;
		"CF" ) echo "Central African Republic" ;;
		"CG" )
			case ${1} in
				5 ) echo "Congo" ;;
				* ) echo "Congo - Brazzaville" ;;
			esac ;;
		"CH" ) echo "Switzerland" ;;
		"CI" )
			case ${1} in
				5 ) echo "Cote D'Ivoire" ;;
				6 ) echo "Ivory Coast" ;;
				* ) echo "Côte d’Ivoire" ;;
			esac ;;
		"CK" ) echo "Cook Islands" ;;
		"CL" ) echo "Chile" ;;
		"CM" ) echo "Cameroon" ;;
		"CN" ) echo "China" ;;
		"CO" ) echo "Colombia" ;;
		"CR" ) echo "Costa Rica" ;;
		"CV" ) echo "Cape Verde" ;;
		"CX" ) echo "Christmas Island" ;;
		"CY" ) echo "Cyprus" ;;
		"CZ" ) echo "Czech Republic" ;;
		"DE" ) echo "Germany" ;;
		"DJ" ) echo "Djibouti" ;;
		"DK" ) echo "Denmark" ;;
		"DM" ) echo "Dominica" ;;
		"DO" ) echo "Dominican Republic" ;;
		"DZ" ) echo "Algeria" ;;
		"EC" ) echo "Ecuador" ;;
		"EE" ) echo "Estonia" ;;
		"EG" ) echo "Egypt" ;;
		"EH" ) echo "Western Sahara" ;;
		"ER" ) echo "Eritrea" ;;
		"ES" ) echo "Spain" ;;
		"ET" ) echo "Ethiopia" ;;
		"FI" ) echo "Finland" ;;
		"FJ" ) echo "Fiji" ;;
		"FK" )
			case ${1} in
				5 ) echo "Falkland Islands (Malvinas)" ;;
				* ) echo "Falkland Islands" ;;
			esac ;;
		"FM" )
			case ${1} in
				5 ) echo "Micronesia, Federated States Of" ;;
				* ) echo "Micronesia" ;;
			esac ;;
		"FO" ) echo "Faroe Islands" ;;
		"FR" ) echo "France" ;;
		"GA" ) echo "Gabon" ;;
		"GB" ) echo "United Kingdom" ;;
		"GD" ) echo "Grenada" ;;
		"GE" ) echo "Georgia" ;;
		"GF" ) echo "French Guiana" ;;
		"GH" ) echo "Ghana" ;;
		"GI" ) echo "Gibraltar" ;;
		"GL" ) echo "Greenland" ;;
		"GM" ) echo "Gambia" ;;
		"GN" ) echo "Guinea" ;;
		"GP" ) echo "Guadeloupe" ;;
		"GQ" ) echo "Equatorial Guinea" ;;
		"GR" ) echo "Greece" ;;
		"GS" )
			case ${1} in
				5 ) echo "South Georgia and The South Sandwich Islands" ;;
				* ) echo "South Georgia and the South Sandwich Islands" ;;
			esac ;;
		"GT" ) echo "Guatemala" ;;
		"GU" ) echo "Guam" ;;
		"GW" ) echo "Guinea-Bissau" ;;
		"GY" ) echo "Guyana" ;;
		"HK" )
			case ${1} in
				5 ) echo "Hong Kong" ;;
				* ) echo "Hong Kong SAR China" ;;
			esac ;;
		"HM" )
			case ${1} in
				5 ) echo "Heard and Mc Donald Islands" ;;
				* ) echo "Heard Island and McDonald Islands" ;;
			esac ;;
		"HN" ) echo "Honduras" ;;
		"HR" ) echo "Croatia" ;;
		"HT" ) echo "Haiti" ;;
		"HU" ) echo "Hungary" ;;
		"ID" ) echo "Indonesia" ;;
		"IE" ) echo "Ireland" ;;
		"IL" ) echo "Israel" ;;
		"IN" ) echo "India" ;;
		"IO" ) echo "British Indian Ocean Territory" ;;
		"IQ" ) echo "Iraq" ;;
		"IS" ) echo "Iceland" ;;
		"IT" ) echo "Italy" ;;
		"JM" ) echo "Jamaica" ;;
		"JO" ) echo "Jordan" ;;
		"JP" ) echo "Japan" ;;
		"KE" ) echo "Kenya" ;;
		"KG" ) echo "Kyrgyzstan" ;;
		"KH" ) echo "Cambodia" ;;
		"KI" ) echo "Kiribati" ;;
		"KM" ) echo "Comoros" ;;
		"KN" ) echo "Saint Kitts and Nevis" ;;
		"KR" )
			case ${1} in
				5 ) echo "Korea, Republic Of" ;;
				* ) echo "South Korea" ;;
			esac ;;
		"KW" ) echo "Kuwait" ;;
		"KY" ) echo "Cayman Islands" ;;
		"KZ" ) echo "Kazakhstan" ;;
		"LA" )
			case ${1} in
				5 ) echo "Lao People's Democratic Republic" ;;
				* ) echo "Laos" ;;
			esac ;;
		"LB" ) echo "Lebanon" ;;
		"LC" ) echo "Saint Lucia" ;;
		"LI" ) echo "Liechtenstein" ;;
		"LK" ) echo "Sri Lanka" ;;
		"LR" ) echo "Liberia" ;;
		"LS" ) echo "Lesotho" ;;
		"LT" ) echo "Lithuania" ;;
		"LU" ) echo "Luxembourg" ;;
		"LV" ) echo "Latvia" ;;
		"MA" ) echo "Morocco" ;;
		"MC" ) echo "Monaco" ;;
		"MD" ) echo "Moldova" ;;
		"ME" )
			case ${1} in
				6 | 7 | 8 ) echo "Montenegro" ;;
			esac ;;
		"MG" ) echo "Madagascar" ;;
		"MH" ) echo "Marshall Islands" ;;
		"MK" )
			case ${1} in
				5 ) echo "Macedonia, The Former Yugoslav Republic Of" ;;
				* ) echo "Macedonia" ;;
			esac ;;
		"ML" ) echo "Mali" ;;
		"MM" )
			case ${1} in
				5 | 6 ) echo "Myanmar" ;;
				* ) echo "Myanmar [Burma]" ;;
			esac ;;
		"MN" ) echo "Mongolia" ;;
		"MO" )
			case ${1} in
				5 ) echo "Macau" ;;
				* ) echo "Macau SAR China" ;;
			esac ;;
		"MP" ) echo "Northern Mariana Islands" ;;
		"MQ" ) echo "Martinique" ;;
		"MR" ) echo "Mauritania" ;;
		"MS" ) echo "Montserrat" ;;
		"MT" ) echo "Malta" ;;
		"MU" ) echo "Mauritius" ;;
		"MV" ) echo "Maldives" ;;
		"MW" ) echo "Malawi" ;;
		"MX" ) echo "Mexico" ;;
		"MY" ) echo "Malaysia" ;;
		"MZ" ) echo "Mozambique" ;;
		"NA" ) echo "Namibia" ;;
		"NC" ) echo "New Caledonia" ;;
		"NE" ) echo "Niger" ;;
		"NF" ) echo "Norfolk Island" ;;
		"NG" ) echo "Nigeria" ;;
		"NI" ) echo "Nicaragua" ;;
		"NL" ) echo "Netherlands" ;;
		"NO" ) echo "Norway" ;;
		"NP" ) echo "Nepal" ;;
		"NR" ) echo "Nauru" ;;
		"NU" ) echo "Niue" ;;
		"NZ" ) echo "New Zealand" ;;
		"OM" ) echo "Oman" ;;
		"PA" ) echo "Panama" ;;
		"PE" ) echo "Peru" ;;
		"PF" ) echo "French Polynesia" ;;
		"PG" ) echo "Papua New Guinea" ;;
		"PH" ) echo "Philippines" ;;
		"PK" ) echo "Pakistan" ;;
		"PL" ) echo "Poland" ;;
		"PM" )
			case ${1} in
				5 ) echo "St. Pierre and Miquelon" ;;
				* ) echo "Saint Pierre and Miquelon" ;;
			esac ;;
		"PN" )
			case ${1} in
				5 | 6 ) echo "Pitcairn" ;;
				* ) echo "Pitcairn Islands" ;;
			esac ;;
		"PR" ) echo "Puerto Rico" ;;
		"PS" )
			case ${1} in
				5 ) echo "Palestinian Authority" ;;
				6 ) echo "Palestinian Territory" ;;
				* ) echo "Palestinian Territories" ;;
			esac ;;
		"PT" ) echo "Portugal" ;;
		"PW" ) echo "Palau" ;;
		"PY" ) echo "Paraguay" ;;
		"QA" ) echo "Qatar" ;;
		"RE" )
			case ${1} in
				5 | 6 ) echo "Reunion" ;;
				* ) echo "Réunion" ;;
			esac ;;
		"RO" ) echo "Romania" ;;
		"RS" )
			case ${1} in
				6 | 7 | 8 ) echo "Serbia" ;;
			esac ;;
		"RU" )
			case ${1} in
				5 ) echo "Russian Federation" ;;
				* ) echo "Russia" ;;
			esac ;;
		"RW" ) echo "Rwanda" ;;
		"SA" ) echo "Saudi Arabia" ;;
		"SB" ) echo "Solomon Islands" ;;
		"SC" ) echo "Seychelles" ;;
		"SE" ) echo "Sweden" ;;
		"SG" ) echo "Singapore" ;;
		"SH" )
			case ${1} in
				5 ) echo "St. Helena" ;;
				* ) echo "Saint Helena" ;;
			esac ;;
		"SI" ) echo "Slovenia" ;;
		"SJ" )
			case ${1} in
				5 ) echo "Svalbard and Jan Mayen Islands" ;;
				* ) echo "Svalbard and Jan Mayen" ;;
			esac ;;
		"SK" )
			case ${1} in
				5 ) echo "Slovak Republic" ;;
				* ) echo "Slovakia" ;;
			esac ;;
		"SL" ) echo "Sierra Leone" ;;
		"SM" ) echo "San Marino" ;;
		"SN" ) echo "Senegal" ;;
		"SO" ) echo "Somalia" ;;
		"SR" ) echo "Suriname" ;;
		"ST" )
			case ${1} in
				5 | 6 ) echo "Sao Tome and Principe" ;;
				* ) echo "São Tomé and Príncipe" ;;
			esac ;;
		"SV" ) echo "El Salvador" ;;
		"SZ" ) echo "Swaziland" ;;
		"TC" ) echo "Turks and Caicos Islands" ;;
		"TD" ) echo "Chad" ;;
		"TF" ) echo "French Southern Territories" ;;
		"TG" ) echo "Togo" ;;
		"TH" ) echo "Thailand" ;;
		"TJ" ) echo "Tajikistan" ;;
		"TK" ) echo "Tokelau" ;;
		"TM" ) echo "Turkmenistan" ;;
		"TN" ) echo "Tunisia" ;;
		"TO" ) echo "Tonga" ;;
		"TP" )
			case ${1} in
				5 ) echo "East Timor" ;;
			esac ;;
		"TR" ) echo "Turkey" ;;
		"TT" ) echo "Trinidad and Tobago" ;;
		"TV" ) echo "Tuvalu" ;;
		"TW" ) echo "Taiwan" ;;
		"TZ" )
			case ${1} in
				5 ) echo "Tanzania, United Republic Of" ;;
				* ) echo "Tanzania" ;;
			esac ;;
		"UA" ) echo "Ukraine" ;;
		"UG" ) echo "Uganda" ;;
		"UM" )
			case ${1} in
				5 | 6 ) echo "United States Minor Outlying Islands" ;;
				* ) echo "U.S. Minor Outlying Islands" ;;
			esac ;;
		"UY" ) echo "Uruguay" ;;
		"UZ" ) echo "Uzbekistan" ;;
		"VA" )
			case ${1} in
				5 ) echo "Holy See (Vatican City State)" ;;
				6 ) echo "Vatican" ;;
				* ) echo "Vatican City" ;;
			esac ;;
		"VC" )
			case ${1} in
				5 ) echo "Saint Vincent and The Grenadines" ;;
				* ) echo "Saint Vincent and the Grenadines" ;;
			esac ;;
		"VE" ) echo "Venezuela" ;;
		"VG" )
			case ${1} in
				5 ) echo "Virgin Islands (British)" ;;
				* ) echo "British Virgin Islands" ;;
			esac ;;
		"VI" )
			case ${1} in
				5 ) echo "Virgin Islands (U.S.)" ;;
				* ) echo "U.S. Virgin Islands" ;;
			esac ;;
		"VN" )
			case ${1} in
				5 ) echo "Viet Nam" ;;
				* ) echo "Vietnam" ;;
			esac ;;
		"VU" ) echo "Vanuatu" ;;
		"WF" )
			case ${1} in
				5 ) echo "Wallis and Futuna Islands" ;;
				* ) echo "Wallis and Futuna" ;;
			esac ;;
		"WS" ) echo "Samoa" ;;
		"YE" ) echo "Yemen" ;;
		"YT" ) echo "Mayotte" ;;
		"YU" )
			case ${1} in
				5 ) echo "Serbia and Montenegro" ;;
			esac ;;
		"ZA" ) echo "South Africa" ;;
		"ZM" ) echo "Zambia" ;;
		"ZW" ) echo "Zimbabwe" ;;
		* ) echo "United States" ;;
	esac
}

function refresh_Country {
	set_AllCountryCodes
	i=0 ; for Code in "${AllCountryCodes[@]}" ; do if [ "${Code}" == "${SACountryCode}" ] ; then i=1 ; break ; fi ; done
	if [ ${i} -eq 0 ] ; then SACountryCode="US" ; fi
	SACountry=`convert_SACountryCodeToName ${TargetOSMinor} "${SACountryCode}"`
}

function set_LanguageCountryCodes {
	# ${1}: Language Code
	set_AllCountryCodes
	LanguageCountryCodes=( `/usr/libexec/PlistBuddy -c "Print ':${1}'" "${Target}/System/Library/PrivateFrameworks/International.framework/Resources/SALanguageToCountry.plist" 2>/dev/null | grep -v "{\|}"` )
	i=0 ; for LanguageCountryCode in "${LanguageCountryCodes[@]}" ; do
		j=0 ; for Code in "${AllCountryCodes[@]}" ; do if [ "${Code}" == "${LanguageCountryCode}" ] ; then j=1 ; break ; fi ; done
		if [ ${j} -eq 0 ] ; then unset LanguageCountryCodes[i] ; fi
		let i++
	done
	if [ ${#LanguageCountryCodes[@]} -eq 0 ] ; then LanguageCountryCodes=( "US" ) ; fi
}

function set_LanguageCountryNames {
	unset LanguageCountryNames[@]
	IFS=$'\n'
	for Code in "${LanguageCountryCodes[@]}" ; do
		LanguageCountryNames=( "${LanguageCountryNames[@]}" $(convert_SACountryCodeToName ${TargetOSMinor} "${Code}") )
	done
	unset IFS
}

function set_OtherCountryCodes {
	unset OtherCountryCodes[@]
	for Code in "${AllCountryCodes[@]}" ; do
		j=0 ; for LanguageCountryCode in "${LanguageCountryCodes[@]}" ; do
			if [ "${Code}" == "${LanguageCountryCode}" ] ; then j=1 ; break ; fi
		done
		if [ ${j} -eq 0 ] ; then OtherCountryCodes=( "${OtherCountryCodes[@]}" "${Code}" ) ; fi
	done
}

function set_OtherCountryNames {
	unset OtherCountryNames[@]
	IFS=$'\n'
	for Code in "${OtherCountryCodes[@]}" ; do
		OtherCountryNames=( "${OtherCountryNames[@]}" $(convert_SACountryCodeToName ${TargetOSMinor} "${Code}") )
	done
	OtherCountryNames=( `for COUNTRY in "${OtherCountryNames[@]}" ; do echo "${COUNTRY}" ; done | sort -u` )
	unset IFS
}

function set_SACountryCode {
	# ${1}:	Country Name
	case "${1}" in
		"Andorra" ) SACountryCode="AD" ;;
		"United Arab Emirates" ) SACountryCode="AE" ;;
		"Afghanistan" ) SACountryCode="AF" ;;
		"Antigua and Barbuda" ) SACountryCode="AG" ;;
		"Anguilla" ) SACountryCode="AI" ;;
		"Albania" ) SACountryCode="AL" ;;
		"Armenia" ) SACountryCode="AM" ;;
		"Netherlands Antilles" ) SACountryCode="AN" ;;
		"Angola" ) SACountryCode="AO" ;;
		"Antarctica" ) SACountryCode="AQ" ;;
		"Argentina" ) SACountryCode="AR" ;;
		"American Samoa" ) SACountryCode="AS" ;;
		"Austria" ) SACountryCode="AT" ;;
		"Australia" ) SACountryCode="AU" ;;
		"Aruba" ) SACountryCode="AW" ;;
		"Azerbaijan" ) SACountryCode="AZ" ;;
		"Bosnia and Herzegovina" ) SACountryCode="BA" ;;
		"Barbados" ) SACountryCode="BB" ;;
		"Bangladesh" ) SACountryCode="BD" ;;
		"Belgium" ) SACountryCode="BE" ;;
		"Burkina Faso" ) SACountryCode="BF" ;;
		"Bulgaria" ) SACountryCode="BG" ;;
		"Bahrain" ) SACountryCode="BH" ;;
		"Burundi" ) SACountryCode="BI" ;;
		"Benin" ) SACountryCode="BJ" ;;
		"Bermuda" ) SACountryCode="BM" ;;
		"Brunei Darussalam" | "Brunei" ) SACountryCode="BN" ;;
		"Bolivia" ) SACountryCode="BO" ;;
		"Brazil" ) SACountryCode="BR" ;;
		"Bahamas" ) SACountryCode="BS" ;;
		"Bhutan" ) SACountryCode="BT" ;;
		"Bouvet Island" ) SACountryCode="BV" ;;
		"Botswana" ) SACountryCode="BW" ;;
		"Belarus" ) SACountryCode="BY" ;;
		"Belize" ) SACountryCode="BZ" ;;
		"Canada" ) SACountryCode="CA" ;;
		"Cocos (Keeling) Islands" | "Cocos Islands" | "Cocos [Keeling] Islands" ) SACountryCode="CC" ;;
		"Congo, The Democratic Republic Of The" | "Congo - Kinshasa" ) SACountryCode="CD" ;;
		"Central African Republic" ) SACountryCode="CF" ;;
		"Congo" | "Congo - Brazzaville" ) SACountryCode="CG" ;;
		"Switzerland" ) SACountryCode="CH" ;;
		"Cote D'Ivoire" | "Ivory Coast" | "Côte d’Ivoire" ) SACountryCode="CI" ;;
		"Cook Islands" ) SACountryCode="CK" ;;
		"Chile" ) SACountryCode="CL" ;;
		"Cameroon" ) SACountryCode="CM" ;;
		"China" ) SACountryCode="CN" ;;
		"Colombia" ) SACountryCode="CO" ;;
		"Costa Rica" ) SACountryCode="CR" ;;
		"Cape Verde" ) SACountryCode="CV" ;;
		"Christmas Island" ) SACountryCode="CX" ;;
		"Cyprus" ) SACountryCode="CY" ;;
		"Czech Republic" ) SACountryCode="CZ" ;;
		"Germany" ) SACountryCode="DE" ;;
		"Djibouti" ) SACountryCode="DJ" ;;
		"Denmark" ) SACountryCode="DK" ;;
		"Dominica" ) SACountryCode="DM" ;;
		"Dominican Republic" ) SACountryCode="DO" ;;
		"Algeria" ) SACountryCode="DZ" ;;
		"Ecuador" ) SACountryCode="EC" ;;
		"Estonia" ) SACountryCode="EE" ;;
		"Egypt" ) SACountryCode="EG" ;;
		"Western Sahara" ) SACountryCode="EH" ;;
		"Eritrea" ) SACountryCode="ER" ;;
		"Spain" ) SACountryCode="ES" ;;
		"Ethiopia" ) SACountryCode="ET" ;;
		"Finland" ) SACountryCode="FI" ;;
		"Fiji" ) SACountryCode="FJ" ;;
		"Falkland Islands (Malvinas)" | "Falkland Islands" ) SACountryCode="FK" ;;
		"Micronesia, Federated States Of" | "Micronesia" ) SACountryCode="FM" ;;
		"Faroe Islands" ) SACountryCode="FO" ;;
		"France" ) SACountryCode="FR" ;;
		"Gabon" ) SACountryCode="GA" ;;
		"United Kingdom" ) SACountryCode="GB" ;;
		"Grenada" ) SACountryCode="GD" ;;
		"Georgia" ) SACountryCode="GE" ;;
		"French Guiana" ) SACountryCode="GF" ;;
		"Ghana" ) SACountryCode="GH" ;;
		"Gibraltar" ) SACountryCode="GI" ;;
		"Greenland" ) SACountryCode="GL" ;;
		"Gambia" ) SACountryCode="GM" ;;
		"Guinea" ) SACountryCode="GN" ;;
		"Guadeloupe" ) SACountryCode="GP" ;;
		"Equatorial Guinea" ) SACountryCode="GQ" ;;
		"Greece" ) SACountryCode="GR" ;;
		"South Georgia and The South Sandwich Islands" | "South Georgia and the South Sandwich Islands" ) SACountryCode="GS" ;;
		"Guatemala" ) SACountryCode="GT" ;;
		"Guam" ) SACountryCode="GU" ;;
		"Guinea-Bissau" ) SACountryCode="GW" ;;
		"Guyana" ) SACountryCode="GY" ;;
		"Hong Kong" | "Hong Kong SAR China" ) SACountryCode="HK" ;;
		"Heard and Mc Donald Islands" | "Heard Island and McDonald Islands" ) SACountryCode="HM" ;;
		"Honduras" ) SACountryCode="HN" ;;
		"Croatia" ) SACountryCode="HR" ;;
		"Haiti" ) SACountryCode="HT" ;;
		"Hungary" ) SACountryCode="HU" ;;
		"Indonesia" ) SACountryCode="ID" ;;
		"Ireland" ) SACountryCode="IE" ;;
		"Israel" ) SACountryCode="IL" ;;
		"India" ) SACountryCode="IN" ;;
		"British Indian Ocean Territory" ) SACountryCode="IO" ;;
		"Iraq" ) SACountryCode="IQ" ;;
		"Iceland" ) SACountryCode="IS" ;;
		"Italy" ) SACountryCode="IT" ;;
		"Jamaica" ) SACountryCode="JM" ;;
		"Jordan" ) SACountryCode="JO" ;;
		"Japan" ) SACountryCode="JP" ;;
		"Kenya" ) SACountryCode="KE" ;;
		"Kyrgyzstan" ) SACountryCode="KG" ;;
		"Cambodia" ) SACountryCode="KH" ;;
		"Kiribati" ) SACountryCode="KI" ;;
		"Comoros" ) SACountryCode="KM" ;;
		"Saint Kitts and Nevis" ) SACountryCode="KN" ;;
		"Korea, Republic Of" | "South Korea" ) SACountryCode="KR" ;;
		"Kuwait" ) SACountryCode="KW" ;;
		"Cayman Islands" ) SACountryCode="KY" ;;
		"Kazakhstan" ) SACountryCode="KZ" ;;
		"Lao People's Democratic Republic" | "Laos" ) SACountryCode="LA" ;;
		"Lebanon" ) SACountryCode="LB" ;;
		"Saint Lucia" ) SACountryCode="LC" ;;
		"Liechtenstein" ) SACountryCode="LI" ;;
		"Sri Lanka" ) SACountryCode="LK" ;;
		"Liberia" ) SACountryCode="LR" ;;
		"Lesotho" ) SACountryCode="LS" ;;
		"Lithuania" ) SACountryCode="LT" ;;
		"Luxembourg" ) SACountryCode="LU" ;;
		"Latvia" ) SACountryCode="LV" ;;
		"Morocco" ) SACountryCode="MA" ;;
		"Monaco" ) SACountryCode="MC" ;;
		"Moldova" ) SACountryCode="MD" ;;
		"Montenegro" ) SACountryCode="ME" ;;
		"Madagascar" ) SACountryCode="MG" ;;
		"Marshall Islands" ) SACountryCode="MH" ;;
		"Macedonia, The Former Yugoslav Republic Of" | "Macedonia" ) SACountryCode="MK" ;;
		"Mali" ) SACountryCode="ML" ;;
		"Myanmar" | "Myanmar [Burma]" ) SACountryCode="MM" ;;
		"Mongolia" ) SACountryCode="MN" ;;
		"Macau" | "Macau SAR China" ) SACountryCode="MO" ;;
		"Northern Mariana Islands" ) SACountryCode="MP" ;;
		"Martinique" ) SACountryCode="MQ" ;;
		"Mauritania" ) SACountryCode="MR" ;;
		"Montserrat" ) SACountryCode="MS" ;;
		"Malta" ) SACountryCode="MT" ;;
		"Mauritius" ) SACountryCode="MU" ;;
		"Maldives" ) SACountryCode="MV" ;;
		"Malawi" ) SACountryCode="MW" ;;
		"Mexico" ) SACountryCode="MX" ;;
		"Malaysia" ) SACountryCode="MY" ;;
		"Mozambique" ) SACountryCode="MZ" ;;
		"Namibia" ) SACountryCode="NA" ;;
		"New Caledonia" ) SACountryCode="NC" ;;
		"Niger" ) SACountryCode="NE" ;;
		"Norfolk Island" ) SACountryCode="NF" ;;
		"Nigeria" ) SACountryCode="NG" ;;
		"Nicaragua" ) SACountryCode="NI" ;;
		"Netherlands" ) SACountryCode="NL" ;;
		"Norway" ) SACountryCode="NO" ;;
		"Nepal" ) SACountryCode="NP" ;;
		"Nauru" ) SACountryCode="NR" ;;
		"Niue" ) SACountryCode="NU" ;;
		"New Zealand" ) SACountryCode="NZ" ;;
		"Oman" ) SACountryCode="OM" ;;
		"Panama" ) SACountryCode="PA" ;;
		"Peru" ) SACountryCode="PE" ;;
		"French Polynesia" ) SACountryCode="PF" ;;
		"Papua New Guinea" ) SACountryCode="PG" ;;
		"Philippines" ) SACountryCode="PH" ;;
		"Pakistan" ) SACountryCode="PK" ;;
		"Poland" ) SACountryCode="PL" ;;
		"St. Pierre and Miquelon" | "Saint Pierre and Miquelon" ) SACountryCode="PM" ;;
		"Pitcairn" | "Pitcairn Islands" ) SACountryCode="PN" ;;
		"Puerto Rico" ) SACountryCode="PR" ;;
		"Palestinian Authority" | "Palestinian Territory" | "Palestinian Territories" ) SACountryCode="PS" ;;
		"Portugal" ) SACountryCode="PT" ;;
		"Palau" ) SACountryCode="PW" ;;
		"Paraguay" ) SACountryCode="PY" ;;
		"Qatar" ) SACountryCode="QA" ;;
		"Reunion" | "Réunion" ) SACountryCode="RE" ;;
		"Romania" ) SACountryCode="RO" ;;
		"Serbia" ) SACountryCode="RS" ;;
		"Russian Federation" | "Russia" ) SACountryCode="RU" ;;
		"Rwanda" ) SACountryCode="RW" ;;
		"Saudi Arabia" ) SACountryCode="SA" ;;
		"Solomon Islands" ) SACountryCode="SB" ;;
		"Seychelles" ) SACountryCode="SC" ;;
		"Sweden" ) SACountryCode="SE" ;;
		"Singapore" ) SACountryCode="SG" ;;
		"St. Helena" | "Saint Helena" ) SACountryCode="SH" ;;
		"Slovenia" ) SACountryCode="SI" ;;
		"Svalbard and Jan Mayen Islands" | "Svalbard and Jan Mayen" ) SACountryCode="SJ" ;;
		"Slovak Republic" | "Slovakia" ) SACountryCode="SK" ;;
		"Sierra Leone" ) SACountryCode="SL" ;;
		"San Marino" ) SACountryCode="SM" ;;
		"Senegal" ) SACountryCode="SN" ;;
		"Somalia" ) SACountryCode="SO" ;;
		"Suriname" ) SACountryCode="SR" ;;
		"Sao Tome and Principe" | "São Tomé and Príncipe" ) SACountryCode="ST" ;;
		"El Salvador" ) SACountryCode="SV" ;;
		"Swaziland" ) SACountryCode="SZ" ;;
		"Turks and Caicos Islands" ) SACountryCode="TC" ;;
		"Chad" ) SACountryCode="TD" ;;
		"French Southern Territories" ) SACountryCode="TF" ;;
		"Togo" ) SACountryCode="TG" ;;
		"Thailand" ) SACountryCode="TH" ;;
		"Tajikistan" ) SACountryCode="TJ" ;;
		"Tokelau" ) SACountryCode="TK" ;;
		"Turkmenistan" ) SACountryCode="TM" ;;
		"Tunisia" ) SACountryCode="TN" ;;
		"Tonga" ) SACountryCode="TO" ;;
		"East Timor" ) SACountryCode="TP" ;;
		"Turkey" ) SACountryCode="TR" ;;
		"Trinidad and Tobago" ) SACountryCode="TT" ;;
		"Tuvalu" ) SACountryCode="TV" ;;
		"Taiwan" ) SACountryCode="TW" ;;
		"Tanzania, United Republic Of" | "Tanzania" ) SACountryCode="TZ" ;;
		"Ukraine" ) SACountryCode="UA" ;;
		"Uganda" ) SACountryCode="UG" ;;
		"United States Minor Outlying Islands" | "U.S. Minor Outlying Islands" ) SACountryCode="UM" ;;
		"United States" ) SACountryCode="US" ;;
		"Uruguay" ) SACountryCode="UY" ;;
		"Uzbekistan" ) SACountryCode="UZ" ;;
		"Holy See (Vatican City State)" | "Vatican" | "Vatican City" ) SACountryCode="VA" ;;
		"Saint Vincent and The Grenadines" | "Saint Vincent and the Grenadines" ) SACountryCode="VC" ;;
		"Venezuela" ) SACountryCode="VE" ;;
		"Virgin Islands (British)" | "British Virgin Islands" ) SACountryCode="VG" ;;
		"Virgin Islands (U.S.)" | "U.S. Virgin Islands" ) SACountryCode="VI" ;;
		"Viet Nam" | "Vietnam" ) SACountryCode="VN" ;;
		"Vanuatu" ) SACountryCode="VU" ;;
		"Wallis and Futuna Islands" | "Wallis and Futuna" ) SACountryCode="WF" ;;
		"Samoa" ) SACountryCode="WS" ;;
		"Yemen" ) SACountryCode="YE" ;;
		"Mayotte" ) SACountryCode="YT" ;;
		"Serbia and Montenegro" ) SACountryCode="YU" ;;
		"South Africa" ) SACountryCode="ZA" ;;
		"Zambia" ) SACountryCode="ZM" ;;
		"Zimbabwe" ) SACountryCode="ZW" ;;
	esac
}

function set_ResourceID {
	# ${1}: Language Code
	# ${2}: Country Code
	unset ResourceID
	case "${1}" in
		"ja" ) case ${TargetOSMinor} in
			5 ) ResourceID=16384 ;;
			* ) case "${2}" in
				"JP" ) ResourceID=16384 ;;
			esac ;;
		esac ;;
		"fr" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"CA" ) ResourceID=11 ;;
				"CH" ) ResourceID=18 ;;
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=1 ;;
			esac ;;
			* ) case "${2}" in
				"CA" ) ResourceID=11 ;;
				"CH" ) ResourceID=18 ;;
				"FR" ) ResourceID=1 ;;
			esac ;;
		esac ;;
		"de" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"AT" ) ResourceID=92 ;;
				"CH" ) ResourceID=19 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=3 ;;
			esac ;;
			* ) case "${2}" in
				"AT" ) ResourceID=92 ;;
				"CH" ) ResourceID=19 ;;
				"DE" ) ResourceID=3 ;;
			esac ;;
		esac ;;
		"es" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"DE" ) ResourceID=3 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=8 ;;
			esac ;;
			* ) case "${2}" in
				"ES" ) ResourceID=8 ;;
			esac ;;
		esac ;;
		"it" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"CH" ) ResourceID=36 ;;
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=4 ;;
			esac ;;
			* ) case "${2}" in
				"CH" ) ResourceID=36 ;;
				"IT" ) ResourceID=4 ;;
			esac ;;
		esac ;;
		"pt" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"PT" ) ResourceID=10 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=71 ;;
			esac ;;
			* ) case "${2}" in
				"BR" ) ResourceID=71 ;;
				"PT" ) ResourceID=10 ;;
			esac ;;
		esac ;;
		"pt-PT" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=10 ;;
			esac ;;
			* ) case "${2}" in
				"PT" ) ResourceID=10 ;;
			esac ;;
		esac ;;
		"nl" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"BE" ) ResourceID=6 ;;
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=5 ;;
			esac ;;
			* ) case "${2}" in
				"BE" ) ResourceID=6 ;;
				"NL" ) ResourceID=5 ;;
			esac ;;
		esac ;;
		"sv" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=7 ;;
			esac ;;
			* ) case "${2}" in
				"SE" ) ResourceID=7 ;;
			esac ;;
		esac ;;
		"nb" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=12 ;;
			esac ;;
			* ) case "${2}" in
				"NO" ) ResourceID=12 ;;
			esac ;;
		esac ;;
		"da" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=9 ;;
			esac ;;
			* ) case "${2}" in
				"DK" ) ResourceID=9 ;;
			esac ;;
		esac ;;
		"fi" ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				"US" ) ResourceID=0 ;;
				* ) ResourceID=17 ;;
			esac ;;
			* ) case "${2}" in
				"FI" ) ResourceID=17 ;;
			esac ;;
		esac ;;
		"ru" ) case ${TargetOSMinor} in
			5 ) ResourceID=19456 ;;
			* ) case "${2}" in
				"RU" ) ResourceID=19456 ;;
			esac ;;
		esac ;;
		"pl" ) case ${TargetOSMinor} in
			5 ) ResourceID=30776 ;;
			* ) case "${2}" in
				"PL" ) ResourceID=30776 ;;
			esac ;;
		esac ;;
		"zh-Hans" ) case ${TargetOSMinor} in
			5 ) ResourceID=28672 ;;
			* ) case "${2}" in
				"CN" ) ResourceID=28672 ;;
			esac ;;
		esac ;;
		"zh-Hant" ) case ${TargetOSMinor} in
			5 ) ResourceID=16896 ;;
			* ) case "${2}" in
				"TW" ) ResourceID=16896 ;;
			esac ;;
		esac ;;
		"ko" ) case ${TargetOSMinor} in
			5 ) ResourceID=17408 ;;
			* ) case "${2}" in
				"KR" ) ResourceID=17408 ;;
			esac ;;
		esac ;;
		* ) case ${TargetOSMinor} in
			5 ) case "${2}" in
				"AU" ) ResourceID=15 ;;
				"DE" ) ResourceID=3 ;;
				"ES" ) ResourceID=8 ;;
				"FR" ) ResourceID=1 ;;
				"GB" ) ResourceID=2 ;;
				"IE" ) ResourceID=108 ;;
				"IT" ) ResourceID=4 ;;
				* ) ResourceID=0 ;;
			esac ;;
			* ) case "${2}" in
				"AU" ) ResourceID=15 ;;
				"GB" ) ResourceID=2 ;;
				"IE" ) ResourceID=108 ;;
				"NZ" ) ResourceID=15 ;;
				"US" ) ResourceID=0 ;;
			esac ;;
		esac ;;
	esac
}

# Section: Keyboard

function set_SAKeyboard_SATypingStyle {
	# ${1}: InputSourceID
	unset SAKeyboard
	unset SATypingStyle
	case "${1}" in
		"AfghanDari" ) SAKeyboard="Afghan Dari" ;;
		"AfghanPashto" ) SAKeyboard="Afghan Pashto" ;;
		"AfghanUzbek" ) SAKeyboard="Afghan Uzbek" ;;
		"Arabic" ) SAKeyboard="Arabic" ;;
		"ArabicPC" ) SAKeyboard="Arabic - PC" ;;
		"Arabic-QWERTY" ) SAKeyboard="Arabic - QWERTY" ;;
		"Armenian-HMQWERTY" ) SAKeyboard="Armenian - HM QWERTY" ;;
		"Armenian-WesternQWERTY" ) SAKeyboard="Armenian - Western QWERTY" ;;
		"Australian" ) SAKeyboard="Australian" ;;
		"Austrian" ) SAKeyboard="Austrian" ;;
		"Azeri" ) SAKeyboard="Azeri" ;;
		"Bangla" ) SAKeyboard="Bangla" ;;
		"Bangla-QWERTY" ) SAKeyboard="Bangla - Qwerty" ;;
		"Belgian" ) SAKeyboard="Belgian" ;;
		"Brazilian" ) SAKeyboard="Brazilian" ;;
		"British" ) SAKeyboard="British" ;;
		"British-PC" ) SAKeyboard="British - PC" ;;
		"Bulgarian" ) SAKeyboard="Bulgarian" ;;
		"Bulgarian-Phonetic" ) SAKeyboard="Bulgarian - Phonetic" ;;
		"Byelorussian" ) SAKeyboard="Byelorussian" ;;
		"Canadian" ) SAKeyboard="Canadian English" ;;
		"Canadian-CSA" ) SAKeyboard="Canadian French - CSA" ;;
		"Cherokee-Nation" ) SAKeyboard="Cherokee - Nation" ;;
		"Cherokee-QWERTY" ) SAKeyboard="Cherokee - QWERTY" ;;
		"SCIM.ITABC" )
			case ${TargetOSMinor} in
				5 ) SAKeyboard="Simplified Chinese" ; SATypingStyle="ITABC" ;;
				* ) SAKeyboard="Chinese - Simplified" ; SATypingStyle="Pinyin - Simplified" ;;
			esac ;;
		"SCIM.WBH" )
			case ${TargetOSMinor} in
				5 ) SAKeyboard="Simplified Chinese" ; SATypingStyle="Wubi Hua" ;;
				* ) SAKeyboard="Chinese - Simplified" ; SATypingStyle="Wubi Hua" ;;
			esac ;;
		"SCIM.WBX" )
			case ${TargetOSMinor} in
				5 ) SAKeyboard="Simplified Chinese" ; SATypingStyle="Wubi Xing" ;;
				* ) SAKeyboard="Chinese - Simplified" ; SATypingStyle="Wubi Xing" ;;
			esac ;;
		"TCIM.Cangjie" )
			case ${TargetOSMinor} in
				5 ) SAKeyboard="Traditional Chinese" ; SATypingStyle="Cangjie" ;;
				* ) SAKeyboard="Chinese - Traditional" ; SATypingStyle="Cangjie" ;;
			esac ;;
		"TCIM.Dayi" )
			case ${TargetOSMinor} in
				5 ) SAKeyboard="Traditional Chinese" ; SATypingStyle="Dayi(Pro)" ;;
				* ) SAKeyboard="Chinese - Traditional" ; SATypingStyle="Dayi Pro" ;;
			esac ;;
		"TCIM.Hanin" ) SAKeyboard="Traditional Chinese" ; SATypingStyle="Hanin" ;;
		"TCIM.Jianyi" )
			case ${TargetOSMinor} in
				5 ) SAKeyboard="Traditional Chinese" ; SATypingStyle="Jianyi" ;;
				6 | 7 ) SAKeyboard="Chinese - Traditional" ; SATypingStyle="Jianyi" ;;
				* ) SAKeyboard="Chinese - Traditional" ; SATypingStyle="Sucheng" ;;
			esac ;;
		"TCIM.Pinyin" )
			case ${TargetOSMinor} in
				5 ) SAKeyboard="Traditional Chinese" ; SATypingStyle="Pinyin" ;;
				* ) SAKeyboard="Chinese - Traditional" ; SATypingStyle="Pinyin - Traditional" ;;
			esac ;;
		"TCIM.Zhuyin" )
			case ${TargetOSMinor} in
				5 ) SAKeyboard="Traditional Chinese" ; SATypingStyle="Zhuyin" ;;
				* ) SAKeyboard="Chinese - Traditional" ; SATypingStyle="Zhuyin" ;;
			esac ;;
		"TCIM.ZhuyinEten" ) SAKeyboard="Chinese - Traditional" ; SATypingStyle="Zhuyin - Eten" ;;
		"Colemak" ) SAKeyboard="Colemak" ;;
		"Croatian" ) SAKeyboard="Croatian" ;;
		"Croatian-PC" ) SAKeyboard="Croatian - PC" ;;
		"Czech" ) SAKeyboard="Czech" ;;
		"Czech-QWERTY" ) SAKeyboard="Czech - QWERTY" ;;
		"Danish" ) SAKeyboard="Danish" ;;
		"Devanagari" ) SAKeyboard="Devanagari" ;;
		"Devanagari-QWERTY" ) SAKeyboard="Devanagari - QWERTY" ;;
		"Dutch" ) SAKeyboard="Dutch" ;;
		"Dvorak" ) SAKeyboard="Dvorak" ;;
		"Dvorak-Left" ) SAKeyboard="Dvorak - Left" ;;
		"DVORAK-QWERTYCMD" ) SAKeyboard="Dvorak - Qwerty ⌘" ;;
		"Dvorak-Right" ) SAKeyboard="Dvorak - Right" ;;
		"Estonian" ) SAKeyboard="Estonian" ;;
		"Faroese" ) SAKeyboard="Faroese" ;;
		"Finnish" ) SAKeyboard="Finnish" ;;
		"FinnishExtended" ) SAKeyboard="Finnish Extended" ;;
		"FinnishSami-PC" ) SAKeyboard="Finnish Sami - PC" ;;
		"French" ) SAKeyboard="French" ;;
		"French-numerical" ) SAKeyboard="French - Numerical" ;;
		"Georgian-QWERTY" ) SAKeyboard="Georgian - QWERTY" ;;
		"German" ) SAKeyboard="German" ;;
		"Greek" ) SAKeyboard="Greek" ;;
		"GreekPolytonic" ) SAKeyboard="Greek Polytonic" ;;
		"Gujarati" ) SAKeyboard="Gujarati" ;;
		"Gujarati-QWERTY" ) SAKeyboard="Gujarati - QWERTY" ;;
		"Gurmukhi" ) SAKeyboard="Gurmukhi" ;;
		"Gurmukhi-QWERTY" ) SAKeyboard="Gurmukhi - QWERTY" ;;
		"Korean.2SetKorean" ) SAKeyboard="Hangul" ; SATypingStyle="2-Set Korean" ;;
		"Korean.3SetKorean" ) SAKeyboard="Hangul" ; SATypingStyle="3-Set Korean" ;;
		"Korean.390Sebulshik" ) SAKeyboard="Hangul" ; SATypingStyle="390 Sebulshik" ;;
		"Korean.GongjinCheongRomaja" ) SAKeyboard="Hangul" ; SATypingStyle="GongjinCheong Romaja" ;;
		"Korean.HNCRomaja" ) SAKeyboard="Hangul" ; SATypingStyle="HNC Romaja" ;;
		"Hawaiian" ) SAKeyboard="Hawaiian" ;;
		"Hebrew" ) SAKeyboard="Hebrew" ;;
		"Hebrew-PC" ) SAKeyboard="Hebrew - PC" ;;
		"Hebrew-QWERTY" ) SAKeyboard="Hebrew - QWERTY" ;;
		"Hungarian" ) SAKeyboard="Hungarian" ;;
		"Icelandic" ) SAKeyboard="Icelandic" ;;
		"Inuktitut-Nunavut" ) SAKeyboard="Inuktitut - Nunavut" ;;
		"Inuktitut-Nutaaq" ) SAKeyboard="Inuktitut - Nutaaq" ;;
		"Inuktitut-QWERTY" ) SAKeyboard="Inuktitut - QWERTY" ;;
		"InuttitutNunavik" ) SAKeyboard="Inuttitut Nunavik" ;;
		"Irish" ) SAKeyboard="Irish" ;;
		"IrishExtended" ) SAKeyboard="Irish Extended" ;;
		"Italian" )
			case ${TargetOSMinor} in
				5 | 6 ) SAKeyboard="Italian" ;;
				7 | 8 ) SAKeyboard="Italian Typewriter" ;;
			esac ;;
		"Italian-Pro" )
			case ${TargetOSMinor} in
				5 | 6 ) SAKeyboard="Italian - Pro" ;;
				7 | 8 ) SAKeyboard="Italian" ;;
			esac ;;
		"Jawi-QWERTY" ) SAKeyboard="Jawi - QWERTY" ;;
		"Kannada" ) SAKeyboard="Kannada" ;;
		"Kannada-QWERTY" ) SAKeyboard="Kannada - QWERTY" ;;
		"Kazakh" ) SAKeyboard="Kazakh" ;;
		"Khmer" ) SAKeyboard="Khmer" ;;
		"Japanese.Katakana" ) SAKeyboard="Kotoeri" ; SATypingStyle="Kana" ;;
		"Japanese.Roman" ) SAKeyboard="Kotoeri" ; SATypingStyle="Romaji" ;;
		"Kurdish-Sorani" ) SAKeyboard="Kurdish-Sorani" ;;
		"Latvian" ) SAKeyboard="Latvian" ;;
		"Lithuanian" ) SAKeyboard="Lithuanian" ;;
		"Macedonian" ) SAKeyboard="Macedonian" ;;
		"Malayalam" ) SAKeyboard="Malayalam" ;;
		"Malayalam-QWERTY" ) SAKeyboard="Malayalam - QWERTY" ;;
		"Maltese" ) SAKeyboard="Maltese" ;;
		"Maori" ) SAKeyboard="Maori" ;;
		"Myanmar-QWERTY" ) SAKeyboard="Myanmar - QWERTY" ;;
		"Nepali" ) SAKeyboard="Nepali" ;;
		"NorthernSami" ) SAKeyboard="Northern Sami" ;;
		"Norwegian" ) SAKeyboard="Norwegian" ;;
		"NorwegianExtended" ) SAKeyboard="Norwegian Extended" ;;
		"NorwegianSami-PC" ) SAKeyboard="Norwegian Sami - PC" ;;
		"Oriya" ) SAKeyboard="Oriya" ;;
		"Oriya-QWERTY" ) SAKeyboard="Oriya - QWERTY" ;;
		"Persian" ) SAKeyboard="Persian" ;;
		"Persian-ISIRI2901" )
			case ${TargetOSMinor} in
				8 ) SAKeyboard="Persian - ISIRI" ;;
				* ) SAKeyboard="Persian - ISIRI 2901" ;;
			esac ;;
		"Persian-QWERTY" ) SAKeyboard="Persian - QWERTY" ;;
		"Polish" ) SAKeyboard="Polish" ;;
		"PolishPro" ) SAKeyboard="Polish Pro" ;;
		"Portuguese" ) SAKeyboard="Portuguese" ;;
		"Romanian" ) SAKeyboard="Romanian" ;;
		"Romanian-Standard" ) SAKeyboard="Romanian - Standard" ;;
		"Russian" ) SAKeyboard="Russian" ;;
		"RussianWin" ) SAKeyboard="Russian - PC" ;;
		"Russian-Phonetic" ) SAKeyboard="Russian - Phonetic" ;;
		"Sami-PC" ) SAKeyboard="Sami - PC" ;;
		"Serbian" ) SAKeyboard="Serbian" ;;
		"Serbian-Latin" ) SAKeyboard="Serbian - Latin" ;;
		"Sinhala" ) SAKeyboard="Sinhala" ;;
		"Sinhala-QWERTY" ) SAKeyboard="Sinhala - QWERTY" ;;
		"Slovak" ) SAKeyboard="Slovak" ;;
		"Slovak-QWERTY" ) SAKeyboard="Slovak - QWERTY" ;;
		"Slovenian" ) SAKeyboard="Slovenian" ;;
		"Spanish" ) SAKeyboard="Spanish" ;;
		"Spanish-ISO" ) SAKeyboard="Spanish - ISO" ;;
		"Swedish" ) SAKeyboard="Swedish" ;;
		"Swedish-Pro" ) SAKeyboard="Swedish - Pro" ;;
		"SwedishSami-PC" ) SAKeyboard="Swedish Sami - PC" ;;
		"SwissFrench" ) SAKeyboard="Swiss French" ;;
		"SwissGerman" ) SAKeyboard="Swiss German" ;;
		"Tamil.AnjalIM" ) SAKeyboard="Tamil Input Method" ; SATypingStyle="Anjal" ;;
		"Tamil.Tamil99" ) SAKeyboard="Tamil Input Method" ; SATypingStyle="Tamil99" ;;
		"Telugu" ) SAKeyboard="Telugu" ;;
		"Telugu-QWERTY" ) SAKeyboard="Telugu - QWERTY" ;;
		"Thai" ) SAKeyboard="Thai" ;;
		"Thai-PattaChote" ) SAKeyboard="Thai - PattaChote" ;;
		"TibetanOtaniUS" ) SAKeyboard="Tibetan - Otani" ;;
		"Tibetan-QWERTY" ) SAKeyboard="Tibetan - QWERTY" ;;
		"Tibetan-Wylie" ) SAKeyboard="Tibetan - Wylie" ;;
		"Turkish" ) SAKeyboard="Turkish" ;;
		"Turkish-QWERTY" ) SAKeyboard="Turkish - QWERTY" ;;
		"Turkish-QWERTY-PC" ) SAKeyboard="Turkish - QWERTY PC" ;;
		"US" ) SAKeyboard="U.S." ;;
		"USExtended" ) SAKeyboard="U.S. Extended" ;;
		"USInternational-PC" ) SAKeyboard="U.S. International - PC" ;;
		"Ukrainian" ) SAKeyboard="Ukrainian" ;;
		"UnicodeHexInput" ) SAKeyboard="Unicode Hex Input" ;;
		"Urdu" ) SAKeyboard="Urdu" ;;
		"Uyghur" ) SAKeyboard="Uyghur" ;;
		"Uyghur-QWERTY" ) SAKeyboard="Uyghur - QWERTY" ;;
		"Vietnamese" ) SAKeyboard="Vietnamese" ;;
		"VietnameseSimpleTelex" ) SAKeyboard="Vietnamese UniKey" ; SATypingStyle="Simple Telex" ;;
		"VietnameseTelex" ) SAKeyboard="Vietnamese UniKey" ; SATypingStyle="Telex" ;;
		"VietnameseVIQR" ) SAKeyboard="Vietnamese UniKey" ; SATypingStyle="VIQR" ;;
		"VietnameseVNI" ) SAKeyboard="Vietnamese UniKey" ; SATypingStyle="VNI" ;;
		"Welsh" ) SAKeyboard="Welsh" ;;
	esac
}

function set_InputSourceIDs {
	case ${TargetOSMinor} in
		5 ) InputSourceIDs=( "AfghanDari" "AfghanPashto" "AfghanUzbek" "Arabic" "Arabic-QWERTY" "ArabicPC" "Armenian-HMQWERTY" "Armenian-WesternQWERTY" "Australian" "Austrian" "Azeri" "Belgian" "Brazilian" "British" "Bulgarian" "Bulgarian-Phonetic" "Byelorussian" "Canadian" "Canadian-CSA" "Cherokee-Nation" "Cherokee-QWERTY" "Croatian" "Czech" "Czech-QWERTY" "Danish" "Devanagari" "Devanagari-QWERTY" "Dutch" "Dvorak" "DVORAK-QWERTYCMD" "Estonian" "Faroese" "Finnish" "FinnishExtended" "FinnishSami-PC" "French" "French-numerical" "German" "Greek" "GreekPolytonic" "Gujarati" "Gujarati-QWERTY" "Gurmukhi" "Gurmukhi-QWERTY" "Hawaiian" "Hebrew" "Hebrew-QWERTY" "Hungarian" "Icelandic" "Inuktitut-Nunavut" "Inuktitut-Nutaaq" "Inuktitut-QWERTY" "InuttitutNunavik" "Irish" "IrishExtended" "Italian" "Italian-Pro" "Japanese.Katakana" "Japanese.Roman" "Jawi-QWERTY" "Kazakh" "Korean.2SetKorean" "Korean.390Sebulshik" "Korean.3SetKorean" "Korean.GongjinCheongRomaja" "Korean.HNCRomaja" "Latvian" "Lithuanian" "Macedonian" "Maltese" "Maori" "Nepali" "NorthernSami" "Norwegian" "NorwegianExtended" "NorwegianSami-PC" "Persian" "Persian-ISIRI2901" "Persian-QWERTY" "Polish" "PolishPro" "Portuguese" "Romanian" "Romanian-Standard" "Russian" "Russian-Phonetic" "RussianWin" "Sami-PC" "SCIM.ITABC" "SCIM.WBH" "SCIM.WBX" "Serbian" "Serbian-Latin" "Slovak" "Slovak-QWERTY" "Slovenian" "Spanish" "Spanish-ISO" "Swedish" "Swedish-Pro" "SwedishSami-PC" "SwissFrench" "SwissGerman" "Tamil.AnjalIM" "Tamil.Tamil99" "TCIM.Cangjie" "TCIM.Dayi" "TCIM.Hanin" "TCIM.Jianyi" "TCIM.Pinyin" "TCIM.Zhuyin" "Thai" "Thai-PattaChote" "Tibetan-QWERTY" "Tibetan-Wylie" "TibetanOtaniUS" "Turkish" "Turkish-QWERTY" "Turkish-QWERTY-PC" "Ukrainian" "UnicodeHexInput" "US" "USExtended" "Vietnamese" "VietnameseSimpleTelex" "VietnameseTelex" "VietnameseVIQR" "VietnameseVNI" "Welsh" ) ;;
		6 ) InputSourceIDs=( "AfghanDari" "AfghanPashto" "AfghanUzbek" "Arabic" "Arabic-QWERTY" "ArabicPC" "Armenian-HMQWERTY" "Armenian-WesternQWERTY" "Australian" "Austrian" "Azeri" "Belgian" "Brazilian" "British" "Bulgarian" "Bulgarian-Phonetic" "Byelorussian" "Canadian" "Canadian-CSA" "Cherokee-Nation" "Cherokee-QWERTY" "Croatian" "Croatian-PC" "Czech" "Czech-QWERTY" "Danish" "Devanagari" "Devanagari-QWERTY" "Dutch" "Dvorak" "Dvorak-Left" "DVORAK-QWERTYCMD" "Dvorak-Right" "Estonian" "Faroese" "Finnish" "FinnishExtended" "FinnishSami-PC" "French" "French-numerical" "German" "Greek" "GreekPolytonic" "Gujarati" "Gujarati-QWERTY" "Gurmukhi" "Gurmukhi-QWERTY" "Hawaiian" "Hebrew" "Hebrew-QWERTY" "Hungarian" "Icelandic" "Inuktitut-Nunavut" "Inuktitut-Nutaaq" "Inuktitut-QWERTY" "InuttitutNunavik" "Irish" "IrishExtended" "Italian" "Italian-Pro" "Japanese.Katakana" "Japanese.Roman" "Jawi-QWERTY" "Kazakh" "Korean.2SetKorean" "Korean.390Sebulshik" "Korean.3SetKorean" "Korean.GongjinCheongRomaja" "Korean.HNCRomaja" "Latvian" "Lithuanian" "Macedonian" "Maltese" "Maori" "Nepali" "NorthernSami" "Norwegian" "NorwegianExtended" "NorwegianSami-PC" "Persian" "Persian-ISIRI2901" "Persian-QWERTY" "Polish" "PolishPro" "Portuguese" "Romanian" "Romanian-Standard" "Russian" "Russian-Phonetic" "RussianWin" "Sami-PC" "SCIM.ITABC" "SCIM.WBH" "SCIM.WBX" "Serbian" "Serbian-Latin" "Slovak" "Slovak-QWERTY" "Slovenian" "Spanish" "Spanish-ISO" "Swedish" "Swedish-Pro" "SwedishSami-PC" "SwissFrench" "SwissGerman" "Tamil.AnjalIM" "Tamil.Tamil99" "TCIM.Cangjie" "TCIM.Dayi" "TCIM.Jianyi" "TCIM.Pinyin" "TCIM.Zhuyin" "Thai" "Thai-PattaChote" "Tibetan-QWERTY" "Tibetan-Wylie" "TibetanOtaniUS" "Turkish" "Turkish-QWERTY" "Turkish-QWERTY-PC" "Ukrainian" "UnicodeHexInput" "US" "USExtended" "USInternational-PC" "Uyghur-QWERTY" "Vietnamese" "VietnameseSimpleTelex" "VietnameseTelex" "VietnameseVIQR" "VietnameseVNI" "Welsh" ) ;;
		7 ) InputSourceIDs=( "AfghanDari" "AfghanPashto" "AfghanUzbek" "Arabic" "Arabic-QWERTY" "ArabicPC" "Armenian-HMQWERTY" "Armenian-WesternQWERTY" "Australian" "Austrian" "Azeri" "Bangla" "Bangla-QWERTY" "Belgian" "Brazilian" "British" "Bulgarian" "Bulgarian-Phonetic" "Byelorussian" "Canadian" "Canadian-CSA" "Cherokee-Nation" "Cherokee-QWERTY" "Colemak" "Croatian" "Croatian-PC" "Czech" "Czech-QWERTY" "Danish" "Devanagari" "Devanagari-QWERTY" "Dutch" "Dvorak" "Dvorak-Left" "DVORAK-QWERTYCMD" "Dvorak-Right" "Estonian" "Faroese" "Finnish" "FinnishExtended" "FinnishSami-PC" "French" "French-numerical" "German" "Greek" "GreekPolytonic" "Gujarati" "Gujarati-QWERTY" "Gurmukhi" "Gurmukhi-QWERTY" "Hawaiian" "Hebrew" "Hebrew-PC" "Hebrew-QWERTY" "Hungarian" "Icelandic" "Inuktitut-Nunavut" "Inuktitut-Nutaaq" "Inuktitut-QWERTY" "InuttitutNunavik" "Irish" "IrishExtended" "Italian" "Italian-Pro" "Japanese.Katakana" "Japanese.Roman" "Jawi-QWERTY" "Kannada" "Kannada-QWERTY" "Kazakh" "Khmer" "Korean.2SetKorean" "Korean.390Sebulshik" "Korean.3SetKorean" "Korean.GongjinCheongRomaja" "Korean.HNCRomaja" "Kurdish-Sorani" "Latvian" "Lithuanian" "Macedonian" "Malayalam" "Malayalam-QWERTY" "Maltese" "Maori" "Myanmar-QWERTY" "Nepali" "NorthernSami" "Norwegian" "NorwegianExtended" "NorwegianSami-PC" "Oriya" "Oriya-QWERTY" "Persian" "Persian-ISIRI2901" "Persian-QWERTY" "Polish" "PolishPro" "Portuguese" "Romanian" "Romanian-Standard" "Russian" "Russian-Phonetic" "RussianWin" "Sami-PC" "SCIM.ITABC" "SCIM.WBH" "SCIM.WBX" "Serbian" "Serbian-Latin" "Sinhala" "Sinhala-QWERTY" "Slovak" "Slovak-QWERTY" "Slovenian" "Spanish" "Spanish-ISO" "Swedish" "Swedish-Pro" "SwedishSami-PC" "SwissFrench" "SwissGerman" "Tamil.AnjalIM" "Tamil.Tamil99" "TCIM.Cangjie" "TCIM.Jianyi" "TCIM.Pinyin" "TCIM.Zhuyin" "Telugu" "Telugu-QWERTY" "Thai" "Thai-PattaChote" "Tibetan-QWERTY" "Tibetan-Wylie" "TibetanOtaniUS" "Turkish" "Turkish-QWERTY" "Turkish-QWERTY-PC" "Ukrainian" "UnicodeHexInput" "Urdu" "US" "USExtended" "USInternational-PC" "Uyghur-QWERTY" "Vietnamese" "VietnameseSimpleTelex" "VietnameseTelex" "VietnameseVIQR" "VietnameseVNI" "Welsh" ) ;;
		* ) InputSourceIDs=( "AfghanDari" "AfghanPashto" "AfghanUzbek" "Arabic" "Arabic-QWERTY" "ArabicPC" "Armenian-HMQWERTY" "Armenian-WesternQWERTY" "Australian" "Austrian" "Azeri" "Bangla" "Bangla-QWERTY" "Belgian" "Brazilian" "British" "British-PC" "Bulgarian" "Bulgarian-Phonetic" "Byelorussian" "Canadian" "Canadian-CSA" "Cherokee-Nation" "Cherokee-QWERTY" "Colemak" "Croatian" "Croatian-PC" "Czech" "Czech-QWERTY" "Danish" "Devanagari" "Devanagari-QWERTY" "Dutch" "Dvorak" "Dvorak-Left" "DVORAK-QWERTYCMD" "Dvorak-Right" "Estonian" "Faroese" "Finnish" "FinnishExtended" "FinnishSami-PC" "French" "French-numerical" "Georgian-QWERTY" "German" "Greek" "GreekPolytonic" "Gujarati" "Gujarati-QWERTY" "Gurmukhi" "Gurmukhi-QWERTY" "Hawaiian" "Hebrew" "Hebrew-PC" "Hebrew-QWERTY" "Hungarian" "Icelandic" "Inuktitut-Nunavut" "Inuktitut-Nutaaq" "Inuktitut-QWERTY" "InuttitutNunavik" "Irish" "IrishExtended" "Italian" "Italian-Pro" "Japanese.Katakana" "Japanese.Roman" "Jawi-QWERTY" "Kannada" "Kannada-QWERTY" "Kazakh" "Khmer" "Korean.2SetKorean" "Korean.390Sebulshik" "Korean.3SetKorean" "Korean.GongjinCheongRomaja" "Korean.HNCRomaja" "Kurdish-Sorani" "Latvian" "Lithuanian" "Macedonian" "Malayalam" "Malayalam-QWERTY" "Maltese" "Maori" "Myanmar-QWERTY" "Nepali" "NorthernSami" "Norwegian" "NorwegianExtended" "NorwegianSami-PC" "Oriya" "Oriya-QWERTY" "Persian" "Persian-ISIRI2901" "Persian-QWERTY" "Polish" "PolishPro" "Portuguese" "Romanian" "Romanian-Standard" "Russian" "Russian-Phonetic" "RussianWin" "Sami-PC" "SCIM.ITABC" "SCIM.WBH" "SCIM.WBX" "Serbian" "Serbian-Latin" "Sinhala" "Sinhala-QWERTY" "Slovak" "Slovak-QWERTY" "Slovenian" "Spanish" "Spanish-ISO" "Swedish" "Swedish-Pro" "SwedishSami-PC" "SwissFrench" "SwissGerman" "Tamil.AnjalIM" "Tamil.Tamil99" "TCIM.Cangjie" "TCIM.Jianyi" "TCIM.Pinyin" "TCIM.Zhuyin" "TCIM.ZhuyinEten" "Telugu" "Telugu-QWERTY" "Thai" "Thai-PattaChote" "Tibetan-QWERTY" "Tibetan-Wylie" "TibetanOtaniUS" "Turkish" "Turkish-QWERTY" "Turkish-QWERTY-PC" "Ukrainian" "UnicodeHexInput" "Urdu" "US" "USExtended" "USInternational-PC" "Uyghur" "Vietnamese" "VietnameseSimpleTelex" "VietnameseTelex" "VietnameseVIQR" "VietnameseVNI" "Welsh" ) ;;
	esac
}

function refresh_Keyboard {
	set_InputSourceIDs
	j=0 ; for ID in "${InputSourceIDs[@]}" ; do if [ "${ID}" == "${InputSourceID}" ] ; then j=1 ; break ; fi ; done
	if [ ${j} -eq 0 ] ; then InputSourceID="US" ; fi
	set_SAKeyboard_SATypingStyle "${InputSourceID}"
}

function set_AllKeyboards {
	case ${TargetOSMinor} in
		5 ) AllKeyboards=( "Afghan Dari" "Afghan Pashto" "Afghan Uzbek" "Arabic" "Arabic - PC" "Arabic - QWERTY" "Armenian - HM QWERTY" "Armenian - Western QWERTY" "Australian" "Austrian" "Azeri" "Belgian" "Brazilian" "British" "Bulgarian" "Bulgarian - Phonetic" "Byelorussian" "Canadian English" "Canadian French - CSA" "Cherokee - Nation" "Cherokee - QWERTY" "Croatian" "Czech" "Czech - QWERTY" "Danish" "Devanagari" "Devanagari - QWERTY" "Dutch" "Dvorak" "Dvorak - Qwerty ⌘" "Estonian" "Faroese" "Finnish" "Finnish Extended" "Finnish Sami - PC" "French" "French - Numerical" "German" "Greek" "Greek Polytonic" "Gujarati" "Gujarati - QWERTY" "Gurmukhi" "Gurmukhi - QWERTY" "Hangul" "Hawaiian" "Hebrew" "Hebrew - QWERTY" "Hungarian" "Icelandic" "Inuktitut - Nunavut" "Inuktitut - Nutaaq" "Inuktitut - QWERTY" "Inuttitut Nunavik" "Irish" "Irish Extended" "Italian" "Italian - Pro" "Jawi - QWERTY" "Kazakh" "Kotoeri" "Latvian" "Lithuanian" "Macedonian" "Maltese" "Maori" "Nepali" "Northern Sami" "Norwegian" "Norwegian Extended" "Norwegian Sami - PC" "Persian" "Persian - ISIRI 2901" "Persian - QWERTY" "Polish" "Polish Pro" "Portuguese" "Romanian" "Romanian - Standard" "Russian" "Russian - PC" "Russian - Phonetic" "Sami - PC" "Serbian" "Serbian - Latin" "Simplified Chinese" "Slovak" "Slovak - QWERTY" "Slovenian" "Spanish" "Spanish - ISO" "Swedish" "Swedish - Pro" "Swedish Sami - PC" "Swiss French" "Swiss German" "Tamil Input Method" "Thai" "Thai - PattaChote" "Tibetan - Otani" "Tibetan - QWERTY" "Tibetan - Wylie" "Traditional Chinese" "Turkish" "Turkish - QWERTY" "Turkish - QWERTY PC" "U.S." "U.S. Extended" "Ukrainian" "Unicode Hex Input" "Vietnamese" "Vietnamese UniKey" "Welsh" ) ;;
		6 ) AllKeyboards=( "Afghan Dari" "Afghan Pashto" "Afghan Uzbek" "Arabic" "Arabic - PC" "Arabic - QWERTY" "Armenian - HM QWERTY" "Armenian - Western QWERTY" "Australian" "Austrian" "Azeri" "Belgian" "Brazilian" "British" "Bulgarian" "Bulgarian - Phonetic" "Byelorussian" "Canadian English" "Canadian French - CSA" "Cherokee - Nation" "Cherokee - QWERTY" "Chinese - Simplified" "Chinese - Traditional" "Croatian" "Croatian - PC" "Czech" "Czech - QWERTY" "Danish" "Devanagari" "Devanagari - QWERTY" "Dutch" "Dvorak" "Dvorak - Left" "Dvorak - Qwerty ⌘" "Dvorak - Right" "Estonian" "Faroese" "Finnish" "Finnish Extended" "Finnish Sami - PC" "French" "French - Numerical" "German" "Greek" "Greek Polytonic" "Gujarati" "Gujarati - QWERTY" "Gurmukhi" "Gurmukhi - QWERTY" "Hangul" "Hawaiian" "Hebrew" "Hebrew - QWERTY" "Hungarian" "Icelandic" "Inuktitut - Nunavut" "Inuktitut - Nutaaq" "Inuktitut - QWERTY" "Inuttitut Nunavik" "Irish" "Irish Extended" "Italian" "Italian - Pro" "Jawi - QWERTY" "Kazakh" "Kotoeri" "Latvian" "Lithuanian" "Macedonian" "Maltese" "Maori" "Nepali" "Northern Sami" "Norwegian" "Norwegian Extended" "Norwegian Sami - PC" "Persian" "Persian - ISIRI 2901" "Persian - QWERTY" "Polish" "Polish Pro" "Portuguese" "Romanian" "Romanian - Standard" "Russian" "Russian - PC" "Russian - Phonetic" "Sami - PC" "Serbian" "Serbian - Latin" "Slovak" "Slovak - QWERTY" "Slovenian" "Spanish" "Spanish - ISO" "Swedish" "Swedish - Pro" "Swedish Sami - PC" "Swiss French" "Swiss German" "Tamil Input Method" "Thai" "Thai - PattaChote" "Tibetan - Otani" "Tibetan - QWERTY" "Tibetan - Wylie" "Turkish" "Turkish - QWERTY" "Turkish - QWERTY PC" "U.S." "U.S. Extended" "U.S. International - PC" "Ukrainian" "Unicode Hex Input" "Uyghur - QWERTY" "Vietnamese" "Vietnamese UniKey" "Welsh" ) ;;
		7 ) AllKeyboards=( "Afghan Dari" "Afghan Pashto" "Afghan Uzbek" "Arabic" "Arabic - PC" "Arabic - QWERTY" "Armenian - HM QWERTY" "Armenian - Western QWERTY" "Australian" "Austrian" "Azeri" "Bangla" "Bangla - Qwerty" "Belgian" "Brazilian" "British" "Bulgarian" "Bulgarian - Phonetic" "Byelorussian" "Canadian English" "Canadian French - CSA" "Cherokee - Nation" "Cherokee - QWERTY" "Chinese - Simplified" "Chinese - Traditional" "Colemak" "Croatian" "Croatian - PC" "Czech" "Czech - QWERTY" "Danish" "Devanagari" "Devanagari - QWERTY" "Dutch" "Dvorak" "Dvorak - Left" "Dvorak - Qwerty ⌘" "Dvorak - Right" "Estonian" "Faroese" "Finnish" "Finnish Extended" "Finnish Sami - PC" "French" "French - Numerical" "German" "Greek" "Greek Polytonic" "Gujarati" "Gujarati - QWERTY" "Gurmukhi" "Gurmukhi - QWERTY" "Hangul" "Hawaiian" "Hebrew" "Hebrew - PC" "Hebrew - QWERTY" "Hungarian" "Icelandic" "Inuktitut - Nunavut" "Inuktitut - Nutaaq" "Inuktitut - QWERTY" "Inuttitut Nunavik" "Irish" "Irish Extended" "Italian" "Italian Typewriter" "Jawi - QWERTY" "Kannada" "Kannada - QWERTY" "Kazakh" "Khmer" "Kotoeri" "Kurdish-Sorani" "Latvian" "Lithuanian" "Macedonian" "Malayalam" "Malayalam - QWERTY" "Maltese" "Maori" "Myanmar - QWERTY" "Nepali" "Northern Sami" "Norwegian" "Norwegian Extended" "Norwegian Sami - PC" "Oriya" "Oriya - QWERTY" "Persian" "Persian - ISIRI 2901" "Persian - QWERTY" "Polish" "Polish Pro" "Portuguese" "Romanian" "Romanian - Standard" "Russian" "Russian - PC" "Russian - Phonetic" "Sami - PC" "Serbian" "Serbian - Latin" "Sinhala" "Sinhala - QWERTY" "Slovak" "Slovak - QWERTY" "Slovenian" "Spanish" "Spanish - ISO" "Swedish" "Swedish - Pro" "Swedish Sami - PC" "Swiss French" "Swiss German" "Tamil Input Method" "Telugu" "Telugu - QWERTY" "Thai" "Thai - PattaChote" "Tibetan - Otani" "Tibetan - QWERTY" "Tibetan - Wylie" "Turkish" "Turkish - QWERTY" "Turkish - QWERTY PC" "U.S." "U.S. Extended" "U.S. International - PC" "Ukrainian" "Unicode Hex Input" "Urdu" "Uyghur - QWERTY" "Vietnamese" "Vietnamese UniKey" "Welsh" ) ;;
		* ) AllKeyboards=( "Afghan Dari" "Afghan Pashto" "Afghan Uzbek" "Arabic" "Arabic - PC" "Arabic - QWERTY" "Armenian - HM QWERTY" "Armenian - Western QWERTY" "Australian" "Austrian" "Azeri" "Bangla" "Bangla - Qwerty" "Belgian" "Brazilian" "British" "British - PC" "Bulgarian" "Bulgarian - Phonetic" "Byelorussian" "Canadian English" "Canadian French - CSA" "Cherokee - Nation" "Cherokee - QWERTY" "Chinese - Simplified" "Chinese - Traditional" "Colemak" "Croatian" "Croatian - PC" "Czech" "Czech - QWERTY" "Danish" "Devanagari" "Devanagari - QWERTY" "Dutch" "Dvorak" "Dvorak - Left" "Dvorak - Qwerty ⌘" "Dvorak - Right" "Estonian" "Faroese" "Finnish" "Finnish Extended" "Finnish Sami - PC" "French" "French - Numerical" "Georgian - QWERTY" "German" "Greek" "Greek Polytonic" "Gujarati" "Gujarati - QWERTY" "Gurmukhi" "Gurmukhi - QWERTY" "Hangul" "Hawaiian" "Hebrew" "Hebrew - PC" "Hebrew - QWERTY" "Hungarian" "Icelandic" "Inuktitut - Nunavut" "Inuktitut - Nutaaq" "Inuktitut - QWERTY" "Inuttitut Nunavik" "Irish" "Irish Extended" "Italian" "Italian Typewriter" "Jawi - QWERTY" "Kannada" "Kannada - QWERTY" "Kazakh" "Khmer" "Kotoeri" "Kurdish-Sorani" "Latvian" "Lithuanian" "Macedonian" "Malayalam" "Malayalam - QWERTY" "Maltese" "Maori" "Myanmar - QWERTY" "Nepali" "Northern Sami" "Norwegian" "Norwegian Extended" "Norwegian Sami - PC" "Oriya" "Oriya - QWERTY" "Persian" "Persian - ISIRI" "Persian - QWERTY" "Polish" "Polish Pro" "Portuguese" "Romanian" "Romanian - Standard" "Russian" "Russian - PC" "Russian - Phonetic" "Sami - PC" "Serbian" "Serbian - Latin" "Sinhala" "Sinhala - QWERTY" "Slovak" "Slovak - QWERTY" "Slovenian" "Spanish" "Spanish - ISO" "Swedish" "Swedish - Pro" "Swedish Sami - PC" "Swiss French" "Swiss German" "Tamil Input Method" "Telugu" "Telugu - QWERTY" "Thai" "Thai - PattaChote" "Tibetan - Otani" "Tibetan - QWERTY" "Tibetan - Wylie" "Turkish" "Turkish - QWERTY" "Turkish - QWERTY PC" "U.S." "U.S. Extended" "U.S. International - PC" "Ukrainian" "Unicode Hex Input" "Urdu" "Uyghur" "Vietnamese" "Vietnamese UniKey" "Welsh" ) ;;
	esac
}

function set_TypingStyles {
	# ${1}: Keyboard
	case "${1}" in
		"Chinese - Simplified" ) TypingStyles=( "Pinyin - Simplified" "Wubi Hua" "Wubi Xing" ) ;;
		"Chinese - Traditional" )
			case ${TargetOSMinor} in
				6 ) TypingStyles=( "Zhuyin" "Cangjie" "Dayi Pro" "Jianyi" "Pinyin - Traditional" ) ;;
				7 ) TypingStyles=( "Zhuyin" "Cangjie" "Jianyi" "Pinyin - Traditional" ) ;;
				* ) TypingStyles=( "Zhuyin" "Cangjie" "Zhuyin - Eten" "Sucheng" "Pinyin - Traditional" ) ;;
			esac ;;
		"Hangul" ) TypingStyles=( "3-Set Korean" "2-Set Korean" "HNC Romaja" "390 Sebulshik" "GongjinCheong Romaja" ) ;;
		"Kotoeri" ) TypingStyles=( "Romaji" "Kana" ) ;;
		"Simplified Chinese" ) TypingStyles=( "ITABC" "Wubi Hua" "Wubi Xing" ) ;;
		"Tamil Input Method" ) TypingStyles=( "Anjal" "Tamil99" ) ;;
		"Traditional Chinese" ) TypingStyles=( "Zhuyin" "Pinyin" "Cangjie" "Jianyi" "Dayi(Pro)" "Hanin" ) ;;
		"Vietnamese UniKey" ) TypingStyles=( "Simple Telex" "VNI" "VIQR" "Telex" ) ;;
		* ) unset TypingStyles[@] ;;
	esac
}

function set_CurrentKeyboards {
	# ${1}: Language Code
	# ${2}: Country Code
	unset DefaultKeyboard
	unset LanguageKeyboards[@]
	unset CountryKeyboards[@]
	if [ ${TargetOSMinor} -lt 8 ] ; then DefaultKeyboard="U.S." ; fi
	case "${1}" in
		"en" ) LanguageKeyboards=( "U.S." ) ;;
		"ja" ) LanguageKeyboards=( "Kotoeri" ) ;;
		"fr" ) LanguageKeyboards=( "French" "French - Numerical" ) ;;
		"de" ) LanguageKeyboards=( "German" ) ;;
		"es" ) LanguageKeyboards=( "Spanish - ISO" "Spanish" ) ;;
		"it" )
			case ${TargetOSMinor} in
				5 | 6 ) LanguageKeyboards=( "Italian - Pro" ) ;;
				* ) LanguageKeyboards=( "Italian" ) ;;
			esac ;;
		"pt" ) LanguageKeyboards=( "Portuguese" "Brazilian" ) ;;
		"pt-PT" )
			case ${TargetOSMinor} in
				6 | 7 | 8 ) LanguageKeyboards=( "Portuguese" "Brazilian" ) ;;
			esac ;;
		"nl" ) LanguageKeyboards=( "Dutch" "Belgian" ) ;;
		"sv" ) LanguageKeyboards=( "Swedish - Pro" ) ;;
		"nb" ) LanguageKeyboards=( "Norwegian" ) ;;
		"da" ) LanguageKeyboards=( "Danish" ) ;;
		"fi" ) LanguageKeyboards=( "Finnish" ) ;;
		"ru" ) LanguageKeyboards=( "Russian" "Russian - Phonetic" ) ;;
		"pl" ) LanguageKeyboards=( "Polish Pro" "Polish" ) ;;
		"zh-Hans" )
			case ${TargetOSMinor} in
				5 ) LanguageKeyboards=( "Simplified Chinese" ) ;;
				* ) LanguageKeyboards=( "Chinese - Simplified" ) ;;
			esac ;;
		"zh-Hant" )
			case ${TargetOSMinor} in
				5 ) LanguageKeyboards=( "Traditional Chinese" ) ;;
				* ) LanguageKeyboards=( "Chinese - Traditional" ) ;;
			esac ;;
		"ko" ) LanguageKeyboards=( "Hangul" ) ;;
		"ar" )
			case ${TargetOSMinor} in
				8 ) LanguageKeyboards=( "Arabic" "Arabic - PC" "Arabic - QWERTY" ) ;;
			esac ;;
		"el" )
			case ${TargetOSMinor} in
				8 ) LanguageKeyboards=( "U.S." "Greek" "Greek Polytonic" ) ;;
			esac ;;
	esac
	case "${2}" in
		"AE" ) CountryKeyboards=( "Arabic" "Arabic - PC" "Arabic - QWERTY" ) ;;
		"AF" ) CountryKeyboards=( "Afghan Pashto" "Afghan Dari" "Afghan Uzbek " ) ;;
		"AM" ) CountryKeyboards=( "Armenian - HM QWERTY" "Armenian - Western QWERTY" ) ;;
		"AT" ) CountryKeyboards=( "Austrian" ) ;;
		"AU" ) CountryKeyboards=( "Australian" ) ;;
		"AZ" ) CountryKeyboards=( "Azeri" ) ;;
		"BE" ) CountryKeyboards=( "Belgian" "French" ) ;;
		"BG" ) CountryKeyboards=( "Bulgarian" "Bulgarian - Phonetic" ) ;;
		"BR" )
			case ${TargetOSMinor} in
				5 ) CountryKeyboards=( "Brazilian" ) ;;
				* ) CountryKeyboards=( "Brazilian" "U.S. International - PC" ) ;;
			esac ;;
		"BY" ) CountryKeyboards=( "Byelorussian" ) ;;
		"CA" ) CountryKeyboards=( "Canadian English" "Canadian French - CSA" ) ;;
		"CN" )
			case ${TargetOSMinor} in
				5 ) CountryKeyboards=( "Simplified Chinese" ) ;;
				* ) CountryKeyboards=( "Chinese - Simplified" ) ;;
			esac ;;
		"CY" )
			case ${TargetOSMinor} in
				8 ) CountryKeyboards=( "U.S." "Greek" "Greek Polytonic" ) ;;
			esac ;;
		"CZ" ) CountryKeyboards=( "Czech - QWERTY" "Czech" ) ;;
		"DE" ) CountryKeyboards=( "German" ) ;;
		"DK" ) CountryKeyboards=( "Danish" ) ;;
		"EE" ) CountryKeyboards=( "Estonian" ) ;;
		"EG" ) CountryKeyboards=( "Arabic" "Arabic - PC" "Arabic - QWERTY" ) ;;
		"ES" ) CountryKeyboards=( "Spanish - ISO" "Spanish" ) ;;
		"FI" ) CountryKeyboards=( "Finnish" ) ;;
		"FO" ) CountryKeyboards=( "Faroese" ) ;;
		"FR" ) CountryKeyboards=( "French" "French - Numerical" ) ;;
		"GB" ) CountryKeyboards=( "British" ) ;;
		"GR" ) CountryKeyboards=( "U.S." "Greek" "Greek Polytonic" ) ;;
		"HR" ) CountryKeyboards=( "Croatian" ) ;;
		"HU" ) CountryKeyboards=( "Hungarian" ) ;;
		"IE" ) CountryKeyboards=( "British" "Irish" ) ;;
		"IL" ) CountryKeyboards=( "Hebrew" "Hebrew - QWERTY" ) ;;
		"IN" ) CountryKeyboards=( "Devanagari" "Devanagari - QWERTY" "Gurmukhi" "Gurmukhi -QWERTY" "Gujarati" "Gujarati - QWERTY" ) ;;
		"IS" ) CountryKeyboards=( "Icelandic" ) ;;
		"IT" )
			case ${TargetOSMinor} in
				5 | 6 ) CountryKeyboards=( "Italian - Pro" ) ;;
				* ) CountryKeyboards=( "Italian" ) ;;
			esac ;;
		"JP" ) CountryKeyboards=( "Kotoeri" ) ;;
		"KR" ) CountryKeyboards=( "Hangul" ) ;;
		"KZ" ) CountryKeyboards=( "Kazakh" ) ;;
		"LB" ) CountryKeyboards=( "Arabic" "Arabic - PC" "Arabic - QWERTY" ) ;;
		"LT" ) CountryKeyboards=( "Lithuanian" ) ;;
		"LV" ) CountryKeyboards=( "Latvian" ) ;;
		"MK" ) CountryKeyboards=( "Macedonian" ) ;;
		"MT" ) CountryKeyboards=( "Maltese" ) ;;
		"NL" ) CountryKeyboards=( "Dutch" ) ;;
		"NO" ) CountryKeyboards=( "Norwegian" ) ;;
		"NP" ) CountryKeyboards=( "Nepali" ) ;;
		"NZ" ) CountryKeyboards=( "Australian" ) ;;
		"PL" ) CountryKeyboards=( "Polish Pro" "Polish" ) ;;
		"PT" ) CountryKeyboards=( "Portuguese" "Brazilian" ) ;;
		"RO" ) CountryKeyboards=( "Romanian - Standard" "Romanian" ) ;;
		"RS" ) CountryKeyboards=( "Serbian" "Serbian - Latin" ) ;;
		"RU" ) CountryKeyboards=( "Russian" "Russian - Phonetic" ) ;;
		"SA" ) CountryKeyboards=( "Arabic" "Arabic - PC" "Arabic - QWERTY" ) ;;
		"SE" ) CountryKeyboards=( "Swedish - Pro" ) ;;
		"SG" )
			case ${TargetOSMinor} in
				5 ) CountryKeyboards=( "Simplified Chinese" ) ;;
				* ) CountryKeyboards=( "Chinese - Simplified" ) ;;
			esac ;;
		"SI" ) CountryKeyboards=( "Slovenian" ) ;;
		"SK" ) CountryKeyboards=( "Slovak" "Slovak - QWERTY" ) ;;
		"TH" ) CountryKeyboards=( "Thai" "Thai - PattaChote" ) ;;
		"TR" ) CountryKeyboards=( "Turkish" "Turkish - QWERTY" "Turkish - QWERTY PC" ) ;;
		"TW" )
			case ${TargetOSMinor} in
				5 ) CountryKeyboards=( "Traditional Chinese" ) ;;
				* ) CountryKeyboards=( "Chinese - Traditional" ) ;;
			esac ;;
		"UA" )
			case ${TargetOSMinor} in
				5 | 6 ) CountryKeyboards=( "Ukrainian" ) ;;
				* ) CountryKeyboards=( "Ukrainian" "Russian" "Russian - Phonetic" ) ;;
			esac ;;
		"US" ) CountryKeyboards=( "U.S." "Canadian English" ) ;;
		"VN" ) CountryKeyboards=( "Vietnamese" ) ;;
	esac
	case "${1}-${2}" in
		"en-US" ) unset LanguageKeyboards[@] ;;
		"en-CA" ) unset LanguageKeyboards[@] ;;
		"en-GB" ) unset LanguageKeyboards[@] ;;
		"en-AU" ) unset LanguageKeyboards[@] ;;
		"en-NZ" ) unset LanguageKeyboards[@] ;;
		"en-IE" ) unset LanguageKeyboards[@] ;;
		"fr-BE" ) unset LanguageKeyboards[@] ;;
		"fr-CA" ) unset LanguageKeyboards[@] ;;
		"fr-CH" ) unset LanguageKeyboards[@] ; CountryKeyboards=( "Swiss French" ) ;;
		"de-AT" ) unset LanguageKeyboards[@] ;;
		"de-CH" ) unset LanguageKeyboards[@] ; CountryKeyboards=( "Swiss German" ) ;;
		"pt-BR" ) unset LanguageKeyboards[@] ;;
		"nl-BE" ) unset LanguageKeyboards[@] ;;
		"nl-NL" ) unset LanguageKeyboards[@] ;;
		"ru-BY" ) unset LanguageKeyboards[@] ;;
		"ru-EE" ) unset LanguageKeyboards[@] ;;
		"ru-KZ" ) unset LanguageKeyboards[@] ;;
		"ru-LV" ) unset LanguageKeyboards[@] ;;
		"ru-UA" ) unset LanguageKeyboards[@] ;;
	esac
	case ${TargetOSMinor} in
		5 )
			case "${1}-${2}" in
				"fr-LU" ) unset LanguageKeyboards[@] ;;
				"de-LU" ) unset LanguageKeyboards[@] ;;
				"ru-KG" ) unset LanguageKeyboards[@] ;;
				"ru-SJ" ) unset LanguageKeyboards[@] ;;
				"ru-TJ" ) unset LanguageKeyboards[@] ;;
				"ru-UZ" ) unset LanguageKeyboards[@] ;;
			esac ;;
		7 | 8 )
			case "${1}-${2}" in
				"ru-LT" ) unset LanguageKeyboards[@] ;;
			esac ;;
	esac
	if [ ${TargetOSMinor} -gt 5 ] ; then
		if [ "${1}" == "pt-PT" ] ; then unset CountryKeyboards[@] ; fi
		if [ "${1}" == "zh-Hans" ] || [ "${1}" == "zh-Hant" ] ; then
			if [ ${#CountryKeyboards[@]} -gt 0 ] ; then unset LanguageKeyboards[@] ; fi
		fi
	fi
	i=0 ; for LanguageKeyboard in "${LanguageKeyboards[@]}" ; do
		if [ "${LanguageKeyboard}" == "${DefaultKeyboard}" ] ; then unset LanguageKeyboards[i] ; break ; fi
		let i++
	done
	i=0 ; for CountryKeyboard in "${CountryKeyboards[@]}" ; do
		if [ "${CountryKeyboard}" == "${DefaultKeyboard}" ] ; then unset CountryKeyboards[i] ; break ; fi
		let i++
	done
	i=0 ; for CountryKeyboard in "${CountryKeyboards[@]}" ; do
		for LanguageKeyboard in "${LanguageKeyboards[@]}" ; do
			if [ "${LanguageKeyboard}" == "${CountryKeyboard}" ] ; then unset CountryKeyboards[i] ; fi
		done
		let i++
	done
	if [ -n "${DefaultKeyboard}" ] ; then
		CurrentKeyboards=( "${DefaultKeyboard}" "${LanguageKeyboards[@]}" "${CountryKeyboards[@]}" )
	else
		CurrentKeyboards=( "${LanguageKeyboards[@]}" "${CountryKeyboards[@]}" )
	fi
	i=0 ; for CurrentKeyboard in "${CurrentKeyboards[@]}" ; do
		if [ "${CurrentKeyboard}" == "U.S." ] ; then unset CurrentKeyboards[i] ; CurrentKeyboards=( "U.S." "${CurrentKeyboards[@]}" ) ; break ; fi
		let i++
	done
}

function set_OtherKeyboards {
	unset OtherKeyboards[@]
	for Keyboard in "${AllKeyboards[@]}" ; do
		j=0 ; for CurrentKeyboard in "${CurrentKeyboards[@]}" ; do
			if [ "${Keyboard}" == "${CurrentKeyboard}" ] ; then j=1 ; break ; fi
		done
		if [ ${j} -eq 0 ] ; then OtherKeyboards=( "${OtherKeyboards[@]}" "${Keyboard}" ) ; fi
	done
}

function set_Bundle_IDs {
	# ${1}: Typing Style
	unset Bundle_IDs[@]
	case "${1}" in
		"2-Set Korean" ) Bundle_IDs[1]="com.apple.inputmethod.Korean" ; Bundle_IDs[2]="com.apple.inputmethod.Korean" ; Bundle_IDs[3]="com.apple.inputmethod.Korean" ; Bundle_IDs[4]="com.apple.inputmethod.Korean" ; Bundle_IDs[5]="com.apple.inputmethod.Korean" ; Bundle_IDs[6]="com.apple.inputmethod.Korean" ;;
		"3-Set Korean" ) Bundle_IDs[1]="com.apple.inputmethod.Korean" ; Bundle_IDs[2]="com.apple.inputmethod.Korean" ; Bundle_IDs[3]="com.apple.inputmethod.Korean" ; Bundle_IDs[4]="com.apple.inputmethod.Korean" ; Bundle_IDs[5]="com.apple.inputmethod.Korean" ; Bundle_IDs[6]="com.apple.inputmethod.Korean" ;;
		"390 Sebulshik" ) Bundle_IDs[1]="com.apple.inputmethod.Korean" ; Bundle_IDs[2]="com.apple.inputmethod.Korean" ; Bundle_IDs[3]="com.apple.inputmethod.Korean" ; Bundle_IDs[4]="com.apple.inputmethod.Korean" ; Bundle_IDs[5]="com.apple.inputmethod.Korean" ; Bundle_IDs[6]="com.apple.inputmethod.Korean" ;;
		"GongjinCheong Romaja" ) Bundle_IDs[1]="com.apple.inputmethod.Korean" ; Bundle_IDs[2]="com.apple.inputmethod.Korean" ; Bundle_IDs[3]="com.apple.inputmethod.Korean" ; Bundle_IDs[4]="com.apple.inputmethod.Korean" ; Bundle_IDs[5]="com.apple.inputmethod.Korean" ; Bundle_IDs[6]="com.apple.inputmethod.Korean" ;;
		"HNC Romaja" ) Bundle_IDs[1]="com.apple.inputmethod.Korean" ; Bundle_IDs[2]="com.apple.inputmethod.Korean" ; Bundle_IDs[3]="com.apple.inputmethod.Korean" ; Bundle_IDs[4]="com.apple.inputmethod.Korean" ; Bundle_IDs[5]="com.apple.inputmethod.Korean" ; Bundle_IDs[6]="com.apple.inputmethod.Korean" ;;
		"Kana" )
			case ${TargetOSMinor} in
				5 ) Bundle_IDs[0]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[1]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[2]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[3]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[4]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[5]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[6]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[7]="com.apple.CharacterPaletteIM" ; Bundle_IDs[8]="com.apple.50onPaletteIM" ;;
				* ) Bundle_IDs[0]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[1]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[2]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[3]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[4]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[5]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[6]="com.apple.inputmethod.Kotoeri" ;;
			esac ;;
		"Romaji" )
			case ${TargetOSMinor} in
				5 ) Bundle_IDs[0]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[1]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[2]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[3]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[4]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[5]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[6]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[7]="com.apple.CharacterPaletteIM" ; Bundle_IDs[8]="com.apple.50onPaletteIM" ;;
				* ) Bundle_IDs[0]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[1]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[2]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[3]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[4]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[5]="com.apple.inputmethod.Kotoeri" ; Bundle_IDs[6]="com.apple.inputmethod.Kotoeri" ;;
			esac ;;
		"ITABC" ) Bundle_IDs[1]="com.apple.inputmethod.SCIM" ; Bundle_IDs[2]="com.apple.inputmethod.SCIM" ; Bundle_IDs[3]="com.apple.inputmethod.SCIM" ; Bundle_IDs[4]="com.apple.inputmethod.SCIM" ;;
		"Pinyin - Simplified" ) Bundle_IDs[1]="com.apple.inputmethod.SCIM" ; Bundle_IDs[2]="com.apple.inputmethod.SCIM" ; Bundle_IDs[3]="com.apple.inputmethod.SCIM" ; Bundle_IDs[4]="com.apple.inputmethod.SCIM" ; Bundle_IDs[5]="com.apple.inputmethod.ChineseHandwriting" ;;
		"Wubi Hua" )
			case ${TargetOSMinor} in
				5 ) Bundle_IDs[1]="com.apple.inputmethod.SCIM" ; Bundle_IDs[2]="com.apple.inputmethod.SCIM" ; Bundle_IDs[3]="com.apple.inputmethod.SCIM" ; Bundle_IDs[4]="com.apple.inputmethod.SCIM" ;;
				* ) Bundle_IDs[1]="com.apple.inputmethod.SCIM" ; Bundle_IDs[2]="com.apple.inputmethod.SCIM" ; Bundle_IDs[3]="com.apple.inputmethod.SCIM" ; Bundle_IDs[4]="com.apple.inputmethod.SCIM" ; Bundle_IDs[5]="com.apple.inputmethod.ChineseHandwriting" ;;
			esac ;;
		"Wubi Xing" )
			case ${TargetOSMinor} in
				5 ) Bundle_IDs[1]="com.apple.inputmethod.SCIM" ; Bundle_IDs[2]="com.apple.inputmethod.SCIM" ; Bundle_IDs[3]="com.apple.inputmethod.SCIM" ; Bundle_IDs[4]="com.apple.inputmethod.SCIM" ;;
				* ) Bundle_IDs[1]="com.apple.inputmethod.SCIM" ; Bundle_IDs[2]="com.apple.inputmethod.SCIM" ; Bundle_IDs[3]="com.apple.inputmethod.SCIM" ; Bundle_IDs[4]="com.apple.inputmethod.SCIM" ; Bundle_IDs[5]="com.apple.inputmethod.ChineseHandwriting" ;;
			esac ;;
		"Anjal" ) Bundle_IDs[1]="com.apple.inputmethod.Tamil" ; Bundle_IDs[2]="com.apple.inputmethod.Tamil" ; Bundle_IDs[3]="com.apple.inputmethod.Tamil" ;;
		"Tamil99" ) Bundle_IDs[1]="com.apple.inputmethod.Tamil" ; Bundle_IDs[2]="com.apple.inputmethod.Tamil" ; Bundle_IDs[3]="com.apple.inputmethod.Tamil" ;;
		"Cangjie" )
			case ${TargetOSMinor} in
				5 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ;;
				6 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
				7 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.ChineseHandwriting" ;;
				8 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
			esac ;;
		"Dayi Pro" ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
		"Dayi(Pro)" ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ;;
		"Hanin" ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.TCIM" ;;
		"Jianyi" )
			case ${TargetOSMinor} in
				5 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ;;
				6 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
				7 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.ChineseHandwriting" ;;
			esac ;;
		"Pinyin" ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ;;
		"Pinyin - Traditional" )
			case ${TargetOSMinor} in
				6 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
				7 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.ChineseHandwriting" ;;
				8 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
			esac ;;
		"Sucheng" ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
		"Zhuyin" )
			case ${TargetOSMinor} in
				5 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ;;
				6 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
				7 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.ChineseHandwriting" ;;
				8 ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
			esac ;;
		"Zhuyin - Eten" ) Bundle_IDs[1]="com.apple.inputmethod.TCIM" ; Bundle_IDs[2]="com.apple.inputmethod.TCIM" ; Bundle_IDs[3]="com.apple.inputmethod.TCIM" ; Bundle_IDs[4]="com.apple.inputmethod.TCIM" ; Bundle_IDs[5]="com.apple.inputmethod.TCIM" ; Bundle_IDs[6]="com.apple.inputmethod.TCIM" ; Bundle_IDs[7]="com.apple.inputmethod.ChineseHandwriting" ;;
		"Simple Telex" ) Bundle_IDs[0]="com.apple.inputmethod.VietnameseIM" ; Bundle_IDs[1]="com.apple.inputmethod.VietnameseIM" ;;
		"Telex" ) Bundle_IDs[0]="com.apple.inputmethod.VietnameseIM" ; Bundle_IDs[1]="com.apple.inputmethod.VietnameseIM" ; Bundle_IDs[2]="com.apple.inputmethod.VietnameseIM" ;;
		"VIQR" ) Bundle_IDs[0]="com.apple.inputmethod.VietnameseIM" ; Bundle_IDs[1]="com.apple.inputmethod.VietnameseIM" ; Bundle_IDs[2]="com.apple.inputmethod.VietnameseIM" ;;
		"VNI" ) Bundle_IDs[0]="com.apple.inputmethod.VietnameseIM" ; Bundle_IDs[1]="com.apple.inputmethod.VietnameseIM" ; Bundle_IDs[2]="com.apple.inputmethod.VietnameseIM" ;;
	esac
}

function set_Input_Modes {
	# ${1}: Typing Style
	unset Input_Modes[@]
	case "${1}" in
		"2-Set Korean" ) Input_Modes[1]="com.apple.inputmethod.Korean.3SetKorean" ; Input_Modes[2]="com.apple.inputmethod.Korean.2SetKorean" ; Input_Modes[3]="com.apple.inputmethod.Korean.HNCRomaja" ; Input_Modes[4]="com.apple.inputmethod.Korean.390Sebulshik" ; Input_Modes[5]="com.apple.inputmethod.Korean.GongjinCheongRomaja" ;;
		"3-Set Korean" ) Input_Modes[1]="com.apple.inputmethod.Korean.3SetKorean" ; Input_Modes[2]="com.apple.inputmethod.Korean.2SetKorean" ; Input_Modes[3]="com.apple.inputmethod.Korean.HNCRomaja" ; Input_Modes[4]="com.apple.inputmethod.Korean.390Sebulshik" ; Input_Modes[5]="com.apple.inputmethod.Korean.GongjinCheongRomaja" ;;
		"390 Sebulshik" ) Input_Modes[1]="com.apple.inputmethod.Korean.3SetKorean" ; Input_Modes[2]="com.apple.inputmethod.Korean.2SetKorean" ; Input_Modes[3]="com.apple.inputmethod.Korean.HNCRomaja" ; Input_Modes[4]="com.apple.inputmethod.Korean.390Sebulshik" ; Input_Modes[5]="com.apple.inputmethod.Korean.GongjinCheongRomaja" ;;
		"GongjinCheong Romaja" ) Input_Modes[1]="com.apple.inputmethod.Korean.3SetKorean" ; Input_Modes[2]="com.apple.inputmethod.Korean.2SetKorean" ; Input_Modes[3]="com.apple.inputmethod.Korean.HNCRomaja" ; Input_Modes[4]="com.apple.inputmethod.Korean.390Sebulshik" ; Input_Modes[5]="com.apple.inputmethod.Korean.GongjinCheongRomaja" ;;
		"HNC Romaja" ) Input_Modes[1]="com.apple.inputmethod.Korean.3SetKorean" ; Input_Modes[2]="com.apple.inputmethod.Korean.2SetKorean" ; Input_Modes[3]="com.apple.inputmethod.Korean.HNCRomaja" ; Input_Modes[4]="com.apple.inputmethod.Korean.390Sebulshik" ; Input_Modes[5]="com.apple.inputmethod.Korean.GongjinCheongRomaja" ;;
		"Kana" ) Input_Modes[0]="com.apple.inputmethod.Japanese" ; Input_Modes[1]="com.apple.inputmethod.Japanese.placename" ; Input_Modes[2]="com.apple.inputmethod.Roman" ; Input_Modes[3]="com.apple.inputmethod.Japanese.Katakana" ; Input_Modes[4]="com.apple.inputmethod.Japanese.firstname" ; Input_Modes[5]="com.apple.inputmethod.Japanese.lastname" ;;
		"Romaji" ) Input_Modes[0]="com.apple.inputmethod.Japanese" ; Input_Modes[1]="com.apple.inputmethod.Japanese.placename" ; Input_Modes[2]="com.apple.inputmethod.Roman" ; Input_Modes[3]="com.apple.inputmethod.Japanese.Katakana" ; Input_Modes[4]="com.apple.inputmethod.Japanese.firstname" ; Input_Modes[5]="com.apple.inputmethod.Japanese.lastname" ;;
		"ITABC" ) Input_Modes[1]="com.apple.inputmethod.SCIM.ITABC" ; Input_Modes[2]="com.apple.inputmethod.SCIM.WBX" ; Input_Modes[3]="com.apple.inputmethod.SCIM.WBH" ;;
		"Pinyin - Simplified" ) Input_Modes[1]="com.apple.inputmethod.SCIM.ITABC" ; Input_Modes[2]="com.apple.inputmethod.SCIM.WBH" ; Input_Modes[3]="com.apple.inputmethod.SCIM.WBX" ;;
		"Wubi Hua" )
			case ${TargetOSMinor} in
				5 ) Input_Modes[1]="com.apple.inputmethod.SCIM.ITABC" ; Input_Modes[2]="com.apple.inputmethod.SCIM.WBX" ; Input_Modes[3]="com.apple.inputmethod.SCIM.WBH" ;;
				* ) Input_Modes[1]="com.apple.inputmethod.SCIM.ITABC" ; Input_Modes[2]="com.apple.inputmethod.SCIM.WBH" ; Input_Modes[3]="com.apple.inputmethod.SCIM.WBX" ;;
			esac ;;
		"Wubi Xing" )
			case ${TargetOSMinor} in
				5 ) Input_Modes[1]="com.apple.inputmethod.SCIM.ITABC" ; Input_Modes[2]="com.apple.inputmethod.SCIM.WBX" ; Input_Modes[3]="com.apple.inputmethod.SCIM.WBH" ;;
				* ) Input_Modes[1]="com.apple.inputmethod.SCIM.ITABC" ; Input_Modes[2]="com.apple.inputmethod.SCIM.WBH" ; Input_Modes[3]="com.apple.inputmethod.SCIM.WBX" ;;
			esac ;;
		"Anjal" )
			case ${TargetOSMinor} in
				5 ) Input_Modes[1]="com.apple.inputmethod.Tamil.Tamil99" ; Input_Modes[2]="com.apple.inputmethod.Tamil.AnjalIM" ;;
				* ) Input_Modes[1]="com.apple.inputmethod.Tamil.AnjalIM" ; Input_Modes[2]="com.apple.inputmethod.Tamil.Tamil99" ;;
			esac ;;
		"Tamil99" )
			case ${TargetOSMinor} in
				5 ) Input_Modes[1]="com.apple.inputmethod.Tamil.Tamil99" ; Input_Modes[2]="com.apple.inputmethod.Tamil.AnjalIM" ;;
				* ) Input_Modes[1]="com.apple.inputmethod.Tamil.AnjalIM" ; Input_Modes[2]="com.apple.inputmethod.Tamil.Tamil99" ;;
			esac ;;
		"Cangjie" )
			case ${TargetOSMinor} in
				5 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Cangjie" ;;
				6 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
				7 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ;;
				8 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.ZhuyinEten" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
			esac ;;
		"Dayi Pro" ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
		"Dayi(Pro)" ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Cangjie" ;;
		"Hanin" ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[7]="com.apple.inputmethod.TCIM.Hanin" ;;
		"Jianyi" )
			case ${TargetOSMinor} in
				5 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Cangjie" ;;
				6 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
				7 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ;;
			esac ;;
		"Pinyin" ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Cangjie" ;;
		"Pinyin - Traditional" )
			case ${TargetOSMinor} in
				6 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
				7 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ;;
				8 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.ZhuyinEten" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
			esac ;;
		"Sucheng" ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.ZhuyinEten" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
		"Zhuyin" )
			case ${TargetOSMinor} in
				5 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Cangjie" ;;
				6 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Dayi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
				7 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Pinyin" ;;
				8 ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.ZhuyinEten" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
			esac ;;
		"Zhuyin - Eten" ) Input_Modes[1]="com.apple.inputmethod.TCIM.Zhuyin" ; Input_Modes[2]="com.apple.inputmethod.TCIM.Cangjie" ; Input_Modes[3]="com.apple.inputmethod.TCIM.ZhuyinEten" ; Input_Modes[4]="com.apple.inputmethod.TCIM.Jianyi" ; Input_Modes[5]="com.apple.inputmethod.TCIM.Pinyin" ;;
		"Simple Telex" ) Input_Modes[0]="com.apple.inputmethod.VietnameseSimpleTelex" ;;
		"Telex" ) Input_Modes[0]="com.apple.inputmethod.VietnameseSimpleTelex" ; Input_Modes[2]="com.apple.inputmethod.VietnameseTelex" ;;
		"VIQR" ) Input_Modes[0]="com.apple.inputmethod.VietnameseSimpleTelex" ; Input_Modes[2]="com.apple.inputmethod.VietnameseVIQR" ;;
		"VNI" ) Input_Modes[0]="com.apple.inputmethod.VietnameseSimpleTelex" ; Input_Modes[2]="com.apple.inputmethod.VietnameseVNI" ;;
	esac
}

function set_InputSourceKinds {
	# ${1}: Keyboard or Typing Style
	unset InputSourceKinds[@]
	case "${1}" in
		"Afghan Dari" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Afghan Pashto" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Afghan Uzbek" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Arabic" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Arabic - PC" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Arabic - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Armenian - HM QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Armenian - Western QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Azeri" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Bangla" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Bangla - Qwerty" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Bulgarian" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Bulgarian - Phonetic" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Byelorussian" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Cherokee - Nation" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Cherokee - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Devanagari" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Devanagari - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Georgian - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Greek" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Greek Polytonic" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Gujarati" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Gujarati - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Gurmukhi" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Gurmukhi - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"2-Set Korean" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
		"3-Set Korean" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
		"390 Sebulshik" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
		"GongjinCheong Romaja" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
		"HNC Romaja" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
		"Hebrew" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Hebrew - PC" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Hebrew - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Jawi - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Kannada" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Kannada - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Kazakh" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Khmer" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Kana" )
			case ${TargetOSMinor} in
				5 ) InputSourceKinds[0]="Input Mode" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ; InputSourceKinds[8]="Non Keyboard Input Method" ;;
				* ) InputSourceKinds[0]="Input Mode" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
			esac ;;
		"Romaji" )
			case ${TargetOSMinor} in
				5 ) InputSourceKinds[0]="Input Mode" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ; InputSourceKinds[8]="Non Keyboard Input Method" ;;
				* ) InputSourceKinds[0]="Input Mode" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
			esac ;;
		"Kurdish-Sorani" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Macedonian" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Malayalam" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Malayalam - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Myanmar - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Nepali" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Oriya" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Oriya - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Persian" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Persian - ISIRI" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Persian - ISIRI 2901" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Persian - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Russian" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Russian - PC" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Russian - Phonetic" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Serbian" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"ITABC" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Keyboard Input Method" ;;
		"Pinyin - Simplified" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Keyboard Input Method" ; InputSourceKinds[5]="Non Keyboard Input Method" ;;
		"Wubi Hua" )
			case ${TargetOSMinor} in
				5 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Keyboard Input Method" ;;
				* ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Keyboard Input Method" ; InputSourceKinds[5]="Non Keyboard Input Method" ;;
			esac ;;
		"Wubi Xing" )
			case ${TargetOSMinor} in
				5 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Keyboard Input Method" ;;
				* ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Keyboard Input Method" ; InputSourceKinds[5]="Non Keyboard Input Method" ;;
			esac ;;
		"Sinhala" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Sinhala - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Anjal" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Keyboard Input Method" ;;
		"Tamil99" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Keyboard Input Method" ;;
		"Telugu" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Telugu - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Thai" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Thai - PattaChote" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Tibetan - Otani" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Tibetan - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Tibetan - Wylie" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Cangjie" )
			case ${TargetOSMinor} in
				5 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
				6 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
				7 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Keyboard Input Method" ; InputSourceKinds[6]="Non Keyboard Input Method" ;;
				8 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
			esac ;;
		"Dayi Pro" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
		"Dayi(Pro)" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
		"Hanin" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Input Mode" ;;
		"Jianyi" )
			case ${TargetOSMinor} in
				5 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
				6 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
				7 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Keyboard Input Method" ; InputSourceKinds[6]="Non Keyboard Input Method" ;;
			esac ;;
		"Pinyin" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
		"Pinyin - Traditional" )
			case ${TargetOSMinor} in
				6 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
				7 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Keyboard Input Method" ; InputSourceKinds[6]="Non Keyboard Input Method" ;;
				8 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
			esac ;;
		"Sucheng" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
		"Zhuyin" )
			case ${TargetOSMinor} in
				5 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ;;
				6 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
				7 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Keyboard Input Method" ; InputSourceKinds[6]="Non Keyboard Input Method" ;;
				8 ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
			esac ;;
		"Zhuyin - Eten" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Input Mode" ; InputSourceKinds[2]="Input Mode" ; InputSourceKinds[3]="Input Mode" ; InputSourceKinds[4]="Input Mode" ; InputSourceKinds[5]="Input Mode" ; InputSourceKinds[6]="Keyboard Input Method" ; InputSourceKinds[7]="Non Keyboard Input Method" ;;
		"Uighur - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Ukrainian" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Urdu" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Uyghur" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Uyghur - QWERTY" ) InputSourceKinds[0]="Keyboard Layout" ; InputSourceKinds[1]="Keyboard Layout" ;;
		"Simple Telex" ) InputSourceKinds[0]="Input Mode" ; InputSourceKinds[1]="Keyboard Input Method" ;;
		"Telex" ) InputSourceKinds[0]="Input Mode" ; InputSourceKinds[1]="Keyboard Input Method" ; InputSourceKinds[2]="Input Mode" ;;
		"VIQR" ) InputSourceKinds[0]="Input Mode" ; InputSourceKinds[1]="Keyboard Input Method" ; InputSourceKinds[2]="Input Mode" ;;
		"VNI" ) InputSourceKinds[0]="Input Mode" ; InputSourceKinds[1]="Keyboard Input Method" ; InputSourceKinds[2]="Input Mode" ;;
		* ) InputSourceKinds[0]="Keyboard Layout" ;;
	esac
}

function set_KeyboardLayout_IDs {
	# ${1}: Keyboard or Typing Style
	unset KeyboardLayout_IDs[@]
	case "${1}" in
		"Afghan Dari" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-2902 ;;
		"Afghan Pashto" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-2904 ;;
		"Afghan Uzbek" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-2903 ;;
		"Arabic" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-17920 ;;
		"Arabic - PC" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-17921 ;;
		"Arabic - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-18000 ;;
		"Armenian - HM QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-28161 ;;
		"Armenian - Western QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-28164 ;;
		"Australian" ) KeyboardLayout_IDs[0]=15 ;;
		"Austrian" ) KeyboardLayout_IDs[0]=92 ;;
		"Azeri" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-49 ;;
		"Bangla" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-22528 ;;
		"Bangla - Qwerty" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-22529 ;;
		"Belgian" ) KeyboardLayout_IDs[0]=6 ;;
		"Brazilian" ) KeyboardLayout_IDs[0]=71 ;;
		"British" ) KeyboardLayout_IDs[0]=2 ;;
		"British - PC" ) KeyboardLayout_IDs[0]=250 ;;
		"Bulgarian" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19528 ;;
		"Bulgarian - Phonetic" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19529 ;;
		"Byelorussian" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19517 ;;
		"Canadian English" ) KeyboardLayout_IDs[0]=29 ;;
		"Canadian French - CSA" ) KeyboardLayout_IDs[0]=80 ;;
		"Cherokee - Nation" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-26112 ;;
		"Cherokee - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-26113 ;;
		"Colemak" ) KeyboardLayout_IDs[0]=12825 ;;
		"Croatian" ) KeyboardLayout_IDs[0]=-68 ;;
		"Croatian - PC" ) KeyboardLayout_IDs[0]=-69 ;;
		"Czech" ) KeyboardLayout_IDs[0]=30776 ;;
		"Czech - QWERTY" ) KeyboardLayout_IDs[0]=30778 ;;
		"Danish" ) KeyboardLayout_IDs[0]=9 ;;
		"Devanagari" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-20480 ;;
		"Devanagari - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-20481 ;;
		"Dutch" ) KeyboardLayout_IDs[0]=26 ;;
		"Dvorak" ) KeyboardLayout_IDs[0]=16300 ;;
		"Dvorak - Left" ) KeyboardLayout_IDs[0]=16302 ;;
		"Dvorak - Qwerty" ) KeyboardLayout_IDs[0]=16301 ;;
		"Dvorak - Qwerty  " ) KeyboardLayout_IDs[0]=16301 ;;
		"Dvorak - Right" ) KeyboardLayout_IDs[0]=16303 ;;
		"Estonian" ) KeyboardLayout_IDs[0]=30764 ;;
		"Faroese" ) KeyboardLayout_IDs[0]=-47 ;;
		"Finnish" ) KeyboardLayout_IDs[0]=17 ;;
		"Finnish Extended" ) KeyboardLayout_IDs[0]=-17 ;;
		"Finnish Sami - PC" ) KeyboardLayout_IDs[0]=-18 ;;
		"French" ) KeyboardLayout_IDs[0]=1 ;;
		"French - Numerical" ) KeyboardLayout_IDs[0]=1111 ;;
		"Georgian - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-27650 ;;
		"German" ) KeyboardLayout_IDs[0]=3 ;;
		"Greek" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-18944 ;;
		"Greek Polytonic" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-18945 ;;
		"Gujarati" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-21504 ;;
		"Gujarati - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-21505 ;;
		"Gurmukhi" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-20992 ;;
		"Gurmukhi - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-20993 ;;
		"Hawaiian" ) KeyboardLayout_IDs[0]=-50 ;;
		"Hebrew" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-18432 ;;
		"Hebrew - PC" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-18433 ;;
		"Hebrew - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-18500 ;;
		"Hungarian" ) KeyboardLayout_IDs[0]=30763 ;;
		"Icelandic" ) KeyboardLayout_IDs[0]=-21 ;;
		"Inuktitut - Nunavut" ) KeyboardLayout_IDs[0]=-30604 ;;
		"Inuktitut - Nutaaq" ) KeyboardLayout_IDs[0]=-30602 ;;
		"Inuktitut - QWERTY" ) KeyboardLayout_IDs[0]=-30600 ;;
		"Inuttitut Nunavik" ) KeyboardLayout_IDs[0]=-30603 ;;
		"Irish" ) KeyboardLayout_IDs[0]=50 ;;
		"Irish Extended" ) KeyboardLayout_IDs[0]=-500 ;;
		"Italian" )
			case ${TargetOSMinor} in
				5 | 6 ) KeyboardLayout_IDs[0]=4 ;;
				7 | 8 ) KeyboardLayout_IDs[0]=223 ;;
			esac ;;
		"Italian - Pro" ) KeyboardLayout_IDs[0]=223 ;;
		"Italian Typewriter" ) KeyboardLayout_IDs[0]=4 ;;
		"Jawi - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-19000 ;;
		"Kannada" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-24064 ;;
		"Kannada - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-24065 ;;
		"Kazakh" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-19501 ;;
		"Khmer" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-26114 ;;
		"Kurdish-Sorani" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-17926 ;;
		"Latvian" ) KeyboardLayout_IDs[0]=30765 ;;
		"Lithuanian" ) KeyboardLayout_IDs[0]=30761 ;;
		"Macedonian" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19523 ;;
		"Malayalam" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-24576 ;;
		"Malayalam - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-24577 ;;
		"Maltese" ) KeyboardLayout_IDs[0]=-501 ;;
		"Maori" ) KeyboardLayout_IDs[0]=-51 ;;
		"Myanmar - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-25601 ;;
		"Nepali" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-20484 ;;
		"Northern Sami" ) KeyboardLayout_IDs[0]=-1200 ;;
		"Norwegian" ) KeyboardLayout_IDs[0]=12 ;;
		"Norwegian Extended" ) KeyboardLayout_IDs[0]=-12 ;;
		"Norwegian Sami - PC" ) KeyboardLayout_IDs[0]=-13 ;;
		"Oriya" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-22016 ;;
		"Oriya - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-22017 ;;
		"Persian" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-17960 ;;
		"Persian - ISIRI" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-2901 ;;
		"Persian - ISIRI 2901" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-2901 ;;
		"Persian - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-1959 ;;
		"Polish" ) KeyboardLayout_IDs[0]=30762 ;;
		"Polish Pro" ) KeyboardLayout_IDs[0]=30788 ;;
		"Portuguese" ) KeyboardLayout_IDs[0]=10 ;;
		"Romanian" ) KeyboardLayout_IDs[0]=-39 ;;
		"Romanian - Standard" ) KeyboardLayout_IDs[0]=-38 ;;
		"Russian" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19456 ;;
		"Russian - PC" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19458 ;;
		"Russian - Phonetic" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19457 ;;
		"Sami - PC" ) KeyboardLayout_IDs[0]=-1201 ;;
		"Serbian" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19521 ;;
		"Serbian - Latin" ) KeyboardLayout_IDs[0]=-19521 ;;
		"Sinhala" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-25088 ;;
		"Sinhala - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-25089 ;;
		"Slovak" ) KeyboardLayout_IDs[0]=30777 ;;
		"Slovak - QWERTY" ) KeyboardLayout_IDs[0]=30779 ;;
		"Slovenian" ) KeyboardLayout_IDs[0]=-66 ;;
		"Spanish" ) KeyboardLayout_IDs[0]=8 ;;
		"Spanish - ISO" ) KeyboardLayout_IDs[0]=87 ;;
		"Swedish" ) KeyboardLayout_IDs[0]=224 ;;
		"Swedish - Pro" ) KeyboardLayout_IDs[0]=7 ;;
		"Swedish Sami - PC" ) KeyboardLayout_IDs[0]=-15 ;;
		"Swiss French" ) KeyboardLayout_IDs[0]=18 ;;
		"Swiss German" ) KeyboardLayout_IDs[0]=19 ;;
		"Telugu" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-23552 ;;
		"Telugu - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-23553 ;;
		"Thai" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-26624 ;;
		"Thai - PattaChote" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-26626 ;;
		"Tibetan - Otani" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-26628 ;;
		"Tibetan - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-26625 ;;
		"Tibetan - Wylie" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-2398 ;;
		"Turkish" ) KeyboardLayout_IDs[0]=-24 ;;
		"Turkish - QWERTY" ) KeyboardLayout_IDs[0]=-35 ;;
		"Turkish - QWERTY PC" ) KeyboardLayout_IDs[0]=-36 ;;
		"U.S. Extended" ) KeyboardLayout_IDs[0]=-2 ;;
		"U.S. International - PC" ) KeyboardLayout_IDs[0]=15000 ;;
		"Uighur - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-27000 ;;
		"Ukrainian" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=19518 ;;
		"Unicode Hex Input" ) KeyboardLayout_IDs[0]=-1 ;;
		"Urdu" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-17925 ;;
		"Uyghur" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-27000 ;;
		"Uyghur - QWERTY" ) KeyboardLayout_IDs[0]=0 ; KeyboardLayout_IDs[1]=-27000 ;;
		"Vietnamese" ) KeyboardLayout_IDs[0]=-31232 ;;
		"Welsh" ) KeyboardLayout_IDs[0]=-790 ;;
		* ) if [ -z "${Bundle_IDs[0]}" ] ; then KeyboardLayout_IDs[0]=0 ; fi ;;
	esac
}

function set_KeyboardLayout_Names {
	# ${1}: Keyboard or TypingStyle
	unset KeyboardLayout_Names[@]
	case "${1}" in
		"Afghan Dari" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Afghan Dari" ;;
		"Afghan Pashto" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Afghan Pashto" ;;
		"Afghan Uzbek" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Afghan Uzbek" ;;
		"Arabic" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Arabic" ;;
		"Arabic - PC" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Arabic PC" ;;
		"Arabic - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Arabic-QWERTY" ;;
		"Armenian - HM QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Armenian-HM QWERTY" ;;
		"Armenian - Western QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Armenian-Western QWERTY" ;;
		"Australian" ) KeyboardLayout_Names[0]="Australian" ;;
		"Austrian" ) KeyboardLayout_Names[0]="Austrian" ;;
		"Azeri" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Azeri" ;;
		"Bangla" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Bangla" ;;
		"Bangla - Qwerty" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Bangla-QWERTY" ;;
		"Belgian" ) KeyboardLayout_Names[0]="Belgian" ;;
		"Brazilian" ) KeyboardLayout_Names[0]="Brazilian" ;;
		"British" ) KeyboardLayout_Names[0]="British" ;;
		"British" ) KeyboardLayout_Names[0]="British-PC" ;;
		"Bulgarian" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Bulgarian" ;;
		"Bulgarian - Phonetic" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Bulgarian - Phonetic" ;;
		"Byelorussian" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Byelorussian" ;;
		"Canadian English" ) KeyboardLayout_Names[0]="Canadian" ;;
		"Canadian French - CSA" ) KeyboardLayout_Names[0]="Canadian - CSA" ;;
		"Cherokee - Nation" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Cherokee-Nation" ;;
		"Cherokee - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Cherokee-QWERTY" ;;
		"Colemak" ) KeyboardLayout_Names[0]="Colemak" ;;
		"Croatian" ) KeyboardLayout_Names[0]="Croatian" ;;
		"Croatian - PC" ) KeyboardLayout_Names[0]="Croatian-PC" ;;
		"Czech" ) KeyboardLayout_Names[0]="Czech" ;;
		"Czech - QWERTY" ) KeyboardLayout_Names[0]="Czech-QWERTY" ;;
		"Danish" ) KeyboardLayout_Names[0]="Danish" ;;
		"Devanagari" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Devanagari" ;;
		"Devanagari - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Devanagari-QWERTY" ;;
		"Dutch" ) KeyboardLayout_Names[0]="Dutch" ;;
		"Dvorak" ) KeyboardLayout_Names[0]="Dvorak" ;;
		"Dvorak - Left" ) KeyboardLayout_Names[0]="Dvorak - Left" ;;
		"Dvorak - Qwerty" ) KeyboardLayout_Names[0]="DVORAK - QWERTY CMD" ;;
		"Dvorak - Qwerty  " ) KeyboardLayout_Names[0]="DVORAK - QWERTY CMD" ;;
		"Dvorak - Right" ) KeyboardLayout_Names[0]="Dvorak - Right" ;;
		"Estonian" ) KeyboardLayout_Names[0]="Estonian" ;;
		"Faroese" ) KeyboardLayout_Names[0]="Faroese" ;;
		"Finnish" ) KeyboardLayout_Names[0]="Finnish" ;;
		"Finnish Extended" ) KeyboardLayout_Names[0]="Finnish Extended" ;;
		"Finnish Sami - PC" ) KeyboardLayout_Names[0]="FinnishSami-PC" ;;
		"French" ) KeyboardLayout_Names[0]="French" ;;
		"French - Numerical" ) KeyboardLayout_Names[0]="French - numerical" ;;
		"Georgian - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Georgian-QWERTY" ;;
		"German" ) KeyboardLayout_Names[0]="German" ;;
		"Greek" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Greek" ;;
		"Greek Polytonic" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Greek Polytonic" ;;
		"Gujarati" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Gujarati" ;;
		"Gujarati - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Gujarati-QWERTY" ;;
		"Gurmukhi" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Gurmukhi" ;;
		"Gurmukhi - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Gurmukhi-QWERTY" ;;
		"Hawaiian" ) KeyboardLayout_Names[0]="Hawaiian" ;;
		"Hebrew" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Hebrew" ;;
		"Hebrew - PC" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Hebrew-PC" ;;
		"Hebrew - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Hebrew-QWERTY" ;;
		"Hungarian" ) KeyboardLayout_Names[0]="Hungarian" ;;
		"Icelandic" ) KeyboardLayout_Names[0]="Icelandic" ;;
		"Inuktitut - Nunavut" ) KeyboardLayout_Names[0]="Inuktitut-Nunavut" ;;
		"Inuktitut - Nutaaq" ) KeyboardLayout_Names[0]="Inuktitut-Nutaaq" ;;
		"Inuktitut - QWERTY" ) KeyboardLayout_Names[0]="Inuktitut-QWERTY" ;;
		"Inuttitut Nunavik" ) KeyboardLayout_Names[0]="Inuttitut Nunavik" ;;
		"Irish" ) KeyboardLayout_Names[0]="Irish" ;;
		"Irish Extended" ) KeyboardLayout_Names[0]="Irish Extended" ;;
		"Italian" )
			case ${TargetOSMinor} in
				5 | 6 ) KeyboardLayout_Names[0]="Italian" ;;
				7 | 8 ) KeyboardLayout_Names[0]="Italian - Pro" ;;
			esac ;;
		"Italian - Pro" ) KeyboardLayout_Names[0]="Italian - Pro" ;;
		"Italian Typewriter" ) KeyboardLayout_Names[0]="Italian" ;;
		"Jawi - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Jawi-QWERTY" ;;
		"Kannada" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Kannada" ;;
		"Kannada - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Kannada-QWERTY" ;;
		"Kazakh" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Kazakh" ;;
		"Khmer" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Khmer" ;;
		"Kurdish-Sorani" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Kurdish-Sorani" ;;
		"Latvian" ) KeyboardLayout_Names[0]="Latvian" ;;
		"Lithuanian" ) KeyboardLayout_Names[0]="Lithuanian" ;;
		"Macedonian" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Macedonian" ;;
		"Malayalam" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Malayalam" ;;
		"Malayalam - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Malayalam-QWERTY" ;;
		"Maltese" ) KeyboardLayout_Names[0]="Maltese" ;;
		"Maori" ) KeyboardLayout_Names[0]="Maori" ;;
		"Myanmar - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Myanmar-QWERTY" ;;
		"Nepali" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Nepali" ;;
		"Northern Sami" ) KeyboardLayout_Names[0]="Northern Sami" ;;
		"Norwegian" ) KeyboardLayout_Names[0]="Norwegian" ;;
		"Norwegian Extended" ) KeyboardLayout_Names[0]="Norwegian Extended" ;;
		"Norwegian Sami - PC" ) KeyboardLayout_Names[0]="NorwegianSami-PC" ;;
		"Oriya" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Oriya" ;;
		"Oriya - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Oriya-QWERTY" ;;
		"Persian" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Persian" ;;
		"Persian - ISIRI" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Persian-ISIRI 2901" ;;
		"Persian - ISIRI 2901" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Persian-ISIRI 2901" ;;
		"Persian - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Persian-QWERTY" ;;
		"Polish" ) KeyboardLayout_Names[0]="Polish" ;;
		"Polish Pro" ) KeyboardLayout_Names[0]="Polish Pro" ;;
		"Portuguese" ) KeyboardLayout_Names[0]="Portuguese" ;;
		"Romanian" ) KeyboardLayout_Names[0]="Romanian" ;;
		"Romanian - Standard" ) KeyboardLayout_Names[0]="Romanian-Standard" ;;
		"Russian" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Russian" ;;
		"Russian - PC" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="RussianWin" ;;
		"Russian - Phonetic" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Russian - Phonetic" ;;
		"Sami - PC" ) KeyboardLayout_Names[0]="Sami-PC" ;;
		"Serbian" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Serbian" ;;
		"Serbian - Latin" ) KeyboardLayout_Names[0]="Serbian-Latin" ;;
		"Sinhala" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Sinhala" ;;
		"Sinhala - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Sinhala-QWERTY" ;;
		"Slovak" ) KeyboardLayout_Names[0]="Slovak" ;;
		"Slovak - QWERTY" ) KeyboardLayout_Names[0]="Slovak-QWERTY" ;;
		"Slovenian" ) KeyboardLayout_Names[0]="Slovenian" ;;
		"Spanish" ) KeyboardLayout_Names[0]="Spanish" ;;
		"Spanish - ISO" ) KeyboardLayout_Names[0]="Spanish - ISO" ;;
		"Swedish" ) KeyboardLayout_Names[0]="Swedish" ;;
		"Swedish - Pro" ) KeyboardLayout_Names[0]="Swedish - Pro" ;;
		"Swedish Sami - PC" ) KeyboardLayout_Names[0]="SwedishSami-PC" ;;
		"Swiss French" ) KeyboardLayout_Names[0]="Swiss French" ;;
		"Swiss German" ) KeyboardLayout_Names[0]="Swiss German" ;;
		"Telugu" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Telugu" ;;
		"Telugu - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Telugu-QWERTY" ;;
		"Thai" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Thai" ;;
		"Thai - PattaChote" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Thai-PattaChote" ;;
		"Tibetan - Otani" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="TibetanOtaniUS" ;;
		"Tibetan - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Tibetan-QWERTY" ;;
		"Tibetan - Wylie" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Tibetan-Wylie" ;;
		"Turkish" ) KeyboardLayout_Names[0]="Turkish" ;;
		"Turkish - QWERTY" ) KeyboardLayout_Names[0]="Turkish-QWERTY" ;;
		"Turkish - QWERTY PC" ) KeyboardLayout_Names[0]="Turkish-QWERTY-PC" ;;
		"U.S. Extended" ) KeyboardLayout_Names[0]="US Extended" ;;
		"U.S. International - PC" ) KeyboardLayout_Names[0]="USInternational-PC" ;;
		"Uighur - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Uyghur-QWERTY" ;;
		"Ukrainian" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Ukrainian" ;;
		"Unicode Hex Input" ) KeyboardLayout_Names[0]="Unicode Hex Input" ;;
		"Urdu" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Urdu" ;;
		"Uyghur" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Uyghur" ;;
		"Uyghur - QWERTY" ) KeyboardLayout_Names[0]="U.S." ; KeyboardLayout_Names[1]="Uyghur-QWERTY" ;;
		"Vietnamese" ) KeyboardLayout_Names[0]="Vietnamese" ;;
		"Welsh" ) KeyboardLayout_Names[0]="Welsh" ;;
		* ) if [ -z "${Bundle_IDs[0]}" ] ; then KeyboardLayout_Names[0]="U.S." ; fi ;;
	esac
}

function set_SelectedInputSource {
	# ${1}: Keyboard or TypingStyle
	unset SelectedInputSource
	case "${1}" in
		"Afghan Dari" ) SelectedInputSource=1 ;;
		"Afghan Pashto" ) SelectedInputSource=1 ;;
		"Afghan Uzbek" ) SelectedInputSource=1 ;;
		"Arabic" ) SelectedInputSource=1 ;;
		"Arabic - PC" ) SelectedInputSource=1 ;;
		"Arabic - QWERTY" ) SelectedInputSource=1 ;;
		"Armenian - HM QWERTY" ) SelectedInputSource=1 ;;
		"Armenian - Western QWERTY" ) SelectedInputSource=1 ;;
		"Azeri" ) SelectedInputSource=1 ;;
		"Bangla" ) SelectedInputSource=1 ;;
		"Bangla - Qwerty" ) SelectedInputSource=1 ;;
		"Bulgarian" ) SelectedInputSource=1 ;;
		"Bulgarian - Phonetic" ) SelectedInputSource=1 ;;
		"Byelorussian" ) SelectedInputSource=1 ;;
		"Cherokee - Nation" ) SelectedInputSource=1 ;;
		"Cherokee - QWERTY" ) SelectedInputSource=1 ;;
		"Devanagari" ) SelectedInputSource=1 ;;
		"Devanagari - QWERTY" ) SelectedInputSource=1 ;;
		"Georgian - QWERTY" ) SelectedInputSource=1 ;;
		"Greek" ) SelectedInputSource=1 ;;
		"Greek Polytonic" ) SelectedInputSource=1 ;;
		"Gujarati" ) SelectedInputSource=1 ;;
		"Gujarati - QWERTY" ) SelectedInputSource=1 ;;
		"Gurmukhi" ) SelectedInputSource=1 ;;
		"Gurmukhi - QWERTY" ) SelectedInputSource=1 ;;
		"2-Set Korean" ) SelectedInputSource=2 ;;
		"3-Set Korean" ) SelectedInputSource=1 ;;
		"390 Sebulshik" ) SelectedInputSource=4 ;;
		"GongjinCheong Romaja" ) SelectedInputSource=5 ;;
		"HNC Romaja" ) SelectedInputSource=3 ;;
		"Hebrew" ) SelectedInputSource=1 ;;
		"Hebrew - PC" ) SelectedInputSource=1 ;;
		"Hebrew - QWERTY" ) SelectedInputSource=1 ;;
		"Jawi - QWERTY" ) SelectedInputSource=1 ;;
		"Kannada" ) SelectedInputSource=1 ;;
		"Kannada - QWERTY" ) SelectedInputSource=1 ;;
		"Kazakh" ) SelectedInputSource=1 ;;
		"Khmer" ) SelectedInputSource=1 ;;
		"Kana" ) SelectedInputSource=3 ;;
		"Romaji" ) SelectedInputSource=2 ;;
		"Kurdish-Sorani" ) SelectedInputSource=1 ;;
		"Macedonian" ) SelectedInputSource=1 ;;
		"Malayalam" ) SelectedInputSource=1 ;;
		"Malayalam - QWERTY" ) SelectedInputSource=1 ;;
		"Myanmar - QWERTY" ) SelectedInputSource=1 ;;
		"Nepali" ) SelectedInputSource=1 ;;
		"Oriya" ) SelectedInputSource=1 ;;
		"Oriya - QWERTY" ) SelectedInputSource=1 ;;
		"Persian" ) SelectedInputSource=1 ;;
		"Persian - ISIRI" ) SelectedInputSource=1 ;;
		"Persian - ISIRI 2901" ) SelectedInputSource=1 ;;
		"Persian - QWERTY" ) SelectedInputSource=1 ;;
		"Russian" ) SelectedInputSource=1 ;;
		"Russian - PC" ) SelectedInputSource=1 ;;
		"Russian - Phonetic" ) SelectedInputSource=1 ;;
		"Serbian" ) SelectedInputSource=1 ;;
		"ITABC" ) SelectedInputSource=1 ;;
		"Pinyin - Simplified" ) SelectedInputSource=1 ;;
		"Wubi Hua" )
			case ${TargetOSMinor} in
				5 ) SelectedInputSource=3 ;;
				* ) SelectedInputSource=2 ;;
			esac ;;
		"Wubi Xing" )
			case ${TargetOSMinor} in
				5 ) SelectedInputSource=2 ;;
				* ) SelectedInputSource=3 ;;
			esac ;;
		"Sinhala" ) SelectedInputSource=1 ;;
		"Sinhala - QWERTY" ) SelectedInputSource=1 ;;
		"Anjal" )
			case ${TargetOSMinor} in
				5 ) SelectedInputSource=2 ;;
				* ) SelectedInputSource=1 ;;
			esac ;;
		"Tamil99" )
			case ${TargetOSMinor} in
				5 ) SelectedInputSource=1 ;;
				* ) SelectedInputSource=2 ;;
			esac ;;
		"Telugu" ) SelectedInputSource=1 ;;
		"Telugu - QWERTY" ) SelectedInputSource=1 ;;
		"Thai" ) SelectedInputSource=1 ;;
		"Thai - PattaChote" ) SelectedInputSource=1 ;;
		"Tibetan - Otani" ) SelectedInputSource=1 ;;
		"Tibetan - QWERTY" ) SelectedInputSource=1 ;;
		"Tibetan - Wylie" ) SelectedInputSource=1 ;;
		"Cangjie" )
			case ${TargetOSMinor} in
				5 ) SelectedInputSource=5 ;;
				* ) SelectedInputSource=2 ;;
			esac ;;
		"Dayi Pro" ) SelectedInputSource=3 ;;
		"Dayi(Pro)" ) SelectedInputSource=2 ;;
		"Hanin" ) SelectedInputSource=7 ;;
		"Jianyi" )
			case ${TargetOSMinor} in
				6 | 8 ) SelectedInputSource=4 ;;
				* ) SelectedInputSource=3 ;;
			esac ;;
		"Pinyin" ) SelectedInputSource=4 ;;
		"Pinyin - Traditional" )
			case ${TargetOSMinor} in
				6 | 8 ) SelectedInputSource=5 ;;
				7 ) SelectedInputSource=4 ;;
			esac ;;
		"Sucheng" ) SelectedInputSource=4 ;;
		"Zhuyin" ) SelectedInputSource=1 ;;
		"Zhuyin - Eten" ) SelectedInputSource=3 ;;
		"Uighur - QWERTY" ) SelectedInputSource=1 ;;
		"Ukrainian" ) SelectedInputSource=1 ;;
		"Urdu" ) SelectedInputSource=1 ;;
		"Uyghur" ) SelectedInputSource=1 ;;
		"Uyghur - QWERTY" ) SelectedInputSource=1 ;;
		"Simple Telex" ) SelectedInputSource=0 ;;
		"Telex" ) SelectedInputSource=2 ;;
		"VNI" ) SelectedInputSource=2 ;;
		"VIQR" ) SelectedInputSource=2 ;;
		* ) SelectedInputSource=0 ;;
	esac
}

function set_CurrentKeyboardLayoutInputSourceID {
	# ${1}: Keyboard or TypingStyle
	if [ ${TargetOSMinor} -eq 5 ] ; then
		unset CurrentKeyboardLayoutInputSourceID
	else
		case "${1}" in
			"Afghan Dari" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.AfghanDari" ;;
			"Afghan Pashto" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.AfghanPashto" ;;
			"Afghan Uzbek" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.AfghanUzbek" ;;
			"Arabic" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Arabic" ;;
			"Arabic - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.ArabicPC" ;;
			"Arabic - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Arabic-QWERTY" ;;
			"Armenian - HM QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Armenian-HMQWERTY" ;;
			"Armenian - Western QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Armenian-WesternQWERTY" ;;
			"Australian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Australian" ;;
			"Austrian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Austrian" ;;
			"Azeri" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Azeri" ;;
			"Bangla" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Bangla" ;;
			"Bangla - Qwerty" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Bangla-QWERTY" ;;
			"Belgian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Belgian" ;;
			"Brazilian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Brazilian" ;;
			"British" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.British" ;;
			"British - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.British-PC" ;;
			"Bulgarian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Bulgarian" ;;
			"Bulgarian - Phonetic" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Bulgarian-Phonetic" ;;
			"Byelorussian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Byelorussian" ;;
			"Canadian English" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Canadian" ;;
			"Canadian French - CSA" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Canadian-CSA" ;;
			"Cherokee - Nation" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Cherokee-Nation" ;;
			"Cherokee - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Cherokee-QWERTY" ;;
			"Colemak" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Colemak" ;;
			"Croatian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Croatian" ;;
			"Croatian - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Croatian-PC" ;;
			"Czech" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Czech" ;;
			"Czech - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Czech-QWERTY" ;;
			"Danish" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Danish" ;;
			"Devanagari" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Devanagari" ;;
			"Devanagari - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Devanagari-QWERTY" ;;
			"Dutch" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Dutch" ;;
			"Dvorak" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Dvorak" ;;
			"Dvorak - Left" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Dvorak-Left" ;;
			"Dvorak - Qwerty ⌘" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.DVORAK-QWERTYCMD" ;;
			"Dvorak - Right" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Dvorak-Right" ;;
			"Estonian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Estonian" ;;
			"Faroese" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Faroese" ;;
			"Finnish" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Finnish" ;;
			"Finnish Extended" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.FinnishExtended" ;;
			"Finnish Sami - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.FinnishSami-PC" ;;
			"French" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.French" ;;
			"French - Numerical" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.French-numerical" ;;
			"Georgian - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Georgian-QWERTY" ;;
			"German" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.German" ;;
			"Greek" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Greek" ;;
			"Greek Polytonic" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.GreekPolytonic" ;;
			"Gujarati" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Gujarati" ;;
			"Gujarati - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Gujarati-QWERTY" ;;
			"Gurmukhi" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Gurmukhi" ;;
			"Gurmukhi - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Gurmukhi-QWERTY" ;;
			"Hawaiian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Hawaiian" ;;
			"Hebrew" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Hebrew" ;;
			"Hebrew - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Hebrew-PC" ;;
			"Hebrew - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Hebrew-QWERTY" ;;
			"Hungarian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Hungarian" ;;
			"Icelandic" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Icelandic" ;;
			"Inuktitut - Nunavut" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Inuktitut-Nunavut" ;;
			"Inuktitut - Nutaaq" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Inuktitut-Nutaaq" ;;
			"Inuktitut - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Inuktitut-QWERTY" ;;
			"Inuttitut Nunavik" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.InuttitutNunavik" ;;
			"Irish" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Irish" ;;
			"Irish Extended" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.IrishExtended" ;;
			"Italian" )
				case ${TargetOSMinor} in
					6 ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Italian" ;;
					* ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Italian-Pro" ;;
				esac ;;
			"Italian - Pro" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Italian-Pro" ;;
			"Italian Typewriter" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Italian" ;;
			"Jawi - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Jawi-QWERTY" ;;
			"Kannada" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Kannada" ;;
			"Kannada - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Kannada-QWERTY" ;;
			"Kazakh" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Kazakh" ;;
			"Khmer" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Khmer" ;;
			"Kurdish-Sorani" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Kurdish-Sorani" ;;
			"Latvian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Latvian" ;;
			"Lithuanian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Lithuanian" ;;
			"Macedonian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Macedonian" ;;
			"Malayalam" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Malayalam" ;;
			"Malayalam - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Malayalam-QWERTY" ;;
			"Maltese" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Maltese" ;;
			"Maori" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Maori" ;;
			"Myanmar - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Myanmar-QWERTY" ;;
			"Nepali" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Nepali" ;;
			"Northern Sami" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.NorthernSami" ;;
			"Norwegian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Norwegian" ;;
			"Norwegian Extended" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.NorwegianExtended" ;;
			"Norwegian Sami - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.NorwegianSami-PC" ;;
			"Oriya" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Oriya" ;;
			"Oriya - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Oriya-QWERTY" ;;
			"Persian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Persian" ;;
			"Persian - ISIRI" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Persian-ISIRI2901" ;;
			"Persian - ISIRI 2901" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Persian-ISIRI2901" ;;
			"Persian - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Persian-QWERTY" ;;
			"Polish" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Polish" ;;
			"Polish Pro" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.PolishPro" ;;
			"Portuguese" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Portuguese" ;;
			"Romanian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Romanian" ;;
			"Romanian - Standard" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Romanian-Standard" ;;
			"Russian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Russian" ;;
			"Russian - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.RussianWin" ;;
			"Russian - Phonetic" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Russian-Phonetic" ;;
			"Sami - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Sami-PC" ;;
			"Serbian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Serbian" ;;
			"Serbian - Latin" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Serbian-Latin" ;;
			"Sinhala" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Sinhala" ;;
			"Sinhala - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Sinhala-QWERTY" ;;
			"Slovak" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Slovak" ;;
			"Slovak - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Slovak-QWERTY" ;;
			"Slovenian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Slovenian" ;;
			"Spanish" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Spanish" ;;
			"Spanish - ISO" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Spanish-ISO" ;;
			"Swedish" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Swedish" ;;
			"Swedish - Pro" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Swedish-Pro" ;;
			"Swedish Sami - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.SwedishSami-PC" ;;
			"Swiss French" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.SwissFrench" ;;
			"Swiss German" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.SwissGerman" ;;
			"Telugu" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Telugu" ;;
			"Telugu - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Telugu-QWERTY" ;;
			"Thai" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Thai" ;;
			"Thai - PattaChote" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Thai-PattaChote" ;;
			"Tibetan - Otani" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.TibetanOtaniUS" ;;
			"Tibetan - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Tibetan-QWERTY" ;;
			"Tibetan - Wylie" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Tibetan-Wylie" ;;
			"Turkish" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Turkish" ;;
			"Turkish - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Turkish-QWERTY" ;;
			"Turkish - QWERTY PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Turkish-QWERTY-PC" ;;
			"U.S. Extended" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.USExtended" ;;
			"U.S. International - PC" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.USInternational-PC" ;;
			"Ukrainian" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Ukrainian" ;;
			"Unicode Hex Input" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.UnicodeHexInput" ;;
			"Urdu" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Urdu" ;;
			"Uyghur" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Uyghur" ;;
			"Uyghur - QWERTY" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Uyghur-QWERTY" ;;
			"Vietnamese" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Vietnamese" ;;
			"Welsh" ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.Welsh" ;;
			* ) CurrentKeyboardLayoutInputSourceID="com.apple.keylayout.US" ;;
		esac
	fi
}

function set_DefaultAsciiInputSource {
	if [ ${#KeyboardLayout_IDs[@]} -eq 0 ] ; then
		InputSourceKind="Keyboard Layout"
		KeyboardLayout_ID=0
		KeyboardLayout_Name="U.S."
	else
		InputSourceKind="${InputSourceKinds[0]}"
		KeyboardLayout_ID=${KeyboardLayout_IDs[0]}
		KeyboardLayout_Name="${KeyboardLayout_Names[0]}"
	fi
}

function set_InputSourceID {
	# ${1}: SAKeyboard
	# ${1}: SATypingStyle
	unset InputSourceID
	case "${1}" in
		"Afghan Dari" ) InputSourceID="AfghanDari" ;;
		"Afghan Pashto" ) InputSourceID="AfghanPashto" ;;
		"Afghan Uzbek" ) InputSourceID="AfghanUzbek" ;;
		"Arabic" ) InputSourceID="Arabic" ;;
		"Arabic - PC" ) InputSourceID="ArabicPC" ;;
		"Arabic - QWERTY" ) InputSourceID="Arabic-QWERTY" ;;
		"Armenian - HM QWERTY" ) InputSourceID="Armenian-HMQWERTY" ;;
		"Armenian - Western QWERTY" ) InputSourceID="Armenian-WesternQWERTY" ;;
		"Australian" ) InputSourceID="Australian" ;;
		"Austrian" ) InputSourceID="Austrian" ;;
		"Azeri" ) InputSourceID="Azeri" ;;
		"Bangla" ) InputSourceID="Bangla" ;;
		"Bangla - Qwerty" ) InputSourceID="Bangla-QWERTY" ;;
		"Belgian" ) InputSourceID="Belgian" ;;
		"Brazilian" ) InputSourceID="Brazilian" ;;
		"British" ) InputSourceID="British" ;;
		"British - PC" ) InputSourceID="British-PC" ;;
		"Bulgarian" ) InputSourceID="Bulgarian" ;;
		"Bulgarian - Phonetic" ) InputSourceID="Bulgarian-Phonetic" ;;
		"Byelorussian" ) InputSourceID="Byelorussian" ;;
		"Canadian English" ) InputSourceID="Canadian" ;;
		"Canadian French - CSA" ) InputSourceID="Canadian-CSA" ;;
		"Cherokee - Nation" ) InputSourceID="Cherokee-Nation" ;;
		"Cherokee - QWERTY" ) InputSourceID="Cherokee-QWERTY" ;;
		"Simplified Chinese" | "Chinese - Simplified" )
			case "${2}" in
				"ITABC" | "Pinyin - Simplified" ) InputSourceID="SCIM.ITABC" ;;
				"Wubi Hua" ) InputSourceID="SCIM.WBH" ;;
				"Wubi Xing" ) InputSourceID="SCIM.WBX" ;;
			esac ;;
		"Traditional Chinese" | "Chinese - Traditional" )
			case "${2}" in
				"Cangjie" ) InputSourceID="TCIM.Cangjie" ;;
				"Dayi(Pro)" | "Dayi Pro" ) InputSourceID="TCIM.Dayi" ;;
				"Hanin" ) InputSourceID="TCIM.Hanin" ;;
				"Pinyin" | "Pinyin - Traditional" ) InputSourceID="TCIM.Pinyin" ;;
				"Jianyi" | "Sucheng" ) InputSourceID="TCIM.Jianyi" ;;
				"Zhuyin" ) InputSourceID="TCIM.Zhuyin" ;;
				"Zhuyin - Eten" ) InputSourceID="TCIM.ZhuyinEten" ;;
			esac ;;
		"Colemak" ) InputSourceID="Colemak" ;;
		"Croatian" ) InputSourceID="Croatian" ;;
		"Croatian - PC" ) InputSourceID="Croatian-PC" ;;
		"Czech" ) InputSourceID="Czech" ;;
		"Czech - QWERTY" ) InputSourceID="Czech-QWERTY" ;;
		"Danish" ) InputSourceID="Danish" ;;
		"Devanagari" ) InputSourceID="Devanagari" ;;
		"Devanagari - QWERTY" ) InputSourceID="Devanagari-QWERTY" ;;
		"Dutch" ) InputSourceID="Dutch" ;;
		"Dvorak" ) InputSourceID="Dvorak" ;;
		"Dvorak - Left" ) InputSourceID="Dvorak-Left" ;;
		"Dvorak - Qwerty ⌘" ) InputSourceID="DVORAK-QWERTYCMD" ;;
		"Dvorak - Right" ) InputSourceID="Dvorak-Right" ;;
		"Estonian" ) InputSourceID="Estonian" ;;
		"Faroese" ) InputSourceID="Faroese" ;;
		"Finnish" ) InputSourceID="Finnish" ;;
		"Finnish Extended" ) InputSourceID="FinnishExtended" ;;
		"Finnish Sami - PC" ) InputSourceID="FinnishSami-PC" ;;
		"French" ) InputSourceID="French" ;;
		"French - Numerical" ) InputSourceID="French-numerical" ;;
		"Georgian - QWERTY" ) InputSourceID="Georgian-QWERTY" ;;
		"German" ) InputSourceID="German" ;;
		"Greek" ) InputSourceID="Greek" ;;
		"Greek Polytonic" ) InputSourceID="GreekPolytonic" ;;
		"Gujarati" ) InputSourceID="Gujarati" ;;
		"Gujarati - QWERTY" ) InputSourceID="Gujarati-QWERTY" ;;
		"Gurmukhi" ) InputSourceID="Gurmukhi" ;;
		"Gurmukhi - QWERTY" ) InputSourceID="Gurmukhi-QWERTY" ;;
		"Hangul" )
			case "${2}" in
				"2-Set Korean" ) InputSourceID="Korean.2SetKorean" ;;
				"3-Set Korean" ) InputSourceID="Korean.3SetKorean" ;;
				"390 Sebulshik" ) InputSourceID="Korean.390Sebulshik" ;;
				"GongjinCheong Romaja" ) InputSourceID="Korean.GongjinCheongRomaja" ;;
				"HNC Romaja" ) InputSourceID="Korean.HNCRomaja" ;;
			esac ;;
		"Hawaiian" ) InputSourceID="Hawaiian" ;;
		"Hebrew" ) InputSourceID="Hebrew" ;;
		"Hebrew - PC" ) InputSourceID="Hebrew-PC" ;;
		"Hebrew - QWERTY" ) InputSourceID="Hebrew-QWERTY" ;;
		"Hungarian" ) InputSourceID="Hungarian" ;;
		"Icelandic" ) InputSourceID="Icelandic" ;;
		"Inuktitut - Nunavut" ) InputSourceID="Inuktitut-Nunavut" ;;
		"Inuktitut - Nutaaq" ) InputSourceID="Inuktitut-Nutaaq" ;;
		"Inuktitut - QWERTY" ) InputSourceID="Inuktitut-QWERTY" ;;
		"Inuttitut Nunavik" ) InputSourceID="InuttitutNunavik" ;;
		"Irish" ) InputSourceID="Irish" ;;
		"Irish Extended" ) InputSourceID="IrishExtended" ;;
		"Italian" )
			case ${TargetOSMinor} in
				5 | 6 ) InputSourceID="Italian" ;;
				* ) InputSourceID="Italian-Pro" ;;
			esac ;;
		"Italian Typewriter" ) InputSourceID="Italian" ;;
		"Italian - Pro" ) InputSourceID="Italian-Pro" ;;
		"Jawi - QWERTY" ) InputSourceID="Jawi-QWERTY" ;;
		"Kannada" ) InputSourceID="Kannada" ;;
		"Kannada - QWERTY" ) InputSourceID="Kannada-QWERTY" ;;
		"Kazakh" ) InputSourceID="Kazakh" ;;
		"Khmer" ) InputSourceID="Khmer" ;;
		"Kotoeri" )
			case "${2}" in
				"Kana" ) InputSourceID="Japanese.Katakana" ;;
				"Romaji" ) InputSourceID="Japanese.Roman" ;;
			esac ;;
		"Kurdish-Sorani" ) InputSourceID="Kurdish-Sorani" ;;
		"Latvian" ) InputSourceID="Latvian" ;;
		"Lithuanian" ) InputSourceID="Lithuanian" ;;
		"Macedonian" ) InputSourceID="Macedonian" ;;
		"Malayalam" ) InputSourceID="Malayalam" ;;
		"Malayalam - QWERTY" ) InputSourceID="Malayalam-QWERTY" ;;
		"Maltese" ) InputSourceID="Maltese" ;;
		"Maori" ) InputSourceID="Maori" ;;
		"Myanmar - QWERTY" ) InputSourceID="Myanmar-QWERTY" ;;
		"Nepali" ) InputSourceID="Nepali" ;;
		"Northern Sami" ) InputSourceID="NorthernSami" ;;
		"Norwegian" ) InputSourceID="Norwegian" ;;
		"Norwegian Extended" ) InputSourceID="NorwegianExtended" ;;
		"Norwegian Sami - PC" ) InputSourceID="NorwegianSami-PC" ;;
		"Oriya" ) InputSourceID="Oriya" ;;
		"Oriya - QWERTY" ) InputSourceID="Oriya-QWERTY" ;;
		"Persian" ) InputSourceID="Persian" ;;
		"Persian - ISIRI 2901" | "Persian - ISIRI" ) InputSourceID="Persian-ISIRI2901" ;;
		"Persian - QWERTY" ) InputSourceID="Persian-QWERTY" ;;
		"Polish" ) InputSourceID="Polish" ;;
		"Polish Pro" ) InputSourceID="PolishPro" ;;
		"Portuguese" ) InputSourceID="Portuguese" ;;
		"Romanian" ) InputSourceID="Romanian" ;;
		"Romanian - Standard" ) InputSourceID="Romanian-Standard" ;;
		"Russian" ) InputSourceID="Russian" ;;
		"Russian - PC" ) InputSourceID="RussianWin" ;;
		"Russian - Phonetic" ) InputSourceID="Russian-Phonetic" ;;
		"Sami - PC" ) InputSourceID="Sami-PC" ;;
		"Serbian" ) InputSourceID="Serbian" ;;
		"Serbian - Latin" ) InputSourceID="Serbian-Latin" ;;
		"Sinhala" ) InputSourceID="Sinhala" ;;
		"Sinhala - QWERTY" ) InputSourceID="Sinhala-QWERTY" ;;
		"Slovak" ) InputSourceID="Slovak" ;;
		"Slovak - QWERTY" ) InputSourceID="Slovak-QWERTY" ;;
		"Slovenian" ) InputSourceID="Slovenian" ;;
		"Spanish" ) InputSourceID="Spanish" ;;
		"Spanish - ISO" ) InputSourceID="Spanish-ISO" ;;
		"Swedish" ) InputSourceID="Swedish" ;;
		"Swedish - Pro" ) InputSourceID="Swedish-Pro" ;;
		"Swedish Sami - PC" ) InputSourceID="SwedishSami-PC" ;;
		"Swiss French" ) InputSourceID="SwissFrench" ;;
		"Swiss German" ) InputSourceID="SwissGerman" ;;
		"Tamil Input Method" )
			case "${2}" in
				"Anjal" ) InputSourceID="Tamil.AnjalIM" ;;
				"Tamil99" ) InputSourceID="Tamil.Tamil99" ;;
			esac ;;
		"Telugu" ) InputSourceID="Telugu" ;;
		"Telugu - QWERTY" ) InputSourceID="Telugu-QWERTY" ;;
		"Thai" ) InputSourceID="Thai" ;;
		"Thai - PattaChote" ) InputSourceID="Thai-PattaChote" ;;
		"Tibetan - Otani" ) InputSourceID="TibetanOtaniUS" ;;
		"Tibetan - QWERTY" ) InputSourceID="Tibetan-QWERTY" ;;
		"Tibetan - Wylie" ) InputSourceID="Tibetan-Wylie" ;;
		"Turkish" ) InputSourceID="Turkish" ;;
		"Turkish - QWERTY" ) InputSourceID="Turkish-QWERTY" ;;
		"Turkish - QWERTY PC" ) InputSourceID="Turkish-QWERTY-PC" ;;
		"U.S." ) InputSourceID="US" ;;
		"U.S. Extended" ) InputSourceID="USExtended" ;;
		"U.S. International - PC" ) InputSourceID="USInternational-PC" ;;
		"Ukrainian" ) InputSourceID="Ukrainian" ;;
		"Unicode Hex Input" ) InputSourceID="UnicodeHexInput" ;;
		"Urdu" ) InputSourceID="Urdu" ;;
		"Uyghur" ) InputSourceID="Uyghur" ;;
		"Uyghur - QWERTY" ) InputSourceID="Uyghur-QWERTY" ;;
		"Vietnamese" ) InputSourceID="Vietnamese" ;;
		"Vietnamese UniKey" )
			case "${2}" in
				"Simple Telex" ) InputSourceID="VietnameseSimpleTelex" ;;
				"Telex" ) InputSourceID="VietnameseTelex" ;;
				"VIQR" ) InputSourceID="VietnameseVIQR" ;;
				"VNI" ) InputSourceID="VietnameseVNI" ;;
			esac ;;
		"Welsh" ) InputSourceID="Welsh" ;;
	esac
}

# Section: NTP Settings

function set_NTPServerName {
	# ${1}: NTP Server
	case "${1}" in
		"time.apple.com" ) NTPServerName="Apple Americas/U.S. (time.apple.com)" ;;
		"time.asia.apple.com" ) NTPServerName="Apple Asia (time.asia.apple.com)" ;;
		"time.euro.apple.com" ) NTPServerName="Apple Europe (time.euro.apple.com)" ;;
		* ) NTPServerName="${1}" ;;
	esac
}

function set_NTPServerNames {
	NTPServerNames=( "Apple Americas/U.S. (time.apple.com)" "Apple Asia (time.asia.apple.com)" "Apple Europe (time.euro.apple.com)" )
	j=0 ; for ServerName in "${NTPServerNames[@]}" ; do if [ "${ServerName}" == "${NTPServerName}" ] ; then j=1 ; break ; fi ; done
	if [ ${j} -eq 0 ] ; then NTPServerNames=( "${NTPServerNames[@]}" "${NTPServerName}" ) ; fi
}

function set_NTPServer {
	# ${1}: NTP Server Name
	case "${1}" in
		"Apple Americas/U.S. (time.apple.com)" ) NTPServer="time.apple.com" ;;
		"Apple Asia (time.asia.apple.com)" ) NTPServer="time.asia.apple.com" ;;
		"Apple Europe (time.euro.apple.com)" ) NTPServer="time.euro.apple.com" ;;
		* ) NTPServer="${1}" ;;
	esac
}

# Section: Time Zone

function convert_CityToGeonameID {
	# ${1}: City
	case "${1}" in
		"Abu Dhabi" ) echo 292968 ;;
		"Accra" ) echo 2306104 ;;
		"Adak" ) echo 5878818 ;;
		"Addis Ababa" ) echo 344979 ;;
		"Adelaide" ) echo 2078025 ;;
		"Algiers" ) echo 2507480 ;;
		"Amman" ) echo 250441 ;;
		"Amsterdam" ) echo 2759794 ;;
		"Anadyr" ) echo 2127202 ;;
		"Antananarivo" ) echo 1070940 ;;
		"Anchorage" ) echo 5879400 ;;
		"Ankara" ) echo 323786 ;;
		"Ashgabat" ) echo 162183 ;;
		"Asmera" ) echo 343300 ;;
		"Asuncion" ) echo 3439389 ;;
		"Athens" ) echo 264371 ;;
		"Atlanta" ) echo 4180439 ;;
		"Austin" ) echo 4671654 ;;
		"Baghdad" ) echo 98182 ;;
		"Baku" ) echo 587084 ;;
		"Bamako" ) echo 2460596 ;;
		"Bangkok" ) echo 1609350 ;;
		"Bangui" ) echo 2389853 ;;
		"Bridgetown" ) echo 3374036 ;;
		"Beijing" ) echo 1816670 ;;
		"Beirut" ) echo 276781 ;;
		"Belgrade" ) echo 792680 ;;
		"Berlin" ) echo 2950159 ;;
		"Blacksburg" ) echo 4747845 ;;
		"Bogota" ) echo 3688689 ;;
		"Boston" ) echo 4930956 ;;
		"Bratislava" ) echo 3060972 ;;
		"Brasalia" ) echo 3469058 ;;
		"Brisbane" ) echo 2174003 ;;
		"Brussels" ) echo 2800866 ;;
		"Bucharest" ) echo 683506 ;;
		"Budapest" ) echo 3054643 ;;
		"Buenos Aires" ) echo 3435910 ;;
		"Cairo" ) echo 360630 ;;
		"Calgary" ) echo 5913490 ;;
		"Canberra" ) echo 2172517 ;;
		"Canton" ) echo 1809858 ;;
		"Cape Town" ) echo 3369157 ;;
		"Caracas" ) echo 3646738 ;;
		"Cardiff" ) echo 2653822 ;;
		"Cayenne" ) echo 3382160 ;;
		"Chennai" ) echo 1264527 ;;
		"Chicago" ) echo 4887398 ;;
		"Colombo" ) echo 1248991 ;;
		"Columbus" ) echo 4509177 ;;
		"Conakry" ) echo 2422465 ;;
		"Copenhagen" ) echo 2618425 ;;
		"Cupertino" ) echo 5341145 ;;
		"Cork" ) echo 2965140 ;;
		"Dhaka" ) echo 1185241 ;;
		"Dakar" ) echo 2253354 ;;
		"Dallas" ) echo 4684888 ;;
		"Damascus" ) echo 170654 ;;
		"Dar es Salaam" ) echo 160263 ;;
		"Darwin" ) echo 2073124 ;;
		"Denver" ) echo 5419384 ;;
		"Detroit" ) echo 4990729 ;;
		"Djibouti" ) echo 223817 ;;
		"Doha" ) echo 290030 ;;
		"Douala" ) echo 2232593 ;;
		"Dublin" ) echo 2964574 ;;
		"Edinburgh" ) echo 2650225 ;;
		"Freetown" ) echo 2409306 ;;
		"Geneva" ) echo 2660646 ;;
		"Georgetown" ) echo 3378644 ;;
		"Grytviken" ) echo 3426466 ;;
		"Guam" ) echo 4043909 ;;
		"Guatemala" ) echo 3598132 ;;
		"Halifax" ) echo 6324729 ;;
		"Hamburg" ) echo 2911298 ;;
		"Hanoi" ) echo 1581130 ;;
		"Harare" ) echo 890299 ;;
		"Havana" ) echo 3553478 ;;
		"Helsinki" ) echo 658225 ;;
		"Hobart" ) echo 2163355 ;;
		"Hong Kong" ) echo 1819729 ;;
		"Honolulu" ) echo 5856195 ;;
		"Houston" ) echo 4699066 ;;
		"Indianapolis" ) echo 4259418 ;;
		"Islamabad" ) echo 1176615 ;;
		"Istanbul" ) echo 745044 ;;
		"Jakarta" ) echo 1642911 ;;
		"Jerusalem" ) echo 281184 ;;
		"Kabul" ) echo 1138958 ;;
		"Kampala" ) echo 232422 ;;
		"Katmandu" ) echo 1283240 ;;
		"Khartoum" ) echo 379252 ;;
		"Kiev" ) echo 703448 ;;
		"Kinshasa" ) echo 2314302 ;;
		"Knoxville" ) echo 4634946 ;;
		"Kolkata" ) echo 1275004 ;;
		"Krasnoyarsk" ) echo 1502026 ;;
		"Kuala Lumpur" ) echo 1735161 ;;
		"Kuwait" ) echo 285787 ;;
		"La Paz" ) echo 3911925 ;;
		"Lagos" ) echo 2332459 ;;
		"Lima" ) echo 3936456 ;;
		"Lisbon" ) echo 2267057 ;;
		"Ljubljana" ) echo 3196359 ;;
		"London" ) echo 2643743 ;;
		"Los Angeles" ) echo 5368361 ;;
		"Luanda" ) echo 2240449 ;;
		"Lusaka" ) echo 909137 ;;
		"Madrid" ) echo 3117735 ;;
		"Male" ) echo 1282027 ;;
		"Managua" ) echo 3617763 ;;
		"Manama" ) echo 290340 ;;
		"Manchester" ) echo 5089178 ;;
		"Manila" ) echo 1701668 ;;
		"Maputo" ) echo 1040652 ;;
		"Mecca" ) echo 104515 ;;
		"Melbourne" ) echo 2158177 ;;
		"Memphis" ) echo 4641239 ;;
		"Mexico City" ) echo 3530597 ;;
		"Miami" ) echo 4164138 ;;
		"Minneapolis" ) echo 5037649 ;;
		"Magadan" ) echo 2123628 ;;
		"Mogadisho" ) echo 53654 ;;
		"Monrovia" ) echo 2274895 ;;
		"Montevideo" ) echo 3441575 ;;
		"Montreal" ) echo 6077243 ;;
		"Moscow" ) echo 524901 ;;
		"Mumbai" ) echo 1275339 ;;
		"Munich" ) echo 2867714 ;;
		"Muscat" ) echo 287286 ;;
		"Nairobi" ) echo 184745 ;;
		"Ndjamena" ) echo 2427123 ;;
		"New Delhi" ) echo 1261481 ;;
		"New York" ) echo 5128581 ;;
		"Nouakchott" ) echo 2377450 ;;
		"Noumea" ) echo 2139521 ;;
		"Novosibirsk" ) echo 1496747 ;;
		"Nuuk" ) echo 3421319 ;;
		"Omsk" ) echo 1496153 ;;
		"Osaka" ) echo 1853909 ;;
		"Oslo" ) echo 3143244 ;;
		"Ottawa" ) echo 6094817 ;;
		"Ougadougou" ) echo 2357048 ;;
		"Pago Pago" ) echo 5881576 ;;
		"Panama" ) echo 3703443 ;;
		"Paramaribo" ) echo 3383330 ;;
		"Paris" ) echo 2988507 ;;
		"Perth" ) echo 2063523 ;;
		"Philadelphia" ) echo 4560349 ;;
		"Phnom Penh" ) echo 1821306 ;;
		"Phoenix" ) echo 5308655 ;;
		"Ponta Delgada" ) echo 3372783 ;;
		"Port Louis" ) echo 934154 ;;
		"Port-au-Prince" ) echo 3718426 ;;
		"Portland" ) echo 5746545 ;;
		"Prague" ) echo 3067696 ;;
		"Pyongyang" ) echo 1871859 ;;
		"Quito" ) echo 3652462 ;;
		"Rabat" ) echo 2538475 ;;
		"Rangoon" ) echo 1298824 ;;
		"Recife" ) echo 3390760 ;;
		"Regina" ) echo 6119109 ;;
		"Reykjavik" ) echo 3413829 ;;
		"Rio de Janeiro" ) echo 3451190 ;;
		"Riyadh" ) echo 108410 ;;
		"Rome" ) echo 3169070 ;;
		"Salt Lake City" ) echo 5780993 ;;
		"San Diego" ) echo 5391811 ;;
		"San Francisco" ) echo 5391959 ;;
		"San Jose" ) echo 3621849 ;;
		"San Juan" ) echo 4568127 ;;
		"San Salvador" ) echo 3583361 ;;
		"Sanaa" ) echo 71137 ;;
		"Santiago" ) echo 3871336 ;;
		"Santo Domingo" ) echo 3492908 ;;
		"Sao Paulo" ) echo 3448439 ;;
		"Seattle" ) echo 5809844 ;;
		"Seoul" ) echo 1835848 ;;
		"Shanghai" ) echo 1796236 ;;
		"Singapore" ) echo 1880252 ;;
		"Sofia" ) echo 727011 ;;
		"St. John's" ) echo 6324733 ;;
		"St. Louis" ) echo 4407066 ;;
		"St. Petersburg" ) echo 498817 ;;
		"Stockholm" ) echo 2673730 ;;
		"Sydney" ) echo 2147714 ;;
		"Taipei" ) echo 1668341 ;;
		"Tashkent" ) echo 1512569 ;;
		"Tegucigalpa" ) echo 3600949 ;;
		"Tehran" ) echo 112931 ;;
		"Thanh Pho Ho Chi Minh" ) echo 1566083 ;;
		"Tientsin" ) echo 1792947 ;;
		"Tokyo" ) echo 1850147 ;;
		"Toronto" ) echo 6167865 ;;
		"Tripoli" ) echo 2210247 ;;
		"Tunis" ) echo 2464470 ;;
		"Ulaanbaatar" ) echo 2028462 ;;
		"UTC" ) echo 1 ;;
		"Vancouver" ) echo 6173331 ;;
		"Victoria" ) echo 241131 ;;
		"Vienna" ) echo 2761369 ;;
		"Vladivostok" ) echo 2013348 ;;
		"Volgograd" ) echo 472757 ;;
		"Warsaw" ) echo 756135 ;;
		"Washington, D.C." ) echo 4140963 ;;
		"Wellington" ) echo 2179537 ;;
		"Winnipeg" ) echo 6183235 ;;
		"Yakutsk" ) echo 2013159 ;;
		"Yekaterinburg" ) echo 1486209 ;;
		"Yerevan" ) echo 616052 ;;
		"Zagreb" ) echo 3186886 ;;
		"Zurich" ) echo 2657896 ;;
	esac
}

function set_UseGeoKit {
	GeoKitFramework="${Target}/System/Library/PrivateFrameworks/GeoKit.framework/Resources/world.geokit"
	Query="select ZNAME from ${PLACES} where ZGEONAMEID = 5341145;"
	sqlite3 "${GeoKitFramework}" "${Query}" &>/dev/null
	if [ ${?} -ne 0 ] ; then
		UseGeoKit=0
		if [ ${#all_cities_adj_0[@]} -eq 0 ] ; then
			unset all_cities_adj_0[@]	# Latitude
			unset all_cities_adj_1[@]	# Longitude
			unset all_cities_adj_2[@]	# Group
			unset all_cities_adj_3[@]	# TZFile
			unset all_cities_adj_4[@]	# CountryCode
			unset all_cities_adj_5[@]	# City
			unset all_cities_adj_6[@]	# Country
			unset all_cities_adj_7[@]	# GeonameID
			unset Localizable_Cities[@]
			unset Localizable_Countries[@]
			display_Title
			printf "\nCreating Location Database ...  "
			s=1
			TimeZonePrefPane="${Target}/System/Library/PreferencePanes/DateAndTime.prefPane/Contents/Resources/TimeZone.prefPane"
			IsPlist=`file "${TimeZonePrefPane}/Contents/Resources/English.lproj/Localizable_Cities.strings" | grep -vq "property list" ; echo ${?}`
			i=0 ; while : ; do
				Item0=`/usr/libexec/PlistBuddy -c "Print ':${i}:0'" "${TimeZonePrefPane}/Contents/Resources/all_cities_adj.plist" 2>/dev/null`
				if [ ${?} -ne 0 ] ; then break ; fi
				all_cities_adj_0[i]="${Item0}"
				all_cities_adj_1[i]=`/usr/libexec/PlistBuddy -c "Print ':${i}:1'" "${TimeZonePrefPane}/Contents/Resources/all_cities_adj.plist"`
				all_cities_adj_2[i]=`/usr/libexec/PlistBuddy -c "Print ':${i}:2'" "${TimeZonePrefPane}/Contents/Resources/all_cities_adj.plist"`
				all_cities_adj_3[i]=`/usr/libexec/PlistBuddy -c "Print ':${i}:3'" "${TimeZonePrefPane}/Contents/Resources/all_cities_adj.plist"`
				all_cities_adj_4[i]=`/usr/libexec/PlistBuddy -c "Print ':${i}:4'" "${TimeZonePrefPane}/Contents/Resources/all_cities_adj.plist"`
				all_cities_adj_5[i]=`/usr/libexec/PlistBuddy -c "Print ':${i}:5'" "${TimeZonePrefPane}/Contents/Resources/all_cities_adj.plist"`
				all_cities_adj_6[i]=`/usr/libexec/PlistBuddy -c "Print ':${i}:6'" "${TimeZonePrefPane}/Contents/Resources/all_cities_adj.plist"`
				all_cities_adj_7[i]=$(convert_CityToGeonameID "${all_cities_adj_5[i]}")
				if [ ${IsPlist} -eq 1 ] ; then
					Localizable_Cities[i]=`/usr/libexec/PlistBuddy -c "Print ':${all_cities_adj_5[i]}'" "${TimeZonePrefPane}/Contents/Resources/English.lproj/Localizable_Cities.strings"`
					Localizable_Countries[i]=`/usr/libexec/PlistBuddy -c "Print ':${all_cities_adj_6[i]}'" "${TimeZonePrefPane}/Contents/Resources/English.lproj/Localizable_Countries.strings"`
				else
					Localizable_Cities[i]=`cat "${TimeZonePrefPane}/Contents/Resources/English.lproj/Localizable_Cities.strings" | iconv -f UTF-16 -t UTF-8 --unicode-subst="" | grep "\"${all_cities_adj_5[i]}\"" | awk -F "\"" '{print $4}'`
					Localizable_Countries[i]=`cat "${TimeZonePrefPane}/Contents/Resources/English.lproj/Localizable_Countries.strings" | iconv -f UTF-16 -t UTF-8 --unicode-subst="" | grep "\"${all_cities_adj_6[i]}\"" | awk -F "\"" '{print $4}'`
				fi
				printf "\b${spin:s++%${#spin}:1}"
				let i++
			done
			printf "\bdone\n"
		fi
	else
		UseGeoKit=1
	fi
}

function set_DefaultGeonameID {
	# ${1}: Country Code
	if [ ${UseGeoKit} -eq 0 ] ; then
		case "${1}" in
			"AE" ) GeonameID=292968 ;;
			"AF" ) GeonameID=1138958 ;;
			"AM" ) GeonameID=616052 ;;
			"AO" ) GeonameID=2240449 ;;
			"AR" ) GeonameID=3435910 ;;
			"AT" ) GeonameID=2761369 ;;
			"AU" ) GeonameID=2172517 ;;
			"AZ" ) GeonameID=587084 ;;
			"BB" ) GeonameID=3374036 ;;
			"BD" ) GeonameID=1185241 ;;
			"BE" ) GeonameID=2800866 ;;
			"BG" ) GeonameID=727011 ;;
			"BH" ) GeonameID=290340 ;;
			"BO" ) GeonameID=3911925 ;;
			"BR" ) GeonameID=3469058 ;;
			"BU" ) GeonameID=1298824 ;;
			"CA" ) GeonameID=6094817 ;;
			"CF" ) GeonameID=2389853 ;;
			"CH" ) GeonameID=2657896 ;;
			"CL" ) GeonameID=3871336 ;;
			"CM" ) GeonameID=2232593 ;;
			"CN" ) GeonameID=1816670 ;;
			"CO" ) GeonameID=3688689 ;;
			"CR" ) GeonameID=3621849 ;;
			"CU" ) GeonameID=3553478 ;;
			"CZ" ) GeonameID=3067696 ;;
			"DE" ) GeonameID=2950159 ;;
			"DJ" ) GeonameID=223817 ;;
			"DK" ) GeonameID=2618425 ;;
			"DO" ) GeonameID=3492908 ;;
			"DZ" ) GeonameID=2507480 ;;
			"EC" ) GeonameID=3652462 ;;
			"EG" ) GeonameID=360630 ;;
			"ER" ) GeonameID=343300 ;;
			"ES" ) GeonameID=3117735 ;;
			"ET" ) GeonameID=344979 ;;
			"FI" ) GeonameID=658225 ;;
			"FR" ) GeonameID=2988507 ;;
			"GB" ) GeonameID=2643743 ;;
			"GF" ) GeonameID=3382160 ;;
			"GH" ) GeonameID=2306104 ;;
			"GL" ) GeonameID=3421319 ;;
			"GN" ) GeonameID=2422465 ;;
			"GR" ) GeonameID=264371 ;;
			"GS" ) GeonameID=3426466 ;;
			"GT" ) GeonameID=3598132 ;;
			"GU" ) GeonameID=4043909 ;;
			"GY" ) GeonameID=3378644 ;;
			"HK" ) GeonameID=1819729 ;;
			"HN" ) GeonameID=3600949 ;;
			"HR" ) GeonameID=3186886 ;;
			"HT" ) GeonameID=3718426 ;;
			"HU" ) GeonameID=3054643 ;;
			"HV" ) GeonameID=2357048 ;;
			"ID" ) GeonameID=1642911 ;;
			"IE" ) GeonameID=2964574 ;;
			"IL" ) GeonameID=281184 ;;
			"IN" ) GeonameID=1261481 ;;
			"IQ" ) GeonameID=98182 ;;
			"IR" ) GeonameID=112931 ;;
			"IS" ) GeonameID=3413829 ;;
			"IT" ) GeonameID=3169070 ;;
			"JO" ) GeonameID=250441 ;;
			"JP" ) GeonameID=1850147 ;;
			"KE" ) GeonameID=184745 ;;
			"KH" ) GeonameID=1821306 ;;
			"KR" ) GeonameID=1835848 ;;
			"KW" ) GeonameID=285787 ;;
			"LB" ) GeonameID=276781 ;;
			"LK" ) GeonameID=1248991 ;;
			"LR" ) GeonameID=2274895 ;;
			"LY" ) GeonameID=2210247 ;;
			"MA" ) GeonameID=2538475 ;;
			"MG" ) GeonameID=1070940 ;;
			"ML" ) GeonameID=2460596 ;;
			"MN" ) GeonameID=2028462 ;;
			"MR" ) GeonameID=2377450 ;;
			"MU" ) GeonameID=934154 ;;
			"MV" ) GeonameID=1282027 ;;
			"MX" ) GeonameID=3530597 ;;
			"MY" ) GeonameID=1735161 ;;
			"MZ" ) GeonameID=1040652 ;;
			"NC" ) GeonameID=2139521 ;;
			"NG" ) GeonameID=2332459 ;;
			"NI" ) GeonameID=3617763 ;;
			"NL" ) GeonameID=2759794 ;;
			"NO" ) GeonameID=3143244 ;;
			"NP" ) GeonameID=1283240 ;;
			"NZ" ) GeonameID=2179537 ;;
			"OM" ) GeonameID=287286 ;;
			"PA" ) GeonameID=3703443 ;;
			"PE" ) GeonameID=3936456 ;;
			"PH" ) GeonameID=1701668 ;;
			"PK" ) GeonameID=1176615 ;;
			"PL" ) GeonameID=756135 ;;
			"PT" ) GeonameID=2267057 ;;
			"PY" ) GeonameID=3439389 ;;
			"QA" ) GeonameID=290030 ;;
			"RO" ) GeonameID=683506 ;;
			"RU" ) GeonameID=524901 ;;
			"SA" ) GeonameID=108410 ;;
			"SC" ) GeonameID=241131 ;;
			"SD" ) GeonameID=379252 ;;
			"SE" ) GeonameID=2673730 ;;
			"SG" ) GeonameID=1880252 ;;
			"SI" ) GeonameID=3196359 ;;
			"SK" ) GeonameID=3060972 ;;
			"SL" ) GeonameID=2409306 ;;
			"SN" ) GeonameID=2253354 ;;
			"SO" ) GeonameID=53654 ;;
			"SR" ) GeonameID=3383330 ;;
			"SV" ) GeonameID=3583361 ;;
			"SY" ) GeonameID=170654 ;;
			"TD" ) GeonameID=2427123 ;;
			"TH" ) GeonameID=1609350 ;;
			"TM" ) GeonameID=162183 ;;
			"TN" ) GeonameID=2464470 ;;
			"TR" ) GeonameID=323786 ;;
			"TW" ) GeonameID=1668341 ;;
			"TZ" ) GeonameID=160263 ;;
			"UA" ) GeonameID=703448 ;;
			"UG" ) GeonameID=232422 ;;
			"UY" ) GeonameID=3441575 ;;
			"UZ" ) GeonameID=1512569 ;;
			"VE" ) GeonameID=3646738 ;;
			"VN" ) GeonameID=1581130 ;;
			"WS" ) GeonameID=5881576 ;;
			"YD" ) GeonameID=71137 ;;
			"YU" ) GeonameID=792680 ;;
			"ZA" ) GeonameID=3369157 ;;
			"ZM" ) GeonameID=909137 ;;
			"ZR" ) GeonameID=2314302 ;;
			"ZW" ) GeonameID=890299 ;;
			* ) GeonameID=5341145 ;;
		esac
	else
		Query="select Z_PK from ${PLACES} where ZCODE = '${1}';"
		ZCOUNTRY=`sqlite3 "${GeoKitFramework}" "${Query}"`
		Query="select ZGEONAMEID from ${PLACES} where ZCOUNTRY = ${ZCOUNTRY} and ZISCAPITAL = 1;"
		ZGEONAMEID=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		if [ "${1}" == "US" ] || [ -z "${ZGEONAMEID}" ] ; then ZGEONAMEID=5341145 ; fi
		GeonameID=${ZGEONAMEID}
	fi
}

function set_TZCountryCode {
	# ${1}: GeonameID
	if [ ${UseGeoKit} -eq 0 ] ; then
		i=0 ; for Item in "${all_cities_adj_7[@]}" ; do
			if [ "${Item}" == "${1}" ] ; then break ; fi
			let i++
		done
		TZCountryCode="${all_cities_adj_4[i]}"
	else
		Query="select ZCOUNTRY from ${PLACES} where ZGEONAMEID = ${1};"
		ZCOUNTRY=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZCODE from ${PLACES} where Z_PK = ${ZCOUNTRY};"
		TZCountryCode=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
	fi
}

function set_TZCountry {
	# ${1}: Country Code
	if [ ${UseGeoKit} -eq 0 ] ; then
		i=0 ; for Item in "${all_cities_adj_4[@]}" ; do
			if [ "${Item}" == "${1}" ] ; then break ; fi
			let i++
		done
		echo "${Localizable_Countries[i]}"
	else
		Query="select ZNAME from ${PLACES} where ZCODE = '${1}';"
		sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null
	fi
}

function set_ClosestCity {
	# ${1}: GeonameID
	if [ ${UseGeoKit} -eq 0 ] ; then
		i=0 ; for Item in "${all_cities_adj_7[@]}" ; do
			if [ "${Item}" == "${1}" ] ; then break ; fi
			let i++
		done
		ZNAME="${Localizable_Cities[i]}"
	else
		Query="select ZNAME from ${PLACES} where ZGEONAMEID = ${1};"
		ZNAME=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZREGIONALCODE from ${PLACES} where ZGEONAMEID = ${1};"
		ZREGIONALCODE=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
	fi
	if [ -n "${ZREGIONALCODE}" ] ; then
		echo "${ZNAME}, ${ZREGIONALCODE}"
	else
		echo "${ZNAME}"
	fi
}

function set_TZFile {
	# ${1}: GeonameID
	if [ ${UseGeoKit} -eq 0 ] ; then
		i=0 ; for Item in "${all_cities_adj_7[@]}" ; do
			if [ "${Item}" == "${1}" ] ; then break ; fi
			let i++
		done
		echo "${all_cities_adj_3[i]}"
	else
		Query="select ZTIMEZONENAME from ${PLACES} where ZGEONAMEID = ${1};"
		sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null
	fi
}

function set_TimeZone {
	# ${1}: TZFile
	case "${1}" in
		"Africa/Abidjan" | "Africa/Accra" | "Africa/Bamako" | "Africa/Banjul" | "Africa/Bissau" | "Africa/Conakry" | "Africa/Dakar" | "Africa/Freetown" | "Africa/Lome" | "Africa/Monrovia" | "Africa/Nouakchott" | "Africa/Ouagadougou" | "Africa/Sao_Tome" | "Atlantic/Reykjavik" | "Atlantic/St_Helena" | "Europe/Dublin" | "Europe/Guernsey" | "Europe/Isle_of_Man" | "Europe/Jersey" | "Europe/London" ) echo "Greenwich Mean Time" ;;
		"Africa/Addis_Ababa" | "Africa/Asmara" | "Africa/Asmera" | "Africa/Dar_es_Salaam" | "Africa/Djibouti" | "Africa/Kampala" | "Africa/Khartoum" | "Africa/Mogadishu" | "Africa/Nairobi" | "Indian/Antananarivo" | "Indian/Comoro" | "Indian/Mayotte" ) echo "East Africa Time" ;;
		"Africa/Algiers" | "Africa/Ceuta" | "Africa/Tunis" | "Arctic/Longyearbyen" | "Europe/Amsterdam" | "Europe/Andorra" | "Europe/Belgrade" | "Europe/Berlin" | "Europe/Bratislava" | "Europe/Brussels" | "Europe/Budapest" | "Europe/Copenhagen" | "Europe/Gibraltar" | "Europe/Ljubljana" | "Europe/Luxembourg" | "Europe/Madrid" | "Europe/Malta" | "Europe/Monaco" | "Europe/Oslo" | "Europe/Paris" | "Europe/Podgorica" | "Europe/Prague" | "Europe/Rome" | "Europe/San_Marino" | "Europe/Sarajevo" | "Europe/Skopje" | "Europe/Stockholm" | "Europe/Tirane" | "Europe/Vaduz" | "Europe/Vatican" | "Europe/Vienna" | "Europe/Warsaw" | "Europe/Zagreb" | "Europe/Zurich" ) echo "Central European Time" ;;
		"Africa/Bangui" | "Africa/Brazzaville" | "Africa/Douala" | "Africa/Kinshasa" | "Africa/Lagos" | "Africa/Libreville" | "Africa/Luanda" | "Africa/Malabo" | "Africa/Ndjamena" | "Africa/Niamey" | "Africa/Porto-Novo" | "Africa/Windhoek" ) echo "West Africa Time" ;;
		"Africa/Blantyre" | "Africa/Bujumbura" | "Africa/Gaborone" | "Africa/Harare" | "Africa/Kigali" | "Africa/Lubumbashi" | "Africa/Lusaka" | "Africa/Maputo" ) echo "Central Africa Time" ;;
		"Africa/Cairo" | "Africa/Tripoli" | "Asia/Amman" | "Asia/Beirut" | "Asia/Damascus" | "Asia/Gaza" | "Asia/Nicosia" | "Europe/Athens" | "Europe/Bucharest" | "Europe/Chisinau" | "Europe/Helsinki" | "Europe/Istanbul" | "Europe/Kiev" | "Europe/Riga" | "Europe/Simferopol" | "Europe/Sofia" | "Europe/Tallinn" | "Europe/Uzhgorod" | "Europe/Vilnius" | "Europe/Zaporozhye" ) echo "Eastern European Time" ;;
		"Africa/Casablanca" | "Africa/El_Aaiun" | "Atlantic/Canary" | "Atlantic/Faroe" | "Atlantic/Madeira" | "Europe/Lisbon" ) echo "Western European Time" ;;
		"Africa/Johannesburg" | "Africa/Maseru" | "Africa/Mbabane" ) echo "South Africa Standard Time" ;;
		"America/Adak" | "Pacific/Honolulu" ) echo "Hawaii-Aleutian Standard Time" ;;
		"America/Anchorage" | "America/Juneau" | "America/Nome" ) echo "Alaska Standard Time" ;;
		"America/Anguilla" | "America/Antigua" | "America/Aruba" | "America/Barbados" | "America/Curacao" | "America/Dominica" | "America/Glace_Bay" | "America/Grenada" | "America/Guadeloupe" | "America/Halifax" | "America/Martinique" | "America/Moncton" | "America/Montserrat" | "America/Port_of_Spain" | "America/Puerto_Rico" | "America/Santo_Domingo" | "America/St_Kitts" | "America/St_Lucia" | "America/St_Thomas" | "America/St_Vincent" | "America/Tortola" | "Atlantic/Bermuda" | "Canada/Atlantic" ) echo "Atlantic Standard Time" ;;
		"America/Araguaina" | "America/Bahia" | "America/Belem" | "America/Fortaleza" | "America/Maceio" | "America/Recife" | "America/Santarem" | "America/Sao_Paulo" | "Brazil/East" ) echo "Brasilia Time" ;;
		"America/Argentina/Buenos_Aires" | "America/Argentina/Catamarca" | "America/Argentina/Cordoba" | "America/Argentina/Jujuy" | "America/Argentina/La_Rioja" | "America/Argentina/Mendoza" | "America/Argentina/Rio_Gallegos" | "America/Argentina/Salta" | "America/Argentina/San_Juan" | "America/Argentina/Tucuman" | "America/Argentina/Ushuaia" | "America/Buenos_Aires" ) echo "Argentina Time" ;;
		"America/Argentina/San_Luis" ) echo "GMT-03:00" ;;
		"America/Asuncion" ) echo "Paraguay Time" ;;
		"America/Belize" | "America/Cancun" | "America/Chicago" | "America/Costa_Rica" | "America/El_Salvador" | "America/Guatemala" | "America/Indiana/Tell_City" | "America/Managua" | "America/Matamoros" | "America/Merida" | "America/Mexico_City" | "America/Monterrey" | "America/North_Dakota/New_Salem" | "America/Regina" | "America/Swift_Current" | "America/Tegucigalpa" | "America/Winnipeg" | "Canada/Saskatchewan" | "US/Central" ) echo "Central Standard Time" ;;
		"America/Boa_Vista" | "America/Campo_Grande" | "America/Cuiaba" | "America/Manaus" | "America/Porto_Velho" | "America/Rio_Branco" ) echo "Amazon Time" ;;
		"America/Bogota" ) echo "Colombia Time" ;;
		"America/Boise" | "America/Chihuahua" | "America/Dawson_Creek" | "America/Denver" | "America/Edmonton" | "America/Hermosillo" | "America/Mazatlan" | "America/Ojinaga" | "America/Phoenix" | "America/Yellowknife" | "Canada/Mountain" | "US/Mountain" ) echo "Mountain Standard Time" ;;
		"America/Caracas" ) echo "Venezuela Time" ;;
		"America/Cayenne" ) echo "French Guiana Time" ;;
		"America/Cayman" | "America/Detroit" | "America/Grand_Turk" | "America/Indiana/Indianapolis" | "America/Indiana/Vincennes" | "America/Indianapolis" | "America/Jamaica" | "America/Kentucky/Louisville" | "America/Kentucky/Monticello" | "America/Montreal" | "America/Nassau" | "America/New_York" | "America/Nipigon" | "America/Panama" | "America/Port-au-Prince" | "America/Thunder_Bay" | "America/Toronto" | "Canada/Eastern" | "US/Eastern" ) echo "Eastern Standard Time" ;;
		"America/Godthab" ) echo "West Greenland Time" ;;
		"America/Guayaquil" ) echo "Ecuador Time" ;;
		"America/Guyana" ) echo "Guyana Time" ;;
		"America/Havana" ) echo "Cuba Standard Time" ;;
		"America/La_Paz" ) echo "Bolivia Time" ;;
		"America/Lima" ) echo "Peru Time" ;;
		"America/Los_Angeles" | "America/Santa_Isabel" | "America/Tijuana" | "America/Vancouver" | "America/Whitehorse" | "US/Pacific" ) echo "Pacific Standard Time" ;;
		"America/Miquelon" ) echo "Pierre and Miquelon Standard Time" ;;
		"America/Montevideo" ) echo "Uruguay Time" ;;
		"America/Noronha" ) echo "Fernando de Noronha Time" ;;
		"America/Paramaribo" ) echo "Suriname Time" ;;
		"America/Santiago" ) echo "Chile Time" ;;
		"America/St_Johns" | "Canada/Newfoundland" ) echo "Newfoundland Standard Time" ;;
		"Antarctica/McMurdo" | "Pacific/Auckland" ) echo "New Zealand Standard Time" ;;
		"Asia/Aden" | "Asia/Baghdad" | "Asia/Bahrain" | "Asia/Kuwait" | "Asia/Qatar" | "Asia/Riyadh" ) echo "Arabian Standard Time" ;;
		"Asia/Almaty" | "Asia/Qyzylorda" ) echo "East Kazakhstan Standard Time" ;;
		"Asia/Anadyr" )
			case ${TargetOSMinor} in
				7 ) echo "Magadan Time" ;;
				* ) echo "Anadyr Time" ;;
			esac ;;
		"Asia/Aqtau" | "Asia/Aqtobe" | "Asia/Oral" ) echo "West Kazakhstan Standard Time" ;;
		"Asia/Ashgabat" ) echo "Turkmenistan Time" ;;
		"Asia/Baku" ) echo "Azerbaijan Time" ;;
		"Asia/Bangkok" | "Asia/Ho_Chi_Minh" | "Asia/Phnom_Penh" | "Asia/Saigon" | "Asia/Vientiane" ) echo "Indochina Time" ;;
		"Asia/Bishkek" ) echo "Kyrgyzstan Time" ;;
		"Asia/Brunei" ) echo "Brunei Darussalam Time" ;;
		"Asia/Calcutta" | "Asia/Colombo" | "Asia/Kolkata" ) echo "India Standard Time" ;;
		"Asia/Chongqing" | "Asia/Harbin" | "Asia/Kashgar" | "Asia/Macau" | "Asia/Shanghai" | "Asia/Urumqi" ) echo "China Standard Time" ;;
		"Asia/Dhaka" )
			case ${TargetOSMinor} in
				5 ) echo "GMT+07:00" ;;
				* ) echo "Bangladesh Time" ;;
			esac ;;
		"Asia/Dili" ) echo "East Timor Time" ;;
		"Asia/Dubai" | "Asia/Muscat" ) echo "Gulf Standard Time" ;;
		"Asia/Dushanbe" ) echo "Tajikistan Time" ;;
		"Asia/Hong_Kong" ) echo "Hong Kong Time" ;;
		"Asia/Irkutsk" ) echo "Irkutsk Time" ;;
		"Asia/Jakarta" | "Asia/Pontianak" ) echo "Western Indonesia Time" ;;
		"Asia/Jayapura" ) echo "Eastern Indonesia Time" ;;
		"Asia/Jerusalem" ) echo "Israel Standard Time" ;;
		"Asia/Kabul" ) echo "Afghanistan Time" ;;
		"Asia/Kamchatka" )
			case ${TargetOSMinor} in
				7 ) echo "Magadan Time" ;;
				* ) echo "Petropavlovsk-Kamchatski Time" ;;
			esac ;;
		"Asia/Karachi" ) echo "Pakistan Time" ;;
		"Asia/Kathmandu" | "Asia/Katmandu" ) echo "Nepal Time" ;;
		"Asia/Krasnoyarsk" ) echo "Krasnoyarsk Time" ;;
		"Asia/Kuala_Lumpur" | "Asia/Kuching" ) echo "Malaysia Time" ;;
		"Asia/Magadan" ) echo "Magadan Time" ;;
		"Asia/Makassar" ) echo "Central Indonesia Time" ;;
		"Asia/Manila" ) echo "Philippine Time" ;;
		"Asia/Novokuznetsk" ) echo "Novosibirsk Time" ;;
		"Asia/Novosibirsk" )
			case ${TargetOSMinor} in
				5 ) echo "Novosibirsk Time" ;;
				* ) echo "Krasnoyarsk Time" ;;
			esac ;;
		"Asia/Omsk" ) echo "Omsk Time" ;;
		"Asia/Pyongyang" | "Asia/Seoul" ) echo "Korean Standard Time" ;;
		"Asia/Rangoon" ) echo "Myanmar Time" ;;
		"Asia/Sakhalin" ) echo "Sakhalin Time" ;;
		"Asia/Samarkand" | "Asia/Tashkent" ) echo "Uzbekistan Time" ;;
		"Asia/Singapore" ) echo "Singapore Standard Time" ;;
		"Asia/Taipei" )
			case ${TargetOSMinor} in
				7 ) echo "Taipei Standard Time" ;;
				* ) echo "GMT+08:00" ;;
			esac ;;
		"Asia/Tbilisi" ) echo "Georgia Time" ;;
		"Asia/Tehran" ) echo "Iran Standard Time" ;;
		"Asia/Thimphu" ) echo "Bhutan Time" ;;
		"Asia/Tokyo" ) echo "Japan Standard Time" ;;
		"Asia/Ulaanbaatar" ) echo "Ulan Bator Time" ;;
		"Asia/Vladivostok" ) echo "Vladivostok Time" ;;
		"Asia/Yakutsk" ) echo "Yakutsk Time" ;;
		"Asia/Yekaterinburg" ) echo "Yekaterinburg Time" ;;
		"Asia/Yerevan" ) echo "Armenia Time" ;;
		"Atlantic/Azores" ) echo "Azores Time" ;;
		"Atlantic/Cape_Verde" ) echo "Cape Verde Time" ;;
		"Atlantic/South_Georgia" ) echo "South Georgia Time" ;;
		"Atlantic/Stanley" ) echo "Falkland Islands Time" ;;
		"Australia/Adelaide" | "Australia/Broken_Hill" | "Australia/Darwin" ) echo "Australian Central Standard Time" ;;
		"Australia/Brisbane" | "Australia/Canberra" | "Australia/Hobart" | "Australia/Melbourne" | "Australia/Sydney" ) echo "Australian Eastern Standard Time" ;;
		"Australia/Perth" ) echo "Australian Western Standard Time" ;;
		"Europe/Kaliningrad" )
			case ${TargetOSMinor} in
				6 ) echo "Eastern European Time" ;;
				* ) echo "GMT+03:00" ;;
			esac ;;
		"Europe/Minsk" )
			case ${TargetOSMinor} in
				6 ) echo "Eastern European Time" ;;
				* ) echo "GMT+03:00" ;;
			esac ;;
		"Europe/Moscow" ) echo "Moscow Standard Time" ;;
		"Europe/Samara" )
			case ${TargetOSMinor} in
				7 ) echo "Moscow Standard Time" ;;
				* ) echo "Samara Time" ;;
			esac ;;
		"Europe/Volgograd" ) echo "Volgograd Time" ;;
		"Indian/Christmas" ) echo "Christmas Island Time" ;;
		"Indian/Cocos" ) echo "Cocos Islands Time" ;;
		"Indian/Kerguelen" ) echo "French Southern and Antarctic Time" ;;
		"Indian/Mahe" ) echo "Seychelles Time" ;;
		"Indian/Maldives" ) echo "Maldives Time" ;;
		"Indian/Mauritius" ) echo "Mauritius Time" ;;
		"Indian/Reunion" ) echo "Reunion Time" ;;
		"Pacific/Apia" | "Pacific/Pago_Pago" ) echo "Samoa Standard Time" ;;
		"Pacific/Efate" ) echo "Vanuatu Time" ;;
		"Pacific/Fiji" ) echo "Fiji Time" ;;
		"Pacific/Funafuti" ) echo "Tuvalu Time" ;;
		"Pacific/Guadalcanal" ) echo "Solomon Islands Time" ;;
		"Pacific/Guam" | "Pacific/Saipan" ) echo "Chamorro Standard Time" ;;
		"Pacific/Majuro" ) echo "Marshall Islands Time" ;;
		"Pacific/Nauru" ) echo "Nauru Time" ;;
		"Pacific/Niue" ) echo "Niue Time" ;;
		"Pacific/Norfolk" ) echo "Norfolk Islands Time" ;;
		"Pacific/Noumea" ) echo "New Caledonia Time" ;;
		"Pacific/Palau" ) echo "Palau Time" ;;
		"Pacific/Pitcairn" ) echo "Pitcairn Time" ;;
		"Pacific/Pohnpei" | "Pacific/Ponape" ) echo "Ponape Time" ;;
		"Pacific/Port_Moresby" ) echo "Papua New Guinea Time" ;;
		"Pacific/Rarotonga" ) echo "Cook Islands Time" ;;
		"Pacific/Tahiti" ) echo "Tahiti Time" ;;
		"Pacific/Tarawa" ) echo "Gilbert Islands Time" ;;
		"Pacific/Tongatapu" ) echo "Tonga Time" ;;
		"Pacific/Wallis" ) echo "Wallis and Futuna Time" ;;
		"UTC" ) echo "GMT+00:00" ;;
	esac
}

function refresh_GeonameID {
	set_UseGeoKit
	j=0
	if [ ${UseGeoKit} -eq 0 ] ; then
		for Item in "${all_cities_adj_7[@]}" ; do
			if [ "${Item}" == "${GeonameID}" ] ; then j=1 ; fi
		done
	else
		Query="select ZGEONAMEID from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		ZGEONAMEID=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		if [ -n "${ZGEONAMEID}" ] ; then j=1 ; fi
	fi
	if [ ${j} -eq 0 ] ; then
		if [ -n "${TZCountryCode}" ] ; then
			set_DefaultGeonameID "${TZCountryCode}"
		else
			set_DefaultGeonameID "${SACountryCode}"
		fi
	fi
	set_TZCountryCode ${GeonameID}
	TZCountry=$(set_TZCountry "${TZCountryCode}")
	ClosestCity="$(set_ClosestCity ${GeonameID})"
	TimeZone=$(set_TimeZone "$(set_TZFile ${GeonameID})")
}

function set_CountryTimeZones {
	# ${1}: Country Code
	unset CountryTZFiles[@]
	if [ ${UseGeoKit} -eq 0 ] ; then
		i=0 ; while [ ${i} -lt ${#all_cities_adj_4[@]} ] ; do
			j=0
			if [ "${all_cities_adj_4[i]}" == "${1}" ] ; then
				j=1
				for TZFILE in "${CountryTZFiles[@]}" ; do
					if [ "${TZFILE}" == "${all_cities_adj_3[i]}" ] ; then j=0 ; break ; fi
				done
			fi
			if [ ${j} -eq 1 ] ; then CountryTZFiles=( "${CountryTZFiles[@]}" "${all_cities_adj_3[i]}" ) ; fi
			let i++
		done
	else
		Query="select Z_PK from ${PLACES} where ZCODE = '${1}';"
		ZCOUNTRY=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		if [ -z "${ZCOUNTRY}" ] ; then
			Query="select Z_PK from ${PLACES} where ZCODE = 'US';"
			ZCOUNTRY=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		fi
		Query="select distinct ZTIMEZONENAME from ${PLACES} where ZCOUNTRY = ${ZCOUNTRY};"
		CountryTZFiles=( `sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null` )
	fi
	unset CountryTimeZones[@]
	for TZFILE in "${CountryTZFiles[@]}" ; do
		TZFILETIMEZONE=$(set_TimeZone "${TZFILE}")
		j=1
		for TIMEZONE in "${CountryTimeZones[@]}" ; do
			if [ "${TZFILETIMEZONE}" == "${TIMEZONE}" ] ; then j=0 ; fi
		done
		if [ ${j} -eq 1 ] ; then CountryTimeZones=( "${CountryTimeZones[@]}" "${TZFILETIMEZONE}" ) ; fi
	done
	IFS=$'\n'
	CountryTimeZones=( `for TIMEZONE in "${CountryTimeZones[@]}" ; do echo "${TIMEZONE}" ; done | sort -u` )
	unset IFS
}

function set_AllTimeZones {
	unset AllTZFiles[@]
	display_Title
	printf "\nCreating Time Zone list ...  "
	s=1
	if [ ${UseGeoKit} -eq 0 ] ; then
		i=0 ; while [ ${i} -lt ${#all_cities_adj_3[@]} ] ; do
			j=1
			for TZFILE in "${AllTZFiles[@]}" ; do
				if [ "${TZFILE}" == "${all_cities_adj_3[i]}" ] ; then j=0 ; break ; fi
				printf "\b${spin:s++%${#spin}:1}"
			done
			if [ ${j} -eq 1 ] ; then AllTZFiles=( "${AllTZFiles[@]}" "${all_cities_adj_3[i]}" ) ; fi
			let i++
		done
	else
		Query="select distinct ZTIMEZONENAME from ZGEOPLACE;"
		AllTZFiles=( `sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null` )
	fi
	unset AllTimeZones[@]
	for TZFILE in "${AllTZFiles[@]}" ; do
		TZFILETIMEZONE=$(set_TimeZone "${TZFILE}")
		j=1
		for TIMEZONE in "${AllTimeZones[@]}" ; do
			if [ "${TZFILETIMEZONE}" == "${TIMEZONE}" ] ; then j=0 ; fi
			printf "\b${spin:s++%${#spin}:1}"
		done
		if [ ${j} -eq 1 ] ; then AllTimeZones=( "${AllTimeZones[@]}" "${TZFILETIMEZONE}" ) ; fi
	done
	printf "\bdone\n"
}

function set_OtherTimeZones {
	set_AllTimeZones
	unset OtherTimeZones[@]
	for TIMEZONE in "${AllTimeZones[@]}" ; do
		j=0 ; for COUNTRYTIMEZONE in "${CountryTimeZones[@]}" ; do
			if [ "${TIMEZONE}" == "${COUNTRYTIMEZONE}" ] ; then j=1 ; break ; fi
		done
		if [ ${j} -eq 0 ] ; then OtherTimeZones=( "${OtherTimeZones[@]}" "${TIMEZONE}" ) ; fi
	done
	IFS=$'\n'
	OtherTimeZones=( `for TIMEZONE in "${OtherTimeZones[@]}" ; do echo "${TIMEZONE}" ; done | sort -u` )
	unset IFS
}

function set_TZFiles {
	# ${1}: Time Zone
	case "${1}" in
		"Afghanistan Time" ) TZFiles=( "Asia/Kabul" ) ;;
		"Alaska Standard Time" ) TZFiles=( "America/Anchorage" "America/Juneau" "America/Nome" ) ;;
		"Amazon Time" ) TZFiles=( "America/Boa_Vista" "America/Campo_Grande" "America/Cuiaba" "America/Manaus" "America/Porto_Velho" "America/Rio_Branco" ) ;;
		"Anadyr Time" ) TZFiles=( "Asia/Anadyr" ) ;;
		"Arabian Standard Time" ) TZFiles=( "Asia/Aden" "Asia/Baghdad" "Asia/Bahrain" "Asia/Kuwait" "Asia/Qatar" "Asia/Riyadh" ) ;;
		"Argentina Time" ) TZFiles=( "America/Argentina/Buenos_Aires" "America/Argentina/Catamarca" "America/Argentina/Cordoba" "America/Argentina/Jujuy" "America/Argentina/La_Rioja" "America/Argentina/Mendoza" "America/Argentina/Rio_Gallegos" "America/Argentina/Salta" "America/Argentina/San_Juan" "America/Argentina/Tucuman" "America/Argentina/Ushuaia" "America/Buenos_Aires" ) ;;
		"Armenia Time" ) TZFiles=( "Asia/Yerevan" ) ;;
		"Atlantic Standard Time" ) TZFiles=( "America/Anguilla" "America/Antigua" "America/Aruba" "America/Barbados" "America/Curacao" "America/Dominica" "America/Glace_Bay" "America/Grenada" "America/Guadeloupe" "America/Halifax" "America/Martinique" "America/Moncton" "America/Montserrat" "America/Port_of_Spain" "America/Puerto_Rico" "America/Santo_Domingo" "America/St_Kitts" "America/St_Lucia" "America/St_Thomas" "America/St_Vincent" "America/Tortola" "Atlantic/Bermuda" "Canada/Atlantic" ) ;;
		"Australian Central Standard Time" ) TZFiles=( "Australia/Adelaide" "Australia/Broken_Hill" "Australia/Darwin" ) ;;
		"Australian Eastern Standard Time" ) TZFiles=( "Australia/Brisbane" "Australia/Canberra" "Australia/Hobart" "Australia/Melbourne" "Australia/Sydney" ) ;;
		"Australian Western Standard Time" ) TZFiles=( "Australia/Perth" ) ;;
		"Azerbaijan Time" ) TZFiles=( "Asia/Baku" ) ;;
		"Azores Time" ) TZFiles=( "Atlantic/Azores" ) ;;
		"Bangladesh Time" ) TZFiles=( "Asia/Dhaka" ) ;;
		"Bhutan Time" ) TZFiles=( "Asia/Thimphu" ) ;;
		"Bolivia Time" ) TZFiles=( "America/La_Paz" ) ;;
		"Brasilia Time" ) TZFiles=( "America/Araguaina" "America/Bahia" "America/Belem" "America/Fortaleza" "America/Maceio" "America/Recife" "America/Santarem" "America/Sao_Paulo" "Brazil/East" ) ;;
		"Brunei Darussalam Time" ) TZFiles=( "Asia/Brunei" ) ;;
		"Cape Verde Time" ) TZFiles=( "Atlantic/Cape_Verde" ) ;;
		"Central Africa Time" ) TZFiles=( "Africa/Blantyre" "Africa/Bujumbura" "Africa/Gaborone" "Africa/Harare" "Africa/Kigali" "Africa/Lubumbashi" "Africa/Lusaka" "Africa/Maputo" ) ;;
		"Central European Time" ) TZFiles=( "Africa/Algiers" "Africa/Ceuta" "Africa/Tunis" "Arctic/Longyearbyen" "Europe/Amsterdam" "Europe/Andorra" "Europe/Belgrade" "Europe/Berlin" "Europe/Bratislava" "Europe/Brussels" "Europe/Budapest" "Europe/Copenhagen" "Europe/Gibraltar" "Europe/Ljubljana" "Europe/Luxembourg" "Europe/Madrid" "Europe/Malta" "Europe/Monaco" "Europe/Oslo" "Europe/Paris" "Europe/Podgorica" "Europe/Prague" "Europe/Rome" "Europe/San_Marino" "Europe/Sarajevo" "Europe/Skopje" "Europe/Stockholm" "Europe/Tirane" "Europe/Vaduz" "Europe/Vatican" "Europe/Vienna" "Europe/Warsaw" "Europe/Zagreb" "Europe/Zurich" ) ;;
		"Central Indonesia Time" ) TZFiles=( "Asia/Makassar" ) ;;
		"Central Standard Time" ) TZFiles=( "America/Belize" "America/Cancun" "America/Chicago" "America/Costa_Rica" "America/El_Salvador" "America/Guatemala" "America/Indiana/Tell_City" "America/Managua" "America/Matamoros" "America/Merida" "America/Mexico_City" "America/Monterrey" "America/North_Dakota/New_Salem" "America/Regina" "America/Swift_Current" "America/Tegucigalpa" "America/Winnipeg" "Canada/Saskatchewan" "US/Central" ) ;;
		"Chamorro Standard Time" ) TZFiles=( "Pacific/Guam" "Pacific/Saipan" ) ;;
		"Chile Time" ) TZFiles=( "America/Santiago" ) ;;
		"China Standard Time" ) TZFiles=( "Asia/Chongqing" "Asia/Harbin" "Asia/Kashgar" "Asia/Macau" "Asia/Shanghai" "Asia/Urumqi" ) ;;
		"Christmas Island Time" ) TZFiles=( "Indian/Christmas" ) ;;
		"Cocos Islands Time" ) TZFiles=( "Indian/Cocos" ) ;;
		"Colombia Time" ) TZFiles=( "America/Bogota" ) ;;
		"Cook Islands Time" ) TZFiles=( "Pacific/Rarotonga" ) ;;
		"Cuba Standard Time" ) TZFiles=( "America/Havana" ) ;;
		"East Africa Time" ) TZFiles=( "Africa/Addis_Ababa" "Africa/Asmara" "Africa/Asmera" "Africa/Dar_es_Salaam" "Africa/Djibouti" "Africa/Kampala" "Africa/Khartoum" "Africa/Mogadishu" "Africa/Nairobi" "Indian/Antananarivo" "Indian/Comoro" "Indian/Mayotte" ) ;;
		"East Kazakhstan Standard Time" ) TZFiles=( "Asia/Almaty" "Asia/Qyzylorda" ) ;;
		"East Timor Time" ) TZFiles=( "Asia/Dili" ) ;;
		"Eastern European Time" ) TZFiles=( "Africa/Cairo" "Africa/Tripoli" "Asia/Amman" "Asia/Beirut" "Asia/Damascus" "Asia/Gaza" "Asia/Nicosia" "Europe/Athens" "Europe/Bucharest" "Europe/Chisinau" "Europe/Helsinki" "Europe/Istanbul" "Europe/Kiev" "Europe/Riga" "Europe/Simferopol" "Europe/Sofia" "Europe/Tallinn" "Europe/Uzhgorod" "Europe/Vilnius" "Europe/Zaporozhye" ) ; if [ ${TargetOSMinor} -eq 6 ] ; then TZFiles=( "${TZFiles[@]}" "Europe/Kaliningrad" "Europe/Minsk" ) ; fi ;;
		"Eastern Indonesia Time" ) TZFiles=( "Asia/Jayapura" ) ;;
		"Eastern Standard Time" ) TZFiles=( "America/Cayman" "America/Detroit" "America/Grand_Turk" "America/Indiana/Indianapolis" "America/Indiana/Vincennes" "America/Indianapolis" "America/Jamaica" "America/Kentucky/Louisville" "America/Kentucky/Monticello" "America/Montreal" "America/Nassau" "America/New_York" "America/Nipigon" "America/Panama" "America/Port-au-Prince" "America/Thunder_Bay" "America/Toronto" "Canada/Eastern" "US/Eastern" ) ;;
		"Ecuador Time" ) TZFiles=( "America/Guayaquil" ) ;;
		"Falkland Islands Time" ) TZFiles=( "Atlantic/Stanley" ) ;;
		"Fernando de Noronha Time" ) TZFiles=( "America/Noronha" ) ;;
		"Fiji Time" ) TZFiles=( "Pacific/Fiji" ) ;;
		"French Guiana Time" ) TZFiles=( "America/Cayenne" ) ;;
		"French Southern and Antarctic Time" ) TZFiles=( "Indian/Kerguelen" ) ;;
		"Georgia Time" ) TZFiles=( "Asia/Tbilisi" ) ;;
		"Gilbert Islands Time" ) TZFiles=( "Pacific/Tarawa" ) ;;
		"GMT-03:00" ) TZFiles=( "America/Argentina/San_Luis" ) ;;
		"GMT+00:00" ) TZFiles=( "UTC" ) ;;
		"GMT+03:00" ) TZFiles=( "Europe/Kaliningrad" "Europe/Minsk" ) ;;
		"GMT+07:00" ) TZFiles=( "Asia/Dhaka" ) ;;
		"GMT+08:00" ) TZFiles=( "Asia/Taipei" ) ;;
		"Greenwich Mean Time" ) TZFiles=( "Africa/Abidjan" "Africa/Accra" "Africa/Bamako" "Africa/Banjul" "Africa/Bissau" "Africa/Conakry" "Africa/Dakar" "Africa/Freetown" "Africa/Lome" "Africa/Monrovia" "Africa/Nouakchott" "Africa/Ouagadougou" "Africa/Sao_Tome" "Atlantic/Reykjavik" "Atlantic/St_Helena" "Europe/Dublin" "Europe/Guernsey" "Europe/Isle_of_Man" "Europe/Jersey" "Europe/London" ) ;;
		"Gulf Standard Time" ) TZFiles=( "Asia/Dubai" "Asia/Muscat" ) ;;
		"Guyana Time" ) TZFiles=( "America/Guyana" ) ;;
		"Hawaii-Aleutian Standard Time" ) TZFiles=( "America/Adak" "Pacific/Honolulu" ) ;;
		"Hong Kong Time" ) TZFiles=( "Asia/Hong_Kong" ) ;;
		"India Standard Time" ) TZFiles=( "Asia/Calcutta" "Asia/Colombo" "Asia/Kolkata" ) ;;
		"Indochina Time" ) TZFiles=( "Asia/Bangkok" "Asia/Ho_Chi_Minh" "Asia/Phnom_Penh" "Asia/Saigon" "Asia/Vientiane" ) ;;
		"Iran Standard Time" ) TZFiles=( "Asia/Tehran" ) ;;
		"Irkutsk Time" ) TZFiles=( "Asia/Irkutsk" ) ;;
		"Israel Standard Time" ) TZFiles=( "Asia/Jerusalem" ) ;;
		"Japan Standard Time" ) TZFiles=( "Asia/Tokyo" ) ;;
		"Korean Standard Time" ) TZFiles=( "Asia/Pyongyang" "Asia/Seoul" ) ;;
		"Krasnoyarsk Time" ) TZFiles=( "Asia/Krasnoyarsk" ) ; if [ ${TargetOSMinor} -ne 5 ] ; then TZFiles=( "${TZFiles[@]}" "Asia/Novosibirsk" ) ; fi ;;
		"Kyrgyzstan Time" ) TZFiles=( "Asia/Bishkek" ) ;;
		"Magadan Time" ) TZFiles=( "Asia/Magadan" ) ; if [ ${TargetOSMinor} -eq 7 ] ; then TZFiles=( "${TZFiles[@]}" "Asia/Anadyr" "Asia/Kamchatka" ) ; fi ;;
		"Malaysia Time" ) TZFiles=( "Asia/Kuala_Lumpur" "Asia/Kuching" ) ;;
		"Maldives Time" ) TZFiles=( "Indian/Maldives" ) ;;
		"Marshall Islands Time" ) TZFiles=( "Pacific/Majuro" ) ;;
		"Mauritius Time" ) TZFiles=( "Indian/Mauritius" ) ;;
		"Moscow Standard Time" ) TZFiles=( "Europe/Moscow" ) ; if [ ${TargetOSMinor} -eq 7 ] ; then TZFiles=( "${TZFiles[@]}" "Europe/Samara" ) ; fi ;;
		"Mountain Standard Time" ) TZFiles=( "America/Boise" "America/Chihuahua" "America/Dawson_Creek" "America/Denver" "America/Edmonton" "America/Hermosillo" "America/Mazatlan" "America/Ojinaga" "America/Phoenix" "America/Yellowknife" "Canada/Mountain" "US/Mountain" ) ;;
		"Myanmar Time" ) TZFiles=( "Asia/Rangoon" ) ;;
		"Nauru Time" ) TZFiles=( "Pacific/Nauru" ) ;;
		"Nepal Time" ) TZFiles=( "Asia/Kathmandu" "Asia/Katmandu" ) ;;
		"New Caledonia Time" ) TZFiles=( "Pacific/Noumea" ) ;;
		"New Zealand Standard Time" ) TZFiles=( "Antarctica/McMurdo" "Pacific/Auckland" ) ;;
		"Newfoundland Standard Time" ) TZFiles=( "America/St_Johns" "Canada/Newfoundland" ) ;;
		"Niue Time" ) TZFiles=( "Pacific/Niue" ) ;;
		"Norfolk Islands Time" ) TZFiles=( "Pacific/Norfolk" ) ;;
		"Novosibirsk Time" ) TZFiles=( "Asia/Novokuznetsk" ) ; if [ ${TargetOSMinor} -eq 5 ] ; then TZFiles=( "${TZFiles[@]}" "Asia/Novosibirsk" ) ; fi ;;
		"Omsk Time" ) TZFiles=( "Asia/Omsk" ) ;;
		"Pacific Standard Time" ) TZFiles=( "America/Los_Angeles" "America/Santa_Isabel" "America/Tijuana" "America/Vancouver" "America/Whitehorse" "US/Pacific" ) ;;
		"Pakistan Time" ) TZFiles=( "Asia/Karachi" ) ;;
		"Palau Time" ) TZFiles=( "Pacific/Palau" ) ;;
		"Papua New Guinea Time" ) TZFiles=( "Pacific/Port_Moresby" ) ;;
		"Paraguay Time" ) TZFiles=( "America/Asuncion" ) ;;
		"Peru Time" ) TZFiles=( "America/Lima" ) ;;
		"Petropavlovsk-Kamchatski Time" ) TZFiles=( "Asia/Kamchatka" ) ;;
		"Philippine Time" ) TZFiles=( "Asia/Manila" ) ;;
		"Pierre and Miquelon Standard Time" ) TZFiles=( "America/Miquelon" ) ;;
		"Pitcairn Time" ) TZFiles=( "Pacific/Pitcairn" ) ;;
		"Ponape Time" ) TZFiles=( "Pacific/Pohnpei" "Pacific/Ponape" ) ;;
		"Reunion Time" ) TZFiles=( "Indian/Reunion" ) ;;
		"Sakhalin Time" ) TZFiles=( "Asia/Sakhalin" ) ;;
		"Samara Time" ) TZFiles=( "Europe/Samara" ) ;;
		"Samoa Standard Time" ) TZFiles=( "Pacific/Apia" "Pacific/Pago_Pago" ) ;;
		"Seychelles Time" ) TZFiles=( "Indian/Mahe" ) ;;
		"Singapore Standard Time" ) TZFiles=( "Asia/Singapore" ) ;;
		"Solomon Islands Time" ) TZFiles=( "Pacific/Guadalcanal" ) ;;
		"South Africa Standard Time" ) TZFiles=( "Africa/Johannesburg" "Africa/Maseru" "Africa/Mbabane" ) ;;
		"South Georgia Time" ) TZFiles=( "Atlantic/South_Georgia" ) ;;
		"Suriname Time" ) TZFiles=( "America/Paramaribo" ) ;;
		"Tahiti Time" ) TZFiles=( "Pacific/Tahiti" ) ;;
		"Tajikistan Time" ) TZFiles=( "Asia/Dushanbe" ) ;;
		"Taipei Standard Time" ) TZFiles=( "Asia/Taipei" ) ;;
		"Tonga Time" ) TZFiles=( "Pacific/Tongatapu" ) ;;
		"Turkmenistan Time" ) TZFiles=( "Asia/Ashgabat" ) ;;
		"Tuvalu Time" ) TZFiles=( "Pacific/Funafuti" ) ;;
		"Ulan Bator Time" ) TZFiles=( "Asia/Ulaanbaatar" ) ;;
		"Uruguay Time" ) TZFiles=( "America/Montevideo" ) ;;
		"Uzbekistan Time" ) TZFiles=( "Asia/Samarkand" "Asia/Tashkent" ) ;;
		"Vanuatu Time" ) TZFiles=( "Pacific/Efate" ) ;;
		"Venezuela Time" ) TZFiles=( "America/Caracas" ) ;;
		"Vladivostok Time" ) TZFiles=( "Asia/Vladivostok" ) ;;
		"Volgograd Time" ) TZFiles=( "Europe/Volgograd" ) ;;
		"Wallis and Futuna Time" ) TZFiles=( "Pacific/Wallis" ) ;;
		"West Africa Time" ) TZFiles=( "Africa/Bangui" "Africa/Brazzaville" "Africa/Douala" "Africa/Kinshasa" "Africa/Lagos" "Africa/Libreville" "Africa/Luanda" "Africa/Malabo" "Africa/Ndjamena" "Africa/Niamey" "Africa/Porto-Novo" "Africa/Windhoek" ) ;;
		"West Greenland Time" ) TZFiles=( "America/Godthab" ) ;;
		"West Kazakhstan Standard Time" ) TZFiles=( "Asia/Aqtau" "Asia/Aqtobe" "Asia/Oral" ) ;;
		"Western European Time" ) TZFiles=( "Africa/Casablanca" "Africa/El_Aaiun" "Atlantic/Canary" "Atlantic/Faroe" "Atlantic/Madeira" "Europe/Lisbon" ) ;;
		"Western Indonesia Time" ) TZFiles=( "Asia/Jakarta" "Asia/Pontianak" ) ;;
		"Yakutsk Time" ) TZFiles=( "Asia/Yakutsk" ) ;;
		"Yekaterinburg Time" ) TZFiles=( "Asia/Yekaterinburg" ) ;;
	esac
}

function set_TZCountries {
	unset ZCODES[@]
	unset ZNAMES[@]
	unset TZCountries[@]
	if [ ${UseGeoKit} -eq 0 ] ; then
		for TZFILE in "${TZFiles[@]}" ; do
			i=0 ; for Item in "${all_cities_adj_3[@]}" ; do
				j=0
				if [ "${TZFILE}" == "${Item}" ] ; then j=1 ; fi
				for CODE in "${ZCODES[@]}" ; do
					if [ "${CODE}" == "${all_cities_adj_4[i]}" ] ; then j=0 ; break ; fi
				done
				if [ ${j} -eq 1 ] ; then ZCODES=( "${ZCODES[@]}" "${all_cities_adj_4[i]}" ) ; fi
				let i++
			done
		done
	else
		for TZFILE in "${TZFiles[@]}" ; do
			Query="select distinct ZCOUNTRY from ${PLACES} where ZTIMEZONENAME = '${TZFILE}';"
			ZCOUNTRYS=( `sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null` )
			for ZCOUNTRY in "${ZCOUNTRYS[@]}" ; do
				j=1
				Query="select ZCODE from ${PLACES} where Z_PK = ${ZCOUNTRY};"
				ZCODE=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
				for CODE in "${ZCODES[@]}" ; do
					if [ "${ZCODE}" == "${CODE}" ] ; then j=0 ; break ; fi
				done
				if [ ${j} -eq 1 ] ; then ZCODES=( "${ZCODES[@]}" "${ZCODE}" ) ; fi
			done
		done
	fi
	IFS=$'\n'
	for ZCODE in "${ZCODES[@]}" ; do
		ZNAMES=( "${ZNAMES[@]}" $(set_TZCountry "${ZCODE}") )
	done
	TZCountries=( `for ZNAME in "${ZNAMES[@]}" ; do echo "${ZNAME}" ; done | sort -u` )
	unset IFS
}

function set_ClosestCities {
	# ${1}: TZCountryCode
	unset ZGEONAMEIDS[@]
	unset ZNAMES[@]
	unset ClosestCities[@]
	display_Title
	printf "\nCreating list of Cities ...  "
	s=1
	if [ ${UseGeoKit} -eq 0 ] ; then
		for TZFILE in "${TZFiles[@]}" ; do
			j=0
			i=0 ; for Item in "${all_cities_adj_3[@]}" ; do
				if [ "${TZFILE}" == "${Item}" ] ; then
					if [ "${1}" == "${all_cities_adj_4[i]}" ] ; then j=1 ; break ; fi
				fi
				printf "\b${spin:s++%${#spin}:1}"
				let i++
			done
			if [ ${j} -eq 1 ] ; then ZGEONAMEIDS=( ${ZGEONAMEIDS[@]} ${all_cities_adj_7[i]} ) ; fi
		done
	else
		Query="select Z_PK from ${PLACES} where ZCODE = '${1}';"
		ZCOUNTRY=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		for TZFILE in "${TZFiles[@]}" ; do
			Query="select ZGEONAMEID from ${PLACES} where ZCOUNTRY = ${ZCOUNTRY} AND ZTIMEZONENAME = '${TZFILE}';"
			ZGEONAMEIDS=( ${ZGEONAMEIDS[@]} `sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null` )
			printf "\b${spin:s++%${#spin}:1}"
		done
	fi
	IFS=$'\n'
	for ZGEONAMEID in ${ZGEONAMEIDS[@]} ; do
		ZNAMES=( "${ZNAMES[@]}" "$(set_ClosestCity ${ZGEONAMEID})" )
		printf "\b${spin:s++%${#spin}:1}"
	done
	ClosestCities=( `for ZNAME in "${ZNAMES[@]}" ; do echo "${ZNAME}" ; done | sort -u` )
	unset IFS
	printf "\bdone\n"
}

# Section: Remote Login

# Section: Remote Management

# Section: Runtime

function display_Language {
	printf "Language:		"
	if [ -n "${Language}" ] ; then printf "${Language}" ; else printf "-" ; fi
	printf "\n"
	# echo "Begin: Debug Output"
	# echo "Language Code:		${LanguageCode}"
	# echo "AppleLanguages:		${AppleLanguages[@]}"
	# echo "End: Debug Output"
	printf "\n"
}

function select_Language {
	display_Subtitle "Select Language"
	display_Language
	display_Options "Languages" "Select the language you wish to use: "
	select Language in "${Languages[@]}" ; do
		if [ -n "${Language}" ] ; then break ; fi
	done
	set_LanguageCode "${Language}"
	set_Localization "${Language}"
#	set_LanguageCountryCodes "${LanguageCode}"
}

function display_CountryName {
	printf "Country:		"
	if [ -n "${SACountry}" ] ; then printf "${SACountry}" ; else printf "-" ; fi
	printf "\n"
	# echo "Begin: Debug Output"
	# echo "Country Code:		${SACountryCode}"
	# echo "Language Country Codes:	${LanguageCountryCodes[@]}"
	# echo "Other Country Codes:	${OtherCountryCodes[@]}"
	# echo "End: Debug Output"
	printf "\n"
}

function select_Country {
	set_LanguageCountryCodes "${LanguageCode}"
	set_LanguageCountryNames
	unset OtherCountryCodes[@]
	unset OtherCountryNames[@]
	CountryNames=( "Show All" "${LanguageCountryNames[@]}" )
	display_Subtitle "Select Country"
	display_CountryName
	display_Options "Countries" "Select the country or region you wish to use: "
	select Country in "${CountryNames[@]}" ; do
		while [ "${Country}" == "Show All" ] ; do
			set_OtherCountryCodes
			set_OtherCountryNames
			CountryNames=( "${LanguageCountryNames[@]}" "${OtherCountryNames[@]}" )
			display_Subtitle "Select Country"
			display_CountryName
			display_Options "Countries" "Select the country or region you wish to use: "
			select Country in "${CountryNames[@]}" ; do
				if [ -n "${Country}" ] ; then break ; fi
			done
		done
		if [ -n "${Country}" ] ; then break ; fi
	done
	SACountry="${Country}"
	set_SACountryCode "${SACountry}"
}

function display_Keyboard {
	printf "Keyboard Layout:	"
	if [ -n "${SAKeyboard}" ] ; then printf "${SAKeyboard}" ; else printf "-" ; fi
	printf "\n"
	if [ ${#TypingStyles[@]} -gt 0 ] ; then
		printf "Preferred typing style:	"
		if [ -n "${SATypingStyle}" ] ; then printf "${SATypingStyle}" ; else printf "-" ; fi
		printf "\n"
	fi
	printf "\n"
}

function select_Keyboard {
	set_AllKeyboards
	set_CurrentKeyboards "${LanguageCode}" "${SACountryCode}"
	Keyboards=( "Show All" "${CurrentKeyboards[@]}" )
	display_Subtitle "Select Keyboard"
	display_Keyboard
	display_Options "Keyboard layouts" "Choose a keyboard layout: "
	select Keyboard in "${Keyboards[@]}" ; do
		while [ "${Keyboard}" == "Show All" ] ; do
			set_OtherKeyboards
			Keyboards=( "${CurrentKeyboards[@]}" "${OtherKeyboards[@]}" )
			display_Subtitle "Select Keyboard"
			display_Keyboard
			display_Options "Keyboard layouts" "Choose a keyboard layout: "
			select Keyboard in "${Keyboards[@]}" ; do
				if [ -n "${Keyboard}" ] ; then break ; fi
			done
		done
		if [ -n "${Keyboard}" ] ; then break ; fi
	done
	if [ "${Keyboard}" != "${SAKeyboard}" ] ; then unset SATypingStyle ; set_TypingStyles "${Keyboard}" ; fi
	SAKeyboard="${Keyboard}"
	if [ ${#TypingStyles[@]} -gt 0 ] ; then
		display_Subtitle "Select Keyboard"
		display_Keyboard
		display_Options "Typing styles" "Which typing style do you prefer? "
		select TypingStyle in "${TypingStyles[@]}" ; do
			if [ -n "${TypingStyle}" ] ; then break ; fi
		done
		SATypingStyle="${TypingStyle}"
	fi
	set_InputSourceID "${SAKeyboard}" "${SATypingStyle}"
}

function display_NTPSettings {
	printf "Network Time Server:	"
	if [ -n "${NTPServerName}" ] ; then printf "${NTPServerName}" ; else printf "-" ; fi
	printf "\n"
	printf "			["
	if [ ${NTPEnabled} -eq 1 ] ; then printf "*" ; else printf " " ; fi
	printf "] Set date and time automatically\n\n"
}

function select_NTPServer {
	set_NTPServerNames
	NTPServerNames=( "${NTPServerNames[@]}" "Other..." )
	display_Subtitle "Date and Time"
	display_NTPSettings
	display_Options "NTP Servers" "Select your network time server: "
	select ServerName in "${NTPServerNames[@]}" ; do
		while [ "${ServerName}" == "Other..." ] ; do
			display_Subtitle "Date and Time"
			display_NTPSettings
			echo
			printf "\nNetwork time server (${NTPServer}): "
			read ServerName
			if [ -z "${ServerName}" ] ; then ServerName="${NTPServer}" ; fi
		done
		if [ -n "${ServerName}" ] ; then break ; fi
	done
	set_NTPServerName "${ServerName}"
	set_NTPServer "${NTPServerName}"
	while [ -z "${NTPAuto}" ] ; do
		display_Subtitle "Date and Time"
		display_NTPSettings
		read -sn 1 -p "Set date and time automatically (Y/n)? " NTPAuto < /dev/tty
		echo
		if [ -z "${NTPAuto}" ] ; then NTPAuto="y" ; fi
		case "${NTPAuto}" in
			"Y" | "y" ) echo ; NTPEnabled=1 ;;
			"N" | "n" ) echo ; NTPEnabled=0 ;;
			* ) echo ; unset NTPAuto ;;
		esac
	done
	unset NTPAuto
}

function display_TimeZone {
	printf "Time Zone:		"
	if [ -n "${TimeZone}" ] ; then printf "${TimeZone}" ; else printf "-" ; fi
	printf "\n"
	printf "Closest City:		"
	if [ -n "${ClosestCity}" ] ; then
		printf "${ClosestCity}"
		if [ -n "${TZCountry}" ] ; then printf " - ${TZCountry}" ; fi
	else
		printf "-"
	fi
	printf "\n"
	printf "			["
	if [ ${TZAuto} -eq 1 ] ; then
		printf "*"
	else
		printf " "
	fi
	printf "] Set time zone automatically using current location\n"
	printf "\n"
}

function select_TZCountry {
	unset TZCountry
	unset ClosestCity
	display_Subtitle "Select Time Zone"
	display_TimeZone
	display_Options "Countries" "Select the country or region: "
	select TZCountry in "${TZCountries[@]}" ; do
		if [ -n "${TZCountry}" ] ; then break ; fi
	done
}

function select_ClosestCity {
	unset ClosestCity
	display_Subtitle "Select Time Zone"
	display_TimeZone
	display_Options "Cities" "Select the closest city: "
	select ClosestCity in "${ClosestCities[@]}" ; do
		if [ -n "${ClosestCity}" ] ; then break ; fi
	done
}

function select_TimeZone {
	set_CountryTimeZones "${SACountryCode}"
	TimeZones=( "Show All" "${CountryTimeZones[@]}" )
	display_Subtitle "Select Time Zone"
	display_TimeZone
	display_Options "Time zones" "Select your Time Zone: "
	select Zone in "${TimeZones[@]}" ; do
		while [ "${Zone}" == "Show All" ] ; do
			set_OtherTimeZones
			TimeZones=( "${CountryTimeZones[@]}" "${OtherTimeZones[@]}" )
			display_Subtitle "Select Time Zone"
			display_TimeZone
			display_Options "Time zones" "Select your Time Zone: "
			select Zone in "${TimeZones[@]}" ; do
				if [ -n "${Zone}" ] ; then break ; fi
			done
		done
		if [ -n "${Zone}" ] ; then break ; fi
	done
	TimeZone="${Zone}"
	set_TZFiles "${TimeZone}"
	set_TZCountries
	if [ ${#TZCountries[@]} -gt 1 ] ; then
		select_TZCountry
	else
		TZCountry="${TZCountries[0]}"
	fi
	i=0 ; for ZNAME in "${ZNAMES[@]}" ; do
		if [ "${TZCountry}" == "${ZNAME}" ] ; then TZCountryCode="${ZCODES[i]}" ; break ; fi
		let i++
	done
	set_ClosestCities "${TZCountryCode}"
	if [ ${#ClosestCities[@]} -gt 1 ] ; then
		select_ClosestCity
	else
		ClosestCity="${ClosestCities[0]}"
	fi
	i=0 ; for ZNAME in "${ZNAMES[@]}" ; do
		if [ "${ClosestCity}" == "${ZNAME}" ] ; then GeonameID=${ZGEONAMEIDS[i]} ; break ; fi
		let i++
	done
	while [ -z "${AutoTZ}" ] ; do
		display_Subtitle "Select Time Zone"
		display_TimeZone
		read -sn 1 -p "Set time zone automatically using current location (Y/n)? " AutoTZ < /dev/tty
		if [ -z "${AutoTZ}" ] ; then AutoTZ="y" ; fi
		case "${AutoTZ}" in
			"Y" | "y" ) echo ; TZAuto=1 ;;
			"N" | "n" ) echo ; TZAuto=0 ;;
			* ) echo ; unset AutoTZ ;;
		esac
	done
	unset AutoTZ
}

function display_RemoteLogin {
	printf "Remote Login:		["
	if [ ${RemoteLogin} -eq 1 ] ; then printf "*" ; else printf " " ; fi
	printf "] Enable users to log in remotely using SSH\n\n"
}

function select_RemoteLogin {
	display_Subtitle "Remote Login"
	display_RemoteLogin
	while [ -z "${EnableSSH}" ] ; do
		read -sn 1 -p "Enable users to log in remotely using SSH (y/N)? " EnableSSH < /dev/tty
		if [ -z "${EnableSSH}" ] ; then EnableSSH="n" ; fi
		case "${EnableSSH}" in
			"Y" | "y" ) echo ; RemoteLogin=1 ;;
			"N" | "n" ) echo ; RemoteLogin=0 ;;
			* ) echo ; unset EnableSSH ;;
		esac
	done
	unset EnableSSH
}

function display_RemoteManagement {
	printf "Remote Management:	["
	if [ ${RemoteManagement} -eq 1 ] ; then printf "*" ; else printf " " ; fi
	printf "] Enable users to manage this computer remotely\n\n"
}

function select_RemoteManagement {
	display_Subtitle "Remote Management"
	display_RemoteManagement
	while [ -z "${EnableARD}" ] ; do
		read -sn 1 -p "Enable users to manage this computer remotely (y/N)? " EnableARD < /dev/tty
		if [ -z "${EnableARD}" ] ; then EnableARD="n" ; fi
		case "${EnableARD}" in
			"Y" | "y" ) echo ; RemoteManagement=1 ;;
			"N" | "n" ) echo ; RemoteManagement=0 ;;
			* ) echo ; unset EnableARD ;;
		esac
	done
	unset EnableARD
}

function display_ComputerName {
	printf "Computer Name:		"
	if [ -n "${ComputerName}" ] ; then printf "${ComputerName}" ; else printf "-" ; fi
	printf "\n\n"
}

function select_ComputerName {
	ComputerNames=( "Do not set" "Model and MAC Address" "Generic using MAC Address" "Serial Number" )
	display_Subtitle "Computer Name"
	display_ComputerName
	display_Options "Naming conventions" "Select the naming convention you wish to use: "
	select newComputerName in "${ComputerNames[@]}" ; do
		if [ -n "${newComputerName}" ] ; then break ; fi
	done
	if [ "${newComputerName}" == "Do not set" ] ; then
		unset ComputerName
	else
		ComputerName="${newComputerName}"
	fi
	unset newComputerName
}

function display_SystemSettings {
	display_Language
	display_CountryName
	display_Keyboard
	display_NTPSettings
	display_TimeZone
	display_RemoteLogin
	display_RemoteManagement
	display_ComputerName
}

function menu_SystemPreferences {
	SystemOptions=( "System Setup Menu" "Language" "Country" "Keyboard" "Network Time Server" "Time Zone" "Remote Login" "Remote Management" "Computer Name" )
	while [ "${Option}" != "System Setup Menu" ] ; do
		display_Subtitle "System Preferences"
		display_SystemSettings
		display_Options "Options" "Select an option: "
		select Option in "${SystemOptions[@]}" ; do
			case "${Option}" in
				"System Setup Menu" ) break ;;
				"Language" ) select_Language ; unset Option ; break ;;
				"Country" ) select_Country ; unset Option ; break ;;
				"Keyboard" ) select_Keyboard ; unset Option ; break ;;
				"Network Time Server" ) select_NTPServer ; unset Option ; break ;;
				"Time Zone" ) select_TimeZone ; unset Option ; break ;;
				"Remote Login" ) select_RemoteLogin ; unset Option ; break ;;
				"Remote Management" ) select_RemoteManagement ; unset Option ; break ;;
				"Computer Name" ) select_ComputerName ; unset Option ; break ;;
			esac
		done
	done
	unset Option
}

# Section: User Accounts

function check_AttributeReserved {
	# ${1}:	Attribute
	# ${2}: Value
	searchResult=`dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -search /Local/Target/Users "${1}" "${2}"`
	if [ -n "${searchResult}" ] ; then
		case "${1}" in
			"RecordName" ) for Element in "${LocalRecordNames[@]}" ; do if [ "${2}" == "${Element}" ] ; then return 1 ; fi ; done ;;
			"RealName" ) for Element in "${LocalRealNames[@]}" ; do if [ "${2}" == "${Element}" ] ; then return 1 ; fi ; done ;;
			"UniqueID" ) for Element in "${LocalUniqueIDs[@]}" ; do if [ ${2} -eq ${Element} ] ; then return 1 ; fi ; done ;;
		esac
		return 0
	fi
	return 1
}

function check_AttributeInUse {
	# ${1}:	Attribute
	# ${2}: Value
	case "${1}" in
		"RecordName" ) for Element in "${RecordNames[@]}" ; do if [ "${2}" == "${Element}" ] ; then return 0 ; fi ; done ;;
		"RealName" ) for Element in "${RealNames[@]}" ; do if [ "${2}" == "${Element}" ] ; then return 0 ; fi ; done ;;
		"UniqueID" ) for Element in "${UniqueIDs[@]}" ; do if [ ${2} -eq ${Element} ] ; then return 0 ; fi ; done ;;
	esac
	return 1
}

function check_AccountTypes {
	if [ ${#AccountTypes[@]} -eq 0 ] ; then return 0 ; fi
	for Element in "${AccountTypes[@]}" ; do
		if [ "${Element}" == "Administrator" ] ; then return 0 ; fi
	done
	if [ ${#AccountTypes[@]} -eq 1 ] ; then
		AccountTypes[0]="Administrator"
	else
		display_Subtitle "Select Administrator"
		display_Users
		display_Options "Users" "Select a user: "
		select RealName in "${RealNames[@]}" ; do
			if [ -n "${RealName}" ] ; then break ; fi
		done
		i=0 ; for Element in "${RealNames[@]}" ; do
			if [ "${Element}" == "${RealName}" ] ; then break ; fi
			let i++
		done
		AccountTypes[i]="Administrator"
	fi
}

function update_RealName {
	# ${1}: RealName
	RealName="${1}"
	j=0
	if check_AttributeReserved "RealName" "${RealName}" ; then
		while [ ${?} -ne 1 ] ; do
			let j++
			check_AttributeReserved "RealName" "${RealName}${j}"
		done
	fi
	if check_AttributeInUse "RealName" "${RealName}" || check_AttributeInUse "RealName" "${RealName}${j}" ; then
		while [ ${?} -ne 1 ] ; do
			let j++
			check_AttributeInUse "RealName" "${RealName}${j}"
		done
	fi
	if check_AttributeReserved "RealName" "${RealName}" || check_AttributeInUse "RealName" "${RealName}" ; then
		RealName="${RealName}${j}"
	fi
}

function check_RealName {
	# ${1}:	RealName
	if check_AttributeReserved "RealName" "${1}" ; then
		update_RealName "${1}"
		printf "\n\033[1mThe name you entered is reserved.\033[m\nPlease enter a different name.\n"
		return 0
	fi
	if check_AttributeInUse "RealName" "${1}" ; then
		update_RealName "${1}"
		printf "\n\033[1mThe name you entered can't be used.\033[m\nThis name is not available. Please enter a different name.\n"
		return 0
	fi
	return 1
}

function update_RecordName {
	# ${1}: RealName or RecordName
	RecordName=`echo "${1}" | tr "[:upper:]" "[:lower:]" | tr "[=à=]" "a" | tr "[=á=]" "a" | tr "[=å=]" "a" | tr "[=ä=]" "a" | tr "[=â=]" "a" | tr "[=ã=]" "a" | tr "[=ç=]" "c" | tr "[=è=]" "e" | tr "[=é=]" "e" | tr "[=ë=]" "e" | tr "[=ê=]" "e" | tr "[=ì=]" "i" | tr "[=í=]" "i" | tr "[=ï=]" "i" | tr "[=î=]" "i" | tr "[=ñ=]" "n" | tr "[=ò=]" "o" | tr "[=ó=]" "o" | tr "[=ö=]" "o" | tr "[=ô=]" "o" | tr "[=õ=]" "o" | tr "[=ù=]" "u" | tr "[=ú=]" "u" | tr "[=ü=]" "u" | tr "[=û=]" "u" | tr "[=ÿ=]" "y"`
	RecordName="${RecordName//[^a-zA-Z0-9_.-]/}"
	i=0
	if check_AttributeReserved "RecordName" "${RecordName}" ; then
		while [ ${?} -ne 1 ] ; do
			let i++
			check_AttributeReserved "RecordName" "${RecordName}${i}"
		done
	fi
	if check_AttributeInUse "RecordName" "${RecordName}" || check_AttributeInUse "RecordName" "${RecordName}${i}" ; then
		while [ ${?} -ne 1 ] ; do
			let i++
			check_AttributeInUse "RecordName" "${RecordName}${i}"
		done
	fi
	if check_AttributeReserved "RecordName" "${RecordName}" || check_AttributeInUse "RecordName" "${RecordName}" ; then
		RecordName="${RecordName}${i}"
	fi
}

function check_RecordName {
	# ${1}: RecordName
	badChars="${1//[-a-zA-Z0-9_.-]/}"
	if [ -n "${badChars}" ] ; then
		update_RecordName "${1}"
		printf "\n\033[1mThe short name you entered can't be used.\033[m\nTry using a short name with fewer characters, or with no punctuation marks. Please enter a different name.\n"
		return 0
	fi
	if check_AttributeReserved "RecordName" "${1}" ; then
		update_RecordName "${1}"
		printf "\n\033[1mThe short name you entered is reserved.\033[m\nPlease enter a different short name.\n"
		return 0
	fi
	if check_AttributeInUse "RecordName" "${1}" ; then
		update_RecordName "${1}"
		printf "\n\033[1mThe short name you entered can't be used.\033[m\nThis short name is not available. Please enter a different name.\n"
		return 0
	fi
	return 1
}

function check_Password {
	# ${1}: Password
	# ${2}: Verification
	if [ "${1}" != "${2}" ] ; then
		printf "\n\033[1mThe passwords do not match.\033[m\nPlease re-enter your password."
		return 0
	fi
	return 1
}

function check_AuthenticationHint {
	# ${1}: AuthenticationHint
	# ${2}: Password
	if [ "${1}" == "" ] ; then return 1 ; fi
	if [ "${1}" == "${2}" ] ; then
		printf "\n\033[1mThe hint and the password are the same.\033[m\nThis is a security risk. Please enter a different hint.\n"
		return 0
	fi
	return 1
}

function update_UniqueID {
	# ${1}: UniqueID
	UniqueID="${1//[^0-9]/}"
	if check_AttributeReserved "UniqueID" ${UniqueID} ; then
		while [ ${?} -ne 1 ] ; do
			let UniqueID++
			check_AttributeReserved "UniqueID" ${UniqueID}
		done
	fi
	if check_AttributeInUse "UniqueID" ${UniqueID} ; then
		while [ ${?} -ne 1 ] ; do
			let UniqueID++
			check_AttributeInUse "UniqueID" ${UniqueID}
		done
	fi
}

function check_UniqueID {
	# ${1}: UniqueID
	badChars="${1//[-0-9]/}"
	if [ -n "${badChars}" ] ; then
		update_UniqueID ${1}
		printf "\n\033[1mThe user id you entered can't be used.\033[m\nThe user id may only contain numeric characters. Please enter a different user id.\n"
		return 0
	fi
	if check_AttributeReserved "UniqueID" "${1}" ; then
		update_UniqueID ${1}
		printf "\n\033[1mThe user id you entered is reserved.\033[m\nPlease enter a different user id.\n"
		return 0
	fi
	if check_AttributeInUse "UniqueID" "${1}" ; then
		update_UniqueID ${1}
		printf "\n\033[1mThe user id you entered can't be used.\033[m\nThis user id is not available. Please enter a different user id.\n"
		return 0
	fi
	return 1
}

function update_UserShell {
	if [ "${AccountType}" == "Sharing Only" ] ; then
		UserShell="/usr/bin/false"
	fi
	if [ "${AccountType}" != "Sharing Only" ] && [ "${UserShell}" == "/usr/bin/false" ] ; then
		UserShell="/bin/bash"
	fi
}

function update_NFSHomeDirectory {
	if [ "${AccountType}" == "Sharing Only" ] ; then
		NFSHomeDirectory="/dev/null"
		return 0
	fi
	if [ -z "${UniqueID}" ] ; then
		unset NFSHomeDirectory
		return 0
	fi
	if [ -z "${UniqueID}" ] || [ ${UniqueID} -gt 500 ] ; then
		NFSHomeDirectory="/Users/${RecordName}"
	else
		NFSHomeDirectory="/var/${RecordName}"
	fi
}

function check_NFSHomeDirectory {
	# ${1}:	NFSHomeDirectory
	escapedPath="${1//[\$\(\)\[\]\`\~\?\*\#\\\!\|\'\"]/_}"
	if [ "${1}" != "${escapedPath}" ] ; then
		printf "\n\033[1mThe path \"${1}\" can't be used.\033[m\nTry using a path with no punctuation marks. Please enter a different path.\n"
		return 0
	fi
	relativePath=`echo "${1}" | awk -F "/" '{print $1}'`
	if [ -n "${relativePath}" ] ; then
		printf "\n\033[1mThe path \"${1}\" can't be used.\033[m\nThe path must be absolute. Please enter an absolute path.\n"
		return 0
	fi
	if [ -f "${Target}/${1}" ] ; then
		printf "\n\033[1mThe path \"${1}\" can't be used.\033[m\nThe specified path is to a file. Please enter a different path.\n"
		return 0
	fi
	for Element in "${LocalNFSHomeDirectories[@]}" ; do
		if [ "${1}" == "${Element}" ] ; then return 1 ; fi
	done
	if [ -d "${Target}/${1}" ] ; then
		printf "\n\033[1mThe path \"${1}\" already exists.\033[m\nThe folder will become the home folder for the new account.\n"
		return 1
	fi
	return 1
}

function display_UserAccount {
	printf "Account Type:		"
	if [ -n "${AccountType}" ] ; then printf "${AccountType}" ; else printf "-" ; fi
	printf "\nFull Name:		"
	if [ -n "${RealName}" ] ; then printf "${RealName}" ; else printf "-" ; fi
	printf "\nAccount Name:		"
	if [ -n "${RecordName}" ] ; then printf "${RecordName}" ; else printf "-" ; fi
	printf "\nPassword:		"
	if [ -n "${Password}" ] ; then
		i=0 ; while [ ${i} -lt ${#Password} ] ; do printf "*" ; let i++ ; done
	else
		printf "-"
	fi
	printf "\nPassword Hint:		"
	if [ -n "${AuthenticationHint}" ] ; then printf "${AuthenticationHint}" ; else printf "-" ; fi
	printf "\nUser ID:		"
	if [ -n "${UniqueID}" ] ; then printf "${UniqueID}" ; else printf "-" ; fi
	printf "\nLogin Shell:		"
	if [ -n "${UserShell}" ] ; then printf "${UserShell}" ; else printf "-" ; fi
	printf "\nHome Directory:		"
	if [ -n "${NFSHomeDirectory}" ] ; then printf "${NFSHomeDirectory}" ; else printf "-" ; fi
	printf "\n"
	printf "\n"
}

function select_AccountType {
	UserTypes=( "Administrator" "Standard" "Sharing Only" )
	display_Subtitle "Account Type"
	display_UserAccount
	if [ -n "${AccountType}" ] ; then
		i=0 ; for Element in "${AccountTypes[@]}" ; do
			if [ "${Element}" == "Administrator" ] ; then let i++ ; fi
		done
		if [ ${i} -eq 0 ] && [ "${AccountType}" == "Administrator" ] ; then
			press_anyKey "You must have at least one Administrator account."
			return 0
		fi
	fi
	display_Options "Account types" "Select an account type: "
	select AccountType in "${UserTypes[@]}" ; do
		if [ -n "${AccountType}" ] ; then break ; fi
	done
	update_UserShell
	update_NFSHomeDirectory
}

function set_RealName {
	unset newRealName
	while [ -z "${newRealName}" ] ; do
		display_Subtitle "Full Name"
		display_UserAccount
		printf "Full name" ; if [ -n "${RealName}" ] ; then printf " (${RealName})" ; fi ; printf ": "
		read newRealName
		if [ -z "${newRealName}" ] && [ -n "${RealName}" ] ; then
			if [ "${newRealName}" == "${RealName}" ] ; then
				return 1
			else
				newRealName="${RealName}"
			fi
		fi
		check_RealName "${newRealName}"
		while [ ${?} -ne 1 ] ; do
			printf "\nFull name" ; if [ -n "${RealName}" ] ; then printf " (${RealName})" ; fi ; printf ": "
			read newRealName
			if [ -z "${newRealName}" ] || [ "${newRealName}" == "${RealName}" ] ; then return 1 ; fi
			check_RealName "${newRealName}"
		done
	done
	RealName="${newRealName}"
}

function set_RecordName {
	unset newRecordName
	while [ -z "${newRecordName}" ] ; do
		display_Subtitle "Account Name"
		display_UserAccount
		printf "Account name" ; if [ -n "${RecordName}" ] ; then printf " (${RecordName})" ; fi ; printf ": "
		read newRecordName
		if [ -z "${newRecordName}" ] && [ -n "${RecordName}" ] ; then
			if [ "${newRecordName}" == "${RecordName}" ] ; then
				return 1
			else
				newRecordName="${RecordName}"
			fi
		fi
		check_RecordName "${newRecordName}"
		while [ ${?} -ne 1 ] ; do
			printf "\nAccount name" ; if [ -n "${RecordName}" ] ; then printf " (${RecordName})" ; fi ; printf ": "
			read newRecordName
			if [ -z "${newRecordName}" ] || [ "${newRecordName}" == "${RecordName}" ] ; then return 1 ; fi
			check_RecordName "${newRecordName}"
		done
	done
	RecordName="${newRecordName}"
}

function set_Password {
	display_Subtitle "Password"
	display_UserAccount
	printf "Password: " ; stty -echo ; read Password ; stty echo
	printf "\nVerify: " ; stty -echo ; read Verify ; stty echo
	check_Password "${Password}" "${Verify}"
	while [ ${?} -ne 1 ] ; do
		printf "\nPassword: " ; stty -echo ; read Password ; stty echo
		printf "\nVerify: " ; stty -echo ; read Verify ; stty echo
		check_Password "${Password}" "${Verify}"
	done
}

function set_AuthenticationHint {
	display_Subtitle "Password Hint"
	display_UserAccount
	printf "Password hint: " ; read AuthenticationHint
	check_AuthenticationHint "${AuthenticationHint}" "${Password}"
	while [ ${?} -ne 1 ] ; do
		printf "\nPassword Hint: " ; read AuthenticationHint
		check_AuthenticationHint "${AuthenticationHint}" "${Password}"
	done
}

function set_UniqueID {
	display_Subtitle "User ID"
	display_UserAccount
	printf "User ID" ; if [ -n "${UniqueID}" ] ; then printf " (${UniqueID})" ; fi ; printf ": "
	read newUniqueID
	if [ -z "${newUniqueID}" ] || [ "${newUniqueID}" == "${UniqueID}" ] ; then return 1 ; fi
	check_UniqueID "${newUniqueID}"
	while [ ${?} -ne 1 ] ; do
		printf "\nUser ID" ; if [ -n "${UniqueID}" ] ; then printf " (${UniqueID})" ; fi ; printf ": "
		read newUniqueID
		if [ -z "${newUniqueID}" ] || [ "${newUniqueID}" == "${UniqueID}" ] ; then return 1 ; fi
		check_UniqueID "${newUniqueID}"
	done
	UniqueID="${newUniqueID}"
}

function select_UserShell {
	if [ "${AccountType}" != "Sharing Only" ] ; then
		LoginShells=( "/bin/bash" "/bin/tcsh" "/bin/sh" "/bin/csh" "/bin/zsh" "/bin/ksh" )
		display_Subtitle "Login Shell"
		display_UserAccount
		display_Options "Login shells" "Select a login shell: "
		select UserShell in "${LoginShells[@]}" ; do
			if [ -n "${UserShell}" ] ; then break ; fi
		done
	fi
}

function set_NFSHomeDirectory {
	if [ "${AccountType}" != "Sharing Only" ] ; then
		display_Subtitle "Home Directory"
		display_UserAccount
		printf "Home directory" ; if [ -n "${NFSHomeDirectory}" ] ; then printf " (${NFSHomeDirectory})" ; fi ; printf ": "
		read newNFSHomeDirectory
		if [ -z "${newNFSHomeDirectory}" ] || [ "${newNFSHomeDirectory}" == "${NFSHomeDirectory}" ] ; then return 1 ; fi
		check_NFSHomeDirectory "${newNFSHomeDirectory}"
		while [ ${?} -ne 1 ] ; do
			printf "\nHome directory" ; if [ -n "${NFSHomeDirectory}" ] ; then printf " (${NFSHomeDirectory})" ; fi ; printf ": "
			read newNFSHomeDirectory
			if [ -z "${newNFSHomeDirectory}" ] || [ "${newNFSHomeDirectory}" == "${NFSHomeDirectory}" ] ; then return 1 ; fi
			check_NFSHomeDirectory "${newNFSHomeDirectory}"
		done
		NFSHomeDirectory="${newNFSHomeDirectory}"
	fi
}

function display_Users {
	printf "User Accounts:	"
	if [ -n "${RealNames[0]}" ] ; then printf "${RealNames[0]}" ; else printf "-" ; fi
	printf "\n"
	i=1 ; while [ ${i} -lt ${#RealNames[@]} ] ; do
		printf "		${RealNames[i]}\n"
		let i++
	done
	printf "\n"
}

function menu_AddUser {
	unset AccountType
	unset RealName
	unset RecordName
	unset Password
	unset AuthenticationHint
	unset UniqueID
	unset UserShell
	unset NFSHomeDirectory
	display_Subtitle "Add User"
	display_UserAccount
	if [ ${#AccountTypes[@]} -eq 0 ] ; then
		AccountType="Administrator"
	else
		select_AccountType
	fi
	set_RealName
	update_RecordName "${RealName}"
	update_UniqueID 501
	update_UserShell
	update_NFSHomeDirectory
	set_RecordName
	update_NFSHomeDirectory
	set_Password
	set_AuthenticationHint
	set_UniqueID
	update_NFSHomeDirectory
	select_UserShell
	set_NFSHomeDirectory
	AccountTypes=( "${AccountTypes[@]}" "${AccountType}" )
	RealNames=( "${RealNames[@]}" "${RealName}" )
	RecordNames=( "${RecordNames[@]}" "${RecordName}" )
	Passwords=( "${Passwords[@]}" "${Password}" )
	AuthenticationHints=( "${AuthenticationHints[@]}" "${AuthenticationHint}" )
	UniqueIDs=( ${UniqueIDs[@]} ${UniqueID} )
	UserShells=( "${UserShells[@]}" "${UserShell}" )
	NFSHomeDirectories=( "${NFSHomeDirectories[@]}" "${NFSHomeDirectory}" )
}

function menu_EditUser {
	display_Subtitle "Edit User"
	if [ ${#RealNames[@]} -eq 0 ] ; then
		press_anyKey "No users available, please create a user first."
		return 0
	fi
	display_Users
	display_Options "Users" "Select a user: "
	select RealName in "${RealNames[@]}" ; do
		if [ -n "${RealName}" ] ; then break ; fi
	done
	i=0 ; for Element in "${RealNames[@]}" ; do
		if [ "${Element}" == "${RealName}" ] ; then break ; fi
		let i++
	done
	unset RealNames[i]
	AccountType="${AccountTypes[i]}" ; unset AccountTypes[i]
	RecordName="${RecordNames[i]}" ; unset RecordNames[i]
	Password="${Passwords[i]}" ; unset Passwords[i]
	AuthenticationHints="${AuthenticationHints[i]}" ; unset AuthenticationHints[i]
	UniqueID=${UniqueIDs[i]} ; unset UniqueIDs[i]
	UserShell="${UserShells[i]}" ; unset UserShells[i]
	NFSHomeDirectory="${NFSHomeDirectories[i]}" ; unset NFSHomeDirectories[i]
	UserOptions=( "Users Menu" "Account Type" "Full Name" "Account Name" "Password" "Password Hint" "User ID" "Login shell" "Home Directory" )
	while [ "${Option}" != "Users Menu" ] ; do
		display_Subtitle "Edit User"
		display_UserAccount
		display_Options "Options" "Select an option: "
		select Option in "${UserOptions[@]}" ; do
			case "${Option}" in
				"Users Menu" ) break ;;
				"Account Type" ) select_AccountType ; unset Option ; break ;;
				"Full Name" ) set_RealName ; unset Option ; break ;;
				"Account Name" ) set_RecordName ; unset Option ; break ;;
				"Password" ) set_Password ; unset Option ; break ;;
				"Password Hint" ) set_AuthenticationHint ; unset Option ; break ;;
				"User ID" ) set_UniqueID ; unset Option ; break ;;
				"Login shell" ) select_UserShell ; unset Option ; break ;;
				"Home Directory" ) set_NFSHomeDirectory ; unset Option ; break ;;
			esac
		done
	done
	unset Option
	AccountTypes=( "${AccountTypes[@]}" "${AccountType}" )
	RealNames=( "${RealNames[@]}" "${RealName}" )
	RecordNames=( "${RecordNames[@]}" "${RecordName}" )
	Passwords=( "${Passwords[@]}" "${Password}" )
	AuthenticationHints=( "${AuthenticationHints[@]}" "${AuthenticationHint}" )
	UniqueIDs=( ${UniqueIDs[@]} ${UniqueID} )
	UserShells=( "${UserShells[@]}" "${UserShell}" )
	NFSHomeDirectories=( "${NFSHomeDirectories[@]}" "${NFSHomeDirectory}" )
}

function menu_DeleteUser {
	display_Subtitle "Delete User"
	if [ ${#RealNames[@]} -eq 0 ] ; then
		press_anyKey "No users available, please create a user first."
		return 0
	fi
	display_Users
	display_Options "Users" "Select a user: "
	select RealName in "${RealNames[@]}" ; do
		if [ -n "${RealName}" ] ; then break ; fi
	done
	i=0 ; for Element in "${RealNames[@]}" ; do
		if [ "${Element}" == "${RealName}" ] ; then break ; fi
		let i++
	done
	unset ConfirmDelete
	while [ -z "${ConfirmDelete}" ] ; do
		echo
		read -sn 1 -p "Are you sure you want to delete the user account \"${RealName}\" (Y/n)? " ConfirmDelete < /dev/tty
		if [ -z "${ConfirmDelete}" ] ; then ConfirmDelete="y" ; fi
		echo
		case "${ConfirmDelete}" in
			"Y" | "y" ) unset AccountTypes[i] ; unset RealNames[i] ; unset RecordNames[i] ; unset Passwords[i] ; unset AuthenticationHints[i] ; unset UniqueIDs[i] ; unset UserShells[i] ; unset NFSHomeDirectories[i] ; echo ;;
			"N" | "n" ) echo ;;
			* ) echo ; unset ConfirmDelete ;;
		esac
	done
	unset ConfirmDelete
	unset RealName
	AccountTypes=( "${AccountTypes[@]}" )
	RealNames=( "${RealNames[@]}" )
	RecordNames=( "${RecordNames[@]}" )
	Passwords=( "${Passwords[@]}" )
	AuthenticationHints=( "${AuthenticationHints[@]}" )
	UniqueIDs=( ${UniqueIDs[@]} )
	UserShells=( "${UserShells[@]}" )
	NFSHomeDirectories=( "${NFSHomeDirectories[@]}" )
	check_AccountTypes
}

function menu_Users {
	AccountOptions=( "System Setup Menu" "Add User" "Edit User" "Delete User" )
	while [ "${Option}" != "System Setup Menu" ] ; do
		display_Subtitle "Users"
		display_Users
		display_Options "Options" "Select an option: "
		select Option in "${AccountOptions[@]}" ; do
			case "${Option}" in
				"System Setup Menu" ) break ;;
				"Add User" ) menu_AddUser ; unset Option ; break ;;
				"Edit User" ) menu_EditUser ; unset Option ; break ;;
				"Delete User" ) menu_DeleteUser ; unset Option ; break ;;
			esac
		done
	done
	unset Option
}

# Section: Packages

function detect_AvailablePackages {
	unset AvailablePackages[@]
	IFS=$'\n'
	AvailablePackages=( `find "${PackageFolder}" -name "*pkg" -a \! -path "*pkg/*" -exec basename {} \;` )
	unset IFS
}

function display_Packages {
	printf "Packages:	"
	if [ -n "${Packages[0]}" ] ; then printf "${Packages[0]}" ; else printf "-" ; fi
	printf "\n"
	i=1 ; while [ ${i} -lt ${#Packages[@]} ] ; do
		printf "		${Packages[i]}\n"
		let i++
	done
	printf "\n"
}

function select_Package {
	unset Package
	display_Subtitle "Select Package"
	display_Packages
	detect_AvailablePackages
	i=0 ; for AvailablePackage in "${AvailablePackages[@]}" ; do
		for Element in "${Packages[@]}" ; do
			if [ "${Element}" == "${AvailablePackage}" ] ; then unset AvailablePackages[i] ; break ; fi
		done
		let i++
	done
	if [ ${#AvailablePackages[@]} -eq 0 ] ; then
		press_anyKey "No packages available."
		unset Packages[@]
	else
		display_Options "Packages" "Select a package: "
		select Package in "${AvailablePackages[@]}" ; do
			if [ -n "${Package}" ] ; then break ; fi
		done
		Packages=( "${Packages[@]}" "${Package}" )
	fi
}

function remove_Package {
	unset Package
	display_Subtitle "Remove Package"
	if [ ${#Packages[@]} -eq 0 ] ; then
		press_anyKey "No packages available, please select a package first."
		return 0
	fi
	select Package in "${Packages[@]}" ; do
		if [ -n "${Package}" ] ; then break ; fi
	done
	i=0 ; for Element in "${Packages[@]}" ; do
		if [ "${Element}" == "${Package}" ] ; then unset Packages[i] ; break ; fi
		let i++
	done
	Packages=( "${Packages[@]}" )
}

function menu_Packages {
	PackageOptions=( "System Setup Menu" "Add Package" "Remove Package" )
	while [ "${Option}" != "System Setup Menu" ] ; do
		display_Subtitle "Packages"
		display_Packages
		display_Options "Options" "Select an option: "
		select Option in "${PackageOptions[@]}" ; do
			case "${Option}" in
				"System Setup Menu" ) break ;;
				"Add Package" ) select_Package ; unset Option ; break ;;
				"Remove Package" ) remove_Package ; unset Option ; break ;;
			esac
		done
	done
	unset Option
}

# Section: Remove Software

function detect_RemovableItems {
	unset AvailableRemovableItems[@]
	if [ -e "${Target}/Applications/iPhoto.app" ] ; then AvailableRemovableItems=( "iPhoto" ) ; fi
	if [ -e "${Target}/Applications/iMovie.app" ] ; then AvailableRemovableItems=( "${AvailableRemovableItems[@]}" "iMovie" ) ; fi
	if [ -e "${Target}/Applications/iDVD.app" ] ; then AvailableRemovableItems=( "${AvailableRemovableItems[@]}" "iDVD" ) ; fi
	if [ -e "${Target}/Applications/GarageBand.app" ] ; then AvailableRemovableItems=( "${AvailableRemovableItems[@]}" "GarageBand" ) ; fi
	if [ -e "${Target}/Library/Receipts/iLifeSoundEffects_Loops.pkg" ] || [ -e "${Target}/var/db/receipts/com.apple.pkg.iLifeSoundEffects_Loops.bom" ] ; then AvailableRemovableItems=( "${AvailableRemovableItems[@]}" "Sounds & Jingles" ) ; fi
	if [ -e "${Target}/Applications/iWeb.app" ] ; then AvailableRemovableItems=( "${AvailableRemovableItems[@]}" "iWeb" ) ; fi
	i=0 ; for Item in "${AvailableRemovableItems[@]}" ; do
		for Element in "${RemovableItems[@]}" ; do
			if [ "${Item}" == "${Element}" ] ; then unset AvailableRemovableItems[i] ; break ; fi
		done
		let i++
	done
	AvailableRemovableItems=( "${AvailableRemovableItems[@]}" )
}

function display_RemovableItems {
	printf "Remove:		"
	if [ -n "${RemovableItems[0]}" ] ; then printf "${RemovableItems[0]}" ; else printf "-" ; fi
	printf "\n"
	i=1 ; while [ ${i} -lt ${#RemovableItems[@]} ] ; do
		printf "		${RemovableItems[i]}\n"
		let i++
	done
	printf "\n"
}

function select_Removable {
	unset Removable
	display_Subtitle "Select Software to Remove"
	display_RemovableItems
	detect_RemovableItems
	if [ ${#AvailableRemovableItems[@]} -eq 0 ] ; then
		press_anyKey "No software available to remove."
	else
		if [ ${#AvailableRemovableItems[@]} -gt 1 ] ; then
			AvailableRemovableItems=( "Select All" "${AvailableRemovableItems[@]}" )
		fi
		display_Options "Software" "Select software to remove: "
		select Removable in "${AvailableRemovableItems[@]}" ; do
			if [ -n "${Removable}" ] ; then break ; fi
		done
		if [ "${Removable}" == "Select All" ] ; then
			unset AvailableRemovableItems[0]
			RemovableItems=( "${RemovableItems[@]}" "${AvailableRemovableItems[@]}" )
		else
			RemovableItems=( "${RemovableItems[@]}" "${Removable}" )
		fi
	fi
}

function deselect_Removable {
	unset Removable
	display_Subtitle "De-select Software to Remove"
	if [ ${#RemovableItems[@]} -eq 0 ] ; then
		press_anyKey "No software selected for removal."
		return 0
	fi
	if [ ${#RemovableItems[@]} -gt 1 ] ; then
		SelectedRemovableItems=( "Select All" "${RemovableItems[@]}" )
	else
		SelectedRemovableItems=( "${RemovableItems[@]}" )
	fi
	select Removable in "${SelectedRemovableItems[@]}" ; do
		if [ -n "${Removable}" ] ; then break ; fi
	done
	if [ "${Removable}" == "Select All" ] ; then
		unset RemovableItems[@]
	else
		i=0 ; for Element in "${RemovableItems[@]}" ; do
			if [ "${Element}" == "${Removable}" ] ; then unset RemovableItems[i] ; break ; fi
			let i++
		done
		RemovableItems=( "${RemovableItems[@]}" )
	fi
}

function menu_RemoveSoftware {
	RemoveOptions=( "System Setup Menu" "Select Item" "De-select Item" )
	while [ "${Option}" != "System Setup Menu" ] ; do
		display_Subtitle "Remove Software"
		display_RemovableItems
		display_Options "Options" "Select an option: "
		select Option in "${RemoveOptions[@]}" ; do
			case "${Option}" in
				"System Setup Menu" ) break ;;
				"Select Item" ) select_Removable ; unset Option ; break ;;
				"De-select Item" ) deselect_Removable ; unset Option ; break ;;
			esac
		done
	done
	unset Option
}

# Section: Configurations

function get_Configurations {
	unset Configurations[@]
	IFS=$'\n'
	Configurations=( `find "${ConfigurationFolder}" -name "*.plist" -exec basename {} \; | awk -F ".plist" '{print $1}'` )
	unset IFS
}

function new_Configuration {
	Language="English"
	refresh_Language
	SACountryCode="US"
	refresh_Country
	InputSourceID="US"
	refresh_Keyboard
	NTPServer="time.apple.com"
	set_NTPServerName "${NTPServer}"
	NTPEnabled=1
	GeonameID=5341145
	refresh_GeonameID
	TZAuto=0
	RemoteLogin=0
	RemoteManagement=0
	unset UserWarnings[@]
	unset AccountTypes[@]
	unset RealNames[@]
	unset RecordNames[@]
	unset Passwords[@]
	unset AuthenticationHints[@]
	unset UniqueIDs[@]
	unset UserShells[@]
	unset NFSHomeDirectories[@]
	unset Packages[@]
}

function load_Configuration {
	display_Subtitle "Load Configuration"
	get_Configurations
	if [ ${#Configurations[@]} -eq 0 ] ; then
		press_anyKey "No configurations available, please create a configuration first."
		return 0
	fi
	display_Options "Configurations" "Select a configuration: "
	select Configuration in "${Configurations[@]}" ; do
		if [ -n "${Configuration}" ] ; then break ; fi
	done
	Language=`defaults read "${ConfigurationFolder}/${Configuration}" "Language" 2>/dev/null`
	refresh_Language
	SACountryCode=`defaults read "${ConfigurationFolder}/${Configuration}" "SACountryCode" 2>/dev/null`
	refresh_Country
	InputSourceID=`defaults read "${ConfigurationFolder}/${Configuration}" "InputSourceID" 2>/dev/null`
	refresh_Keyboard
	NTPEnabled=`defaults read "${ConfigurationFolder}/${Configuration}" "NTPEnabled" 2>/dev/null`
	if [ -z "${NTPEnabled}" ] ; then NTPEnabled=1 ; fi
	NTPServer=`defaults read "${ConfigurationFolder}/${Configuration}" "NTPServer" 2>/dev/null`
	if [ -z "${NTPServer}" ] ; then NTPServer="time.apple.com" ; fi
	set_NTPServerName "${NTPServer}"
	GeonameID=`defaults read "${ConfigurationFolder}/${Configuration}" "GeonameID" 2>/dev/null`
	TZAuto=`defaults read "${ConfigurationFolder}/${Configuration}" "TZAuto" 2>/dev/null`
	if [ -z "${TZAuto}" ] ; then TZAuto=0 ; fi
	refresh_GeonameID
	RemoteLogin=`defaults read "${ConfigurationFolder}/${Configuration}" "RemoteLogin" 2>/dev/null`
	if [ ${?} -ne 0 ] ; then RemoteLogin=0 ; fi
	RemoteManagement=`defaults read "${ConfigurationFolder}/${Configuration}" "RemoteManagement" 2>/dev/null`
	if [ ${?} -ne 0 ] ; then RemoteManagement=0 ; fi
	ComputerName=`defaults read "${ConfigurationFolder}/${Configuration}" "ComputerName" 2>/dev/null`
	if [ ${?} -ne 0 ] ; then unset ComputerName ; fi
	unset UserWarnings[@]
	unset AccountTypes[@]
	unset RealNames[@]
	unset RecordNames[@]
	unset Passwords[@]
	unset AuthenticationHints[@]
	unset UniqueIDs[@]
	unset UserShells[@]
	unset NFSHomeDirectories[@]
	i=0 ; while : ; do
		AccountType=`/usr/libexec/PlistBuddy -c "Print :Users:${i}:type" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		if [ ${?} -ne 0 ] ; then break ; fi
		UserWarnings[i]=0
		AccountTypes[i]="${AccountType}"
		realname=`/usr/libexec/PlistBuddy -c "Print :Users:${i}:realname" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		update_RealName "${realname}"
		if [ "${realname}" != "${RealName}" ] ; then UserWarnings[i]=1 ; fi
		RealNames[i]="${RealName}"
		name=`/usr/libexec/PlistBuddy -c "Print :Users:${i}:name" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		update_RecordName "${name}"
		if [ "${name}" != "${RecordName}" ] ; then UserWarnings[i]=1 ; fi
		RecordNames[i]="${RecordName}"
		Passwords[i]=`/usr/libexec/PlistBuddy -c "Print :Users:${i}:passwd" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		AuthenticationHints[i]=`/usr/libexec/PlistBuddy -c "Print :Users:${i}:hint" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		uid=`/usr/libexec/PlistBuddy -c "Print :Users:${i}:uid" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		update_UniqueID "${uid}"
		if [ ${uid} -ne ${UniqueID} ] ; then UserWarnings[i]=1 ; fi
		UniqueIDs[i]=${UniqueID}
		UserShells[i]=`/usr/libexec/PlistBuddy -c "Print :Users:${i}:shell" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		NFSHomeDirectories[i]=`/usr/libexec/PlistBuddy -c "Print :Users:${i}:home" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		let i++
	done
	unset Packages[@]
	i=0 ; while : ; do
		Package=`/usr/libexec/PlistBuddy -c "Print :Packages:${i}" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		if [ ${?} -ne 0 ] ; then break ; fi
		Packages[i]="${Package}"
		let i++
	done
	unset RemovableItems[@]
	i=0 ; while : ; do
		RemovableItem=`/usr/libexec/PlistBuddy -c "Print :RemovableItems:${i}" "${ConfigurationFolder}/${Configuration}.plist" 2>/dev/null`
		if [ ${?} -ne 0 ] ; then break ; fi
		RemovableItems[i]="${RemovableItem}"
		let i++
	done
}

function save_Configuration {
	unset ConfigurationName
	unset Overwrite
	display_Subtitle "Save Configuration"
	while [ -z "${ConfigurationName}" ] ; do
		printf "Configuration name" ; if [ -n "${Configuration}" ] ; then printf " (${Configuration})" ; fi ; printf ": "
		read ConfigurationName
		if [ -z "${ConfigurationName}" ] ; then ConfigurationName="${Configuration}" ; fi
	done
	if [ "${ConfigurationName}" != "${Configuration}" ] ; then
		while [ -e "${ConfigurationFolder}/${ConfigurationName}.plist" ] ; do
			printf "\nA configuration already exists named \033[1m${ConfigurationName}\033[m.\n"
			read -sn 1 -p "Would you like to overwrite it (y/N)? " Overwrite < /dev/tty ; echo
			if [ -z "${Overwrite}" ] ; then Overwrite="n" ; fi
			case "${Overwrite}" in
				"Y" | "y" ) echo ; break ;;
				"N" | "n" ) echo ; return 0 ;;
			esac
		done
	fi
	Configuration="${ConfigurationName}"
	if [ -e "${ConfigurationFolder}/${Configuration}.plist" ] ; then rm "${ConfigurationFolder}/${Configuration}.plist" ; fi
	defaults write "${ConfigurationFolder}/${Configuration}" "Language" -string "${Language}"
	defaults write "${ConfigurationFolder}/${Configuration}" "SACountryCode" -string "${SACountryCode}"
	set_InputSourceID "${SAKeyboard}" "${SATypingStyle}"
	defaults write "${ConfigurationFolder}/${Configuration}" "InputSourceID" -string "${InputSourceID}"
	if [ ${NTPEnabled} -eq 1 ] ;then
		defaults write "${ConfigurationFolder}/${Configuration}" "NTPEnabled" -bool TRUE
	else
		defaults write "${ConfigurationFolder}/${Configuration}" "NTPEnabled" -bool FALSE
	fi
	defaults write "${ConfigurationFolder}/${Configuration}" "NTPServer" -string "${NTPServer}"
	defaults write "${ConfigurationFolder}/${Configuration}" "GeonameID" -int ${GeonameID}
	if [ ${TZAuto} -eq 1 ] ;then
		defaults write "${ConfigurationFolder}/${Configuration}" "TZAuto" -bool TRUE
	else
		defaults write "${ConfigurationFolder}/${Configuration}" "TZAuto" -bool FALSE
	fi
	if [ ${RemoteLogin} -eq 1 ] ;then
		defaults write "${ConfigurationFolder}/${Configuration}" "RemoteLogin" -bool TRUE
	else
		defaults write "${ConfigurationFolder}/${Configuration}" "RemoteLogin" -bool FALSE
	fi
	if [ ${RemoteManagement} -eq 1 ] ;then
		defaults write "${ConfigurationFolder}/${Configuration}" "RemoteManagement" -bool TRUE
	else
		defaults write "${ConfigurationFolder}/${Configuration}" "RemoteManagement" -bool FALSE
	fi
	defaults write "${ConfigurationFolder}/${Configuration}" "ComputerName" -string "${ComputerName}"
	defaults write "${ConfigurationFolder}/${Configuration}" "Users" -array
	i=0 ; for Account in "${AccountTypes[@]}" ; do
		defaults write "${ConfigurationFolder}/${Configuration}" "Users" -array-add "{ \"type\" = \"${AccountTypes[i]}\"; \"realname\" = \"${RealNames[i]}\"; \"name\" = \"${RecordNames[i]}\"; \"passwd\" = \"${Passwords[i]}\"; \"hint\" = \"${AuthenticationHints[i]}\"; \"uid\" = \"${UniqueIDs[i]}\"; \"shell\" = \"${UserShells[i]}\"; \"home\" = \"${NFSHomeDirectories[i]}\"; }"
		let i++
	done
	defaults write "${ConfigurationFolder}/${Configuration}" "Packages" -array "${Packages[@]}"
	defaults write "${ConfigurationFolder}/${Configuration}" "RemovableItems" -array "${RemovableItems[@]}"
}

function menu_Configurations {
	ConfigurationOptions=( "System Setup Menu" "New Configuration" "Load Configuration" "Save Configuration" )
	while [ "${Option}" != "System Setup Menu" ] ; do
		display_Subtitle "Configurations"
		display_Options "Options" "Select an option: "
		select Option in "${ConfigurationOptions[@]}" ; do
			case "${Option}" in
				"System Setup Menu" ) break ;;
				"New Configuration" ) new_Configuration ; unset Option ; return 0 ;;
				"Load Configuration" ) load_Configuration ; unset Option ; return 0 ;;
				"Save Configuration" ) save_Configuration ; unset Option ; return 0 ;;
			esac
		done
	done
}

function apply_Configuration {
	display_Subtitle "Apply Configuration"
	if [ ${TargetType} -eq 0 ] ; then
		press_anyKey "No target selected, please select a target first."
		return 0
	fi
	unset NoUser
	if [ ${#RecordNames[@]} -eq 0 ] ; then
		while [ -z "${NoUser}" ] ; do
			printf "No user accounts have been created.\n"
			read -sn 1 -p "Are you sure you want to proceed (y/N)? " NoUser < /dev/tty
			echo
			if [ -z "${NoUser}" ] ; then NoUser="n" ; fi
			case "${NoUser}" in
				"Y" | "y" ) echo ; break ;;
				"N" | "n" ) return 0 ;;
				* ) unset NoUser ;;
			esac
		done
	fi
	if [ ${TargetType} -eq 2 ] ; then
		if [ -e "${LibraryFolder}/${TargetName}.shadow" ] ; then rm -f "${LibraryFolder}/${TargetName}.shadow" ; fi
		ExportName="${TargetName//.dmg/}"
		if [ -n "${Configuration}" ] ; then ExportName="${ExportName}-${Configuration}" ; fi
		MasterName="${ExportName}.i386.hfs.dmg"
		RecoveryName="${ExportName}.i386.recovery.dmg"
		# Begin: Debug Output
		# echo "TargetName:	${TargetName}"
		# echo "MasterName:	${MasterName}"
		# echo "RecoveryName:	${RecoveryName}"
		# echo
		# End: Debug Output
		unset Overwrite
		if [ -e "${MasterFolder}/${MasterName}" ] ; then
			while [ -z "${Overwrite}" ] ; do
				printf "An image named \033[1m${MasterName}\033[m already exists.\n"
				read -sn 1 -p "Would you like to overwrite it (y/N)? " Overwrite < /dev/tty
				echo
				if [ -z "${Overwrite}" ] ; then Overwrite="n" ; fi
				case "${Overwrite}" in
					"Y" | "y" ) echo ; break ;;
					"N" | "n" ) return 0 ;;
					* ) unset Overwrite ;;
				esac
			done
		fi
		hdiutil eject "${Target}" -force &>/dev/null
		while [ -e "${Target}" ] ; do
			sleep 1
		done
		IFS=$'\n'
		TargetVolumes=( `hdiutil attach -owners on -noverify "${LibraryFolder}/${TargetName}" -shadow | grep "/Volumes/" | awk -F "/Volumes/" '{print $NF}'` )
		unset IFS
		set_Target "${TargetVolumes[0]}"
	fi
	vsdbutil -a "${Target}"
	set_Localization "${Language}"
	set_AppleLanguages "${LanguageCode}"
	printf "Creating:	/Library/Preferences/.GlobalPreferences.plist\n"
	if [ -e "${Target}/Library/Preferences/.GlobalPreferences.plist" ] ; then
		rm -f "${Target}/Library/Preferences/.GlobalPreferences.plist"
	fi
	defaults write "${Target}/Library/Preferences/.GlobalPreferences" "AppleLanguages" -array "${AppleLanguages[@]}"
	if [ ${TargetOSMinor} -gt 5 ] ; then
		defaults write "${Target}/Library/Preferences/.GlobalPreferences" "AppleLocale" -string "${LanguageCode}_${SACountryCode}"
	fi
	defaults write "${Target}/Library/Preferences/.GlobalPreferences" "Country" -string "${SACountryCode}"
	defaults write "${Target}/Library/Preferences/.GlobalPreferences" "com.apple.AppleModemSettingTool.LastCountryCode" -string "${TZCountryCode}"
	if [ ${UseGeoKit} -eq 0 ] ; then
		i=0 ; for Item in "${all_cities_adj_7[@]}" ; do
			if [ "${Item}" == "${GeonameID}" ] ; then break ; fi
			let i++
		done
		defaults write "${Target}/Library/Preferences/.GlobalPreferences" "com.apple.TimeZonePref.Last_Selected_City" -array "${all_cities_adj_0[i]}" "${all_cities_adj_1[i]}" "${all_cities_adj_2[i]}" "${all_cities_adj_3[i]}" "${all_cities_adj_4[i]}" "${all_cities_adj_5[i]}" "${all_cities_adj_6[i]}"
		if [ -d "${TimeZonePrefPane}/Contents/Resources/${Localization}.lproj" ] ; then
			IsPlist=`file "${TimeZonePrefPane}/Contents/Resources/${Localization}.lproj/Localizable_Cities.strings" | grep -vq "property list" ; echo ${?}`
			if [ ${IsPlist} -eq 1 ] ; then
				LocalizedCity=`/usr/libexec/PlistBuddy -c "Print ':${all_cities_adj_5[i]}'" "${TimeZonePrefPane}/Contents/Resources/${Localization}.lproj/Localizable_Cities.strings"`
				LocalizedCountry=`/usr/libexec/PlistBuddy -c "Print ':${all_cities_adj_6[i]}'" "${TimeZonePrefPane}/Contents/Resources/${Localization}.lproj/Localizable_Countries.strings"`
			else
				LocalizedCity=`cat "${TimeZonePrefPane}/Contents/Resources/${Localization}.lproj/Localizable_Cities.strings" | iconv -f UTF-16 -t UTF-8 --unicode-subst="" | grep "\"${all_cities_adj_5[i]}\"" | awk -F "\"" '{print $4}'`
				LocalizedCountry=`cat "${TimeZonePrefPane}/Contents/Resources/${Localization}.lproj/Localizable_Countries.strings" | iconv -f UTF-16 -t UTF-8 --unicode-subst="" | grep "\"${all_cities_adj_6[i]}\"" | awk -F "\"" '{print $4}'`
			fi
		else
			LocalizedCity="${Localizable_Cities[i]}"
			LocalizedCountry="${Localizable_Countries[i]}"
		fi
		defaults write "${Target}/Library/Preferences/.GlobalPreferences" "com.apple.TimeZonePref.Last_Selected_City" -array-add "${LocalizedCity}" "${LocalizedCountry}"
		if [ ${TargetOSMinor} -gt 5 ] ; then
			defaults write "${Target}/Library/Preferences/.GlobalPreferences" "com.apple.TimeZonePref.Last_Selected_City" -array-add "DEPRECATED IN 10.6"
		fi
	else
		Query="select ZLATITUDE from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		ZLATITUDE=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZREGIONALCODE from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		ZREGIONALCODE=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZTIMEZONENAME from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		ZTIMEZONENAME=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZPOPULATION from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		ZPOPULATION=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZLONGITUDE from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		ZLONGITUDE=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZCOUNTRY from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		ZCOUNTRY=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ${PLACES} where Z_PK = ${ZCOUNTRY};"
		ZCOUNTRYNAME=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZCODE from ${PLACES} where Z_PK = ${ZCOUNTRY};"
		ZCODE=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		ZNAME=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select Z_PK from ${PLACES} where ZGEONAMEID = ${GeonameID};"
		Z_PK=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZAR <> 0 and ZPLACE = ${Z_PK};"
		ZAR=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZCA <> 0 and ZPLACE = ${Z_PK};"
		ZCA=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZCS <> 0 and ZPLACE = ${Z_PK};"
		ZCS=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZDA <> 0 and ZPLACE = ${Z_PK};"
		ZDA=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZDE <> 0 and ZPLACE = ${Z_PK};"
		ZDE=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZEL <> 0 and ZPLACE = ${Z_PK};"
		ZEL=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZEN <> 0 and ZPLACE = ${Z_PK};"
		ZEN=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZES <> 0 and ZPLACE = ${Z_PK};"
		ZES=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZFI <> 0 and ZPLACE = ${Z_PK};"
		ZFI=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZFR <> 0 and ZPLACE = ${Z_PK};"
		ZFR=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZHE <> 0 and ZPLACE = ${Z_PK};"
		ZHE=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZHR <> 0 and ZPLACE = ${Z_PK};"
		ZHR=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZHU <> 0 and ZPLACE = ${Z_PK};"
		ZHU=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		# Query="select ZNAME from ZGEOPLACENAME where ZID <> 0 and ZPLACE = ${Z_PK};"
		# ZID=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZIT <> 0 and ZPLACE = ${Z_PK};"
		ZIT=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZJA <> 0 and ZPLACE = ${Z_PK};"
		ZJA=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZKO <> 0 and ZPLACE = ${Z_PK};"
		ZKO=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		# Query="select ZNAME from ZGEOPLACENAME where ZMS <> 0 and ZPLACE = ${Z_PK};"
		# ZMS=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZNL <> 0 and ZPLACE = ${Z_PK};"
		ZNL=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZNO <> 0 and ZPLACE = ${Z_PK};"
		ZNO=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZPL <> 0 and ZPLACE = ${Z_PK};"
		ZPL=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZPT <> 0 and ZPLACE = ${Z_PK};"
		ZPT=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZPT_BR <> 0 and ZPLACE = ${Z_PK};"
		ZPT_BR=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZRO <> 0 and ZPLACE = ${Z_PK};"
		ZRO=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZRU <> 0 and ZPLACE = ${Z_PK};"
		ZRU=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZSK <> 0 and ZPLACE = ${Z_PK};"
		ZSK=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZSV <> 0 and ZPLACE = ${Z_PK};"
		ZSV=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZTH <> 0 and ZPLACE = ${Z_PK};"
		ZTH=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZTR <> 0 and ZPLACE = ${Z_PK};"
		ZTR=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZUK <> 0 and ZPLACE = ${Z_PK};"
		ZUK=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		# Query="select ZNAME from ZGEOPLACENAME where ZVI <> 0 and ZPLACE = ${Z_PK};"
		# ZVI=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZZH <> 0 and ZPLACE = ${Z_PK};"
		ZZH=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		Query="select ZNAME from ZGEOPLACENAME where ZZH_TW <> 0 and ZPLACE = ${Z_PK};"
		ZZH_TW=`sqlite3 "${GeoKitFramework}" "${Query}" 2>/dev/null`
		defaults write "${Target}/Library/Preferences/.GlobalPreferences" "com.apple.TimeZonePref.Last_Selected_City" -array "${ZLATITUDE}" "${ZLONGITUDE}" "0" "${ZTIMEZONENAME}" "${ZCODE}" "${ZNAME}" "${ZCOUNTRYNAME}" "${ZNAME}" "${ZCOUNTRYNAME}" "DEPRECATED IN 10.6"
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city dict" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:CountryCode string ${ZCODE}" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:GeonameID integer ${GeonameID}" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:Latitude real ${ZLATITUDE}" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames dict" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		case ${TargetOSMinor} in
			6 )
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:da string ${ZDA}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:nl string ${ZNL}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ko string ${ZKO}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:zh-Hant string ${ZZH_TW}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ja string ${ZJA}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pt-PT string ${ZPT}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:fr string ${ZFR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:zh-Hans string ${ZZH}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:it string ${ZIT}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:fi string ${ZFI}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:sv string ${ZSV}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pt string ${ZPT_BR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:en string ${ZEN}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ru string ${ZRU}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:es string ${ZES}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pl string ${ZPL}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:de string ${ZDE}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;;
			7 )
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:da string ${ZDA}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:nl string ${ZNL}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ko string ${ZKO}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:zh-Hant string ${ZZH_TW}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ja string ${ZJA}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pt-PT string ${ZPT}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:fr string ${ZFR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:it string ${ZIT}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ru string ${ZRU}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pt string ${ZPT_BR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:fi string ${ZFI}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:zh-Hans string ${ZZH}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:sv string ${ZSV}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:en string ${ZEN}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:es string ${ZES}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pl string ${ZPL}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:de string ${ZDE}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;;
			8 )
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ro string ${ZRO}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:tr string ${ZTR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:es string ${ZES}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:nb string ${ZNO}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ca string ${ZCA}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:el string ${ZEL}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pt-PT string ${ZPT}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:fi string ${ZFI}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:nl string ${ZNL}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:fr string ${ZFR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:sv string ${ZSV}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:hu string ${ZHU}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:cs string ${ZCS}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:he string ${ZHE}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:en string ${ZEN}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:da string ${ZDA}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:it string ${ZIT}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ja string ${ZJA}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:uk string ${ZUK}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:zh-Hans string ${ZZH}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ko string ${ZKO}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ar string ${ZAR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:ru string ${ZRU}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:zh-Hant string ${ZZH_TW}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:th string ${ZTH}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:sk string ${ZSK}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pt string ${ZPT_BR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:hr string ${ZHR}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:pl string ${ZPL}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;
				/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:LocalizedNames:de string ${ZDE}" "${Target}/Library/Preferences/.GlobalPreferences.plist" ;;
		esac
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:Longitude real ${ZLONGITUDE}" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:Name string ${ZNAME}" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:Population integer ${ZPOPULATION}" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		if [ -n "${ZREGIONALCODE}" ] ; then
			/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:RegionalCode string ${ZREGIONALCODE}" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		fi
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:TimeZoneName string ${ZTIMEZONENAME}" "${Target}/Library/Preferences/.GlobalPreferences.plist"
		/usr/libexec/PlistBuddy -c "Add :com.apple.preferences.timezone.selected_city:Version integer 1" "${Target}/Library/Preferences/.GlobalPreferences.plist"
	fi
	chown 0:0 "${Target}/Library/Preferences/.GlobalPreferences.plist"
	chmod 644 "${Target}/Library/Preferences/.GlobalPreferences.plist"
	printf "Creating:	/etc/localtime\n"
	ln -fs "/usr/share/zoneinfo/${ZTIMEZONENAME}" "${Target}/etc/localtime"
	# Begin: Debug Output
	# /usr/libexec/PlistBuddy -c "Print" "${Target}/Library/Preferences/.GlobalPreferences.plist"
	# printf "\n"
	# End: Debug Output
	printf "Creating:	/Library/Preferences/com.apple.HIToolbox.plist\n"
	if [ -e "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ] ; then
		rm -f "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	fi
	if [ -n "${SATypingStyle}" ] ; then
		set_Bundle_IDs "${SATypingStyle}"
		set_Input_Modes "${SATypingStyle}"
		set_InputSourceKinds "${SATypingStyle}"
		set_KeyboardLayout_IDs "${SATypingStyle}"
		set_KeyboardLayout_Names "${SATypingStyle}"
		set_SelectedInputSource "${SATypingStyle}"
		set_CurrentKeyboardLayoutInputSourceID "${SATypingStyle}"
	else
		unset Bundle_IDs[@]
		unset Input_Modes[@]
		set_InputSourceKinds "${SAKeyboard}"
		set_KeyboardLayout_IDs "${SAKeyboard}"
		set_KeyboardLayout_Names "${SAKeyboard}"
		set_SelectedInputSource "${SAKeyboard}"
		set_CurrentKeyboardLayoutInputSourceID "${SAKeyboard}"
	fi
	set_DefaultAsciiInputSource
	if [ ${TargetOSMinor} -gt 5 ] ; then
		defaults write "${Target}/Library/Preferences/com.apple.HIToolbox" "AppleCurrentKeyboardLayoutInputSourceID" -string "${CurrentKeyboardLayoutInputSourceID}"
	fi
	defaults write "${Target}/Library/Preferences/com.apple.HIToolbox" "AppleDefaultAsciiInputSource" -dict "InputSourceKind" -string "${InputSourceKind}" "KeyboardLayout ID" -int ${KeyboardLayout_ID} "KeyboardLayout Name" -string "${KeyboardLayout_Name}"
	/usr/libexec/PlistBuddy -c "Add :AppleEnabledInputSources array" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	i=0 ; while [ ${i} -lt ${#InputSourceKinds[@]} ] ; do
		/usr/libexec/PlistBuddy -c "Add :AppleEnabledInputSources:${i} dict" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		if [ -n "${Bundle_IDs[i]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleEnabledInputSources:${i}:Bundle\ ID string ${Bundle_IDs[i]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
		if [ -n "${Input_Modes[i]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleEnabledInputSources:${i}:Input\ Mode string ${Input_Modes[i]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
		if [ -n "${InputSourceKinds[i]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleEnabledInputSources:${i}:InputSourceKind string ${InputSourceKinds[i]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
		if [ -n "${KeyboardLayout_IDs[i]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleEnabledInputSources:${i}:KeyboardLayout\ ID integer ${KeyboardLayout_IDs[i]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
		if [ -n "${KeyboardLayout_Names[i]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleEnabledInputSources:${i}:KeyboardLayout\ Name string ${KeyboardLayout_Names[i]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
		let i++
	done
	set_ScriptManager "${LanguageCode}"
	if [ ${TargetOSMinor} -eq 5 ] ; then set_ITLB "${LanguageCode}" ; else unset ITLB ; fi
	if [ -n "${ITLB}" ] ; then
		/usr/libexec/PlistBuddy -c "Add :AppleItlbDate dict" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		/usr/libexec/PlistBuddy -c "Add :AppleItlbDate:${ScriptManager} integer ${ITLB}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		/usr/libexec/PlistBuddy -c "Add :AppleItlbNumber dict" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		/usr/libexec/PlistBuddy -c "Add :AppleItlbNumber:${ScriptManager} integer ${ITLB}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	fi
	set_ResourceID "${LanguageCode}" "${SACountryCode}"
	if [ -n "${ResourceID}" ] ; then
		/usr/libexec/PlistBuddy -c "Add :AppleDateResID dict" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		/usr/libexec/PlistBuddy -c "Add :AppleDateResID:${ScriptManager} integer ${ResourceID}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		/usr/libexec/PlistBuddy -c "Add :AppleNumberResID dict" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		/usr/libexec/PlistBuddy -c "Add :AppleNumberResID:${ScriptManager} integer ${ResourceID}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		/usr/libexec/PlistBuddy -c "Add :AppleTimeResID dict" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
		/usr/libexec/PlistBuddy -c "Add :AppleTimeResID:${ScriptManager} integer ${ResourceID}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	fi
	/usr/libexec/PlistBuddy -c "Add :AppleSelectedInputSources array" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	/usr/libexec/PlistBuddy -c "Add :AppleSelectedInputSources:0 dict" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	if [ -n "${Bundle_IDs[SelectedInputSource]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleSelectedInputSources:0:Bundle\ ID string ${Bundle_IDs[SelectedInputSource]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
	if [ -n "${Input_Modes[SelectedInputSource]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleSelectedInputSources:0:Input\ Mode string ${Input_Modes[SelectedInputSource]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
	if [ -n "${InputSourceKinds[SelectedInputSource]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleSelectedInputSources:0:InputSourceKind string ${InputSourceKinds[SelectedInputSource]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
	if [ -n "${KeyboardLayout_IDs[SelectedInputSource]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleSelectedInputSources:0:KeyboardLayout\ ID integer ${KeyboardLayout_IDs[SelectedInputSource]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
	if [ -n "${KeyboardLayout_Names[SelectedInputSource]}" ] ; then /usr/libexec/PlistBuddy -c "Add :AppleSelectedInputSources:0:KeyboardLayout\ Name string ${KeyboardLayout_Names[SelectedInputSource]}" "${Target}/Library/Preferences/com.apple.HIToolbox.plist" ; fi
	chown 0:0 "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	chmod 644 "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	# Begin: Debug Output
	# /usr/libexec/PlistBuddy -c "Print" "${Target}/Library/Preferences/com.apple.HIToolbox.plist"
	# printf "\n"
	# End: Debug Output
	if [ ${AllowGuestAccess} -eq 0 ] ; then
		printf "Creating:	/Library/Preferences/com.apple.AppleFileServer.plist\n"
		defaults write "${Target}/Library/Preferences/com.apple.AppleFileServer" "guestAccess" -bool FALSE
		chown 0:0 "${Target}/Library/Preferences/com.apple.AppleFileServer.plist"
		chmod 644 "${Target}/Library/Preferences/com.apple.AppleFileServer.plist"
		# Begin: Debug Output
		# defaults read "${Target}/Library/Preferences/com.apple.AppleFileServer"
		# printf "\n"
		# End: Debug Output
		printf "Creating:	/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist\n"
		defaults write "${Target}/Library/Preferences/SystemConfiguration/com.apple.smb.server" "AllowGuestAccess" -bool FALSE
		chown 0:0 "${Target}/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist"
		chmod 644 "${Target}/Library/Preferences/SystemConfiguration/com.apple.smb.server.plist"
		# Begin: Debug Output
		# defaults read "${Target}/Library/Preferences/SystemConfiguration/com.apple.smb.server"
		# printf "\n"
		# End: Debug Output
	fi
	if [ ${ManagedUserPrinters} -eq 1 ] ; then
		GeneratedUID=`dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly read /Local/Target/Groups/everyone GeneratedUID | awk '{print $NF}'`
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Groups/_lpadmin NestedGroups "${GeneratedUID}"
	fi
	printf "Creating:	/etc/ntp.conf\n"
	printf "server ${NTPServer}\n" > "${Target}/etc/ntp.conf"
	chown 0:0 "${Target}/etc/ntp.conf"
	chmod 644 "${Target}/etc/ntp.conf"
	# Begin: Debug Output
	# cat "${Target}/etc/ntp.conf"
	# printf "\n"
	# End: Debug Output
	printf "Creating:	/var/db/.AppleSetupDone\n"
	touch "${Target}/var/db/.AppleSetupDone"
	chown 0:0 "${Target}/var/db/.AppleSetupDone"
	chmod 600 "${Target}/var/db/.AppleSetupDone"
	printf "Creating:	/var/db/launchd.db/com.apple.launchd/overrides.plist\n"
	if [ ! -e "${Target}/var/db/launchd.db/com.apple.launchd" ] ; then
		mkdir -p "${Target}/var/db/launchd.db/com.apple.launchd"
	fi
	if [ ${NTPEnabled} -eq 1 ] ; then
		defaults write "${Target}/var/db/launchd.db/com.apple.launchd/overrides" "org.ntp.ntpd" -dict "Disabled" -bool FALSE
	else
		defaults write "${Target}/var/db/launchd.db/com.apple.launchd/overrides" "org.ntp.ntpd" -dict "Disabled" -bool TRUE
	fi
	if [ ${RemoteLogin} -eq 1 ] ; then
		defaults write "${Target}/var/db/launchd.db/com.apple.launchd/overrides" "com.openssh.sshd" -dict "Disabled" -bool FALSE
	else
		defaults write "${Target}/var/db/launchd.db/com.apple.launchd/overrides" "com.openssh.sshd" -dict "Disabled" -bool TRUE
	fi
	chown 0:0 "${Target}/var/db/launchd.db/com.apple.launchd/overrides.plist"
	chmod 600 "${Target}/var/db/launchd.db/com.apple.launchd/overrides.plist"
	# Begin: Debug Output
	# /usr/libexec/PlistBuddy -c "Print" "${Target}/var/db/launchd.db/com.apple.launchd/overrides.plist"
	# printf "\n"
	# End: Debug Output
	printf "Creating:	/var/log/CDIS.custom\n"
	printf "LANGUAGE=${Localization}\n" > "${Target}/var/log/CDIS.custom"
	chown 0:0 "${Target}/var/log/CDIS.custom"
	chmod 644 "${Target}/var/log/CDIS.custom"
	# Begin: Debug Output
	# cat "${Target}/var/log/CDIS.custom"
	# printf "\n"
	# End: Debug Output
	printf "Creating:	/Library/LaunchDaemons/FirstBoot.plist\n"
	defaults write "${Target}/Library/LaunchDaemons/FirstBoot" "Label" -string "FirstBoot"
	defaults write "${Target}/Library/LaunchDaemons/FirstBoot" "ProgramArguments" -array "${FirstBootPath}/FirstBoot.sh"
	defaults write "${Target}/Library/LaunchDaemons/FirstBoot" "RunAtLoad" -bool TRUE
	chown 0:0 "${Target}/Library/LaunchDaemons/FirstBoot.plist"
	chmod 644 "${Target}/Library/LaunchDaemons/FirstBoot.plist"
	# Begin: Debug Output
	# /usr/libexec/PlistBuddy -c "Print" "${Target}/Library/LaunchDaemons/FirstBoot.plist"
	# printf "\n"
	# End: Debug Output
	printf "Creating:	${FirstBootPath}/FirstBoot.sh\n"
	mkdir -p "${Target}/${FirstBootPath}/Actions"
	mkdir -p "${Target}/${FirstBootPath}/Packages"
	printf \#\!"/bin/sh\n" > "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "ScriptPath=\`dirname \"\${0}\"\`" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "IFS=\$'\\\n'" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "Actions=( \`ls \"\${ScriptPath}/Actions\" 2>/dev/null\` )" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "Packages=( \`ls \"\${ScriptPath}/Packages\" 2>/dev/null\` )" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "unset IFS" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "for Action in \"\${Actions[@]}\" ; do" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "	\"\${ScriptPath}/Actions/\${Action}\"" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "done" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "Minor=\`sw_vers -productVersion | awk -F \".\" '{print \$2}'\`" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "Point=\`sw_vers -productVersion | awk -F \".\" '{print \$3}'\`" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "if [ \${Minor} -eq 7 -a \${Point} -gt 3 ] || [ \${Minor} -gt 7 ] ; then GateKeeper=\"-allowUntrusted\" ; fi" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "for Package in \"\${Packages[@]}\" ; do" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "	installer -dumplog \"\${GateKeeper}\" -pkg \"\${ScriptPath}/Packages/\${Package}\" -target / 2>/dev/null" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "done" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "srm \"/Library/LaunchDaemons/FirstBoot.plist\"" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "srm -rf \"\${ScriptPath}\"" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	echo "exit 0" >> "${Target}/${FirstBootPath}/FirstBoot.sh"
	chown 0:0 "${Target}/${FirstBootPath}/FirstBoot.sh"
	chmod 755 "${Target}/${FirstBootPath}/FirstBoot.sh"
	# Begin: Debug Output
	# cat "${Target}/${FirstBootPath}/FirstBoot.sh"
	# printf "\n"
	# End: Debug Output
	if [ -n "${ComputerName}" ] ; then
		printf "Creating:	${FirstBootPath}/Actions/ComputerName.sh\n"
		printf \#\!"/bin/sh\n" > "${Target}/${FirstBootPath}/Actions/ComputerName.sh"
		case "${ComputerName}" in
			"Model and MAC Address" )
				echo "ModelName=\`system_profiler | grep \"Model Name: \" | awk -F \": \" '{print \$NF}'\`" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh" ;
				echo "MACAddress=\`ifconfig en0 | grep \"ether\" | awk '{print \$NF}' | sed \"s/://g\"\`" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh" ;
				echo "ComputerName=\"\${ModelName} \${MACAddress}\"" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh" ;;
			"Generic using MAC Address" )
				echo "MACAddress=\`ifconfig en0 | grep \"ether\" | awk '{print \$NF}' | sed \"s/://g\"\`" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh" ;
				echo "ComputerName=\"Mac \${MACAddress}\"" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh" ;;
			"Serial Number" )
				echo "ComputerName=\`system_profiler | grep \"Serial Number (system): \" | awk -F \": \" '{print \$NF}'\`" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh" ;;
		esac
		echo "LocalHostName=\"\${ComputerName// /-}\"" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh"
		echo "scutil --set ComputerName \"\${ComputerName}\"" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh"
		echo "scutil --set LocalHostName \"\${LocalHostName}\"" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh"
		echo "exit 0" >> "${Target}/${FirstBootPath}/Actions/ComputerName.sh"
		chown 0:0 "${Target}/${FirstBootPath}/Actions/ComputerName.sh"
		chmod 755 "${Target}/${FirstBootPath}/Actions/ComputerName.sh"
	fi
	# Begin: Debug Output
	# cat "${Target}/${FirstBootPath}/Actions/ComputerName.sh"
	# printf "\n"
	# End: Debug Output
	if [ ${TargetOSMinor} -ge 6 ] ; then
		if [ ${TZAuto} -eq 1 ] ;then
			printf "Creating:	/Library/Preferences/com.apple.timezone.auto.plist\n"
			defaults write "${Target}/Library/Preferences/com.apple.timezone.auto" "Active" -bool TRUE
			chown 0:0 "${Target}/Library/Preferences/com.apple.timezone.auto.plist"
			chmod 644 "${Target}/Library/Preferences/com.apple.timezone.auto.plist"
			if [ ${TargetOSMinor} -ge 8 ] ; then
				printf "Creating:	${FirstBootPath}/Actions/LocationServices.sh\n"
				printf \#\!"/bin/sh\n" > "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "if [ \`ioreg -rd1 -c IOPlatformExpertDevice | grep -i \"UUID\" | cut -c27-50\` == \"00000000-0000-1000-8000-\" ] ; then" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "	UUID=\`ioreg -rd1 -c IOPlatformExpertDevice | grep -i \"UUID\" | cut -c51-62 | awk {'print tolower()'}\`" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "else" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "	UUID=\`ioreg -rd1 -c IOPlatformExpertDevice | grep -i \"UUID\" | cut -c27-62\`" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "fi" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "mkdir -p \"/private/var/db/locationd/Library/Preferences/ByHost\"" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "defaults write \"/private/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.\${UUID}\" \"ObsoleteDataDeleted\" -bool TRUE" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "defaults write \"/private/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.\${UUID}\" \"LocationServicesEnabled\" -int 1" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "defaults write \"/private/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.notbackedup.\${UUID}\" \"LocationServicesEnabled\" -int 1" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "chown -Rh 205:205 \"/private/var/db/locationd/Library/Preferences/ByHost\"" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				echo "exit 0" >> "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				chown 0:0 "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				chmod 755 "${Target}/${FirstBootPath}/Actions/LocationServices.sh"
				# Begin: Debug Output
				# cat "${Target}/usr/libexec/FirstBoot/Actions/LocationServices.sh"
				# printf "\n"
				# End: Debug Output
			fi
		fi
	fi
	if [ ${RemoteManagement} -eq 1 ] ; then
		printf "Creating:	/Library/Preferences/com.apple.RemoteManagement.plist\n"
		defaults write "${Target}/Library/Preferences/com.apple.RemoteManagement" "ARD_AllLocalUsersPrivs" -int 1073742079
		defaults write "${Target}/Library/Preferences/com.apple.RemoteManagement" "ARD_AllLocalUsers" -bool TRUE
		chown 0:0 "${Target}/Library/Preferences/com.apple.RemoteManagement.plist"
		chmod 644 "${Target}/Library/Preferences/com.apple.RemoteManagement.plist"
		# Begin: Debug Output
		# /usr/libexec/PlistBuddy -c "Print" "${Target}/Library/Preferences/com.apple.RemoteManagement.plist"
		# printf "\n"
		# End: Debug Output
		printf "Creating:	/etc/RemoteManagement.launchd\n"
		printf "enabled" > "${Target}/etc/RemoteManagement.launchd"
		chown 0:0 "${Target}/etc/RemoteManagement.launchd"
		chmod 644 "${Target}/etc/RemoteManagement.launchd"
		# Begin: Debug Output
		# cat "${Target}/etc/RemoteManagement.launchd" ; printf "\n"
		# printf "\n"
		# End: Debug Output
		printf "Creating:	${FirstBootPath}/Actions/RemoteManagement.sh\n"
		printf \#\!"/bin/sh\n" > "${Target}/${FirstBootPath}/Actions/RemoteManagement.sh"
		echo "/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -restart -agent -privs -all" >> "${Target}/${FirstBootPath}/Actions/RemoteManagement.sh"
		echo "exit 0" >> "${Target}/${FirstBootPath}/Actions/RemoteManagement.sh"
		chown 0:0 "${Target}/${FirstBootPath}/Actions/RemoteManagement.sh"
		chmod 755 "${Target}/${FirstBootPath}/Actions/RemoteManagement.sh"
		# Begin: Debug Output
		# cat "${Target}/usr/libexec/FirstBoot/Actions/RemoteManagement.sh"
		# printf "\n"
		# End: Debug Output
	fi
	# Advanced System Settings, to be implemented
	if [ ${AdminHostInfo} -eq 1 ] ; then
		defaults write "${Target}/Library/Preferences/com.apple.loginwindow" "AdminHostInfo" -string "HostName"
	fi
	if [ ${ShowFullName} -eq 1 ] ; then
		defaults write "${Target}/Library/Preferences/com.apple.loginwindow" "SHOWFULLNAME" -bool TRUE
	fi
	if [ -e "${Target}/Library/Preferences/com.apple.loginwindow.plist" ] ; then
		chown 0:0 "${Target}/Library/Preferences/com.apple.loginwindow.plist"
		chmod 644 "${Target}/Library/Preferences/com.apple.loginwindow.plist"
	fi
	# Begin: Debug Output
	# defaults read "${Target}/Library/Preferences/com.apple.loginwindow"
	# printf "\n"
	# End: Debug Output
	if [ ${SoftwareUpdateCheck} -eq 0 ] ; then
		printf "Creating:	${FirstBootPath}/Actions/SoftwareUpdateCheck.sh\n"
		printf \#\!"/bin/sh\n" > "${Target}/${FirstBootPath}/Actions/SoftwareUpdateCheck.sh"
		echo "softwareupdate --schedule off" >> "${Target}/${FirstBootPath}/Actions/SoftwareUpdateCheck.sh"
		echo "exit 0" >> "${Target}/${FirstBootPath}/Actions/SoftwareUpdateCheck.sh"
		chown 0:0 "${Target}/${FirstBootPath}/Actions/SoftwareUpdateCheck.sh"
		chmod 755 "${Target}/${FirstBootPath}/Actions/SoftwareUpdateCheck.sh"
		# Begin: Debug Output
		# cat "${Target}/usr/libexec/FirstBoot/Actions/SoftwareUpdateCheck.sh"
		# printf "\n"
		# End: Debug Output
	fi
	printf "\n"
	i=0 ; for RecordName in "${RecordNames[@]}" ; do
		printf "Creating User:	${RecordName}\n"
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/"${RecordName}"
		printf "		Setting Full Name"
		# Begin: Debug Output
		printf ":	${RealNames[i]}"
		# End: Debug Output
		printf "\n"
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Users/"${RecordName}" RealName "${RealNames[i]}"
		printf "		Setting Password"
		if [ ${TargetOSMinor} -le 6 ] ; then
			GeneratedUID=`dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -read /Local/Target/Users/"${RecordName}" GeneratedUID | awk '{print $2}'`
			if [ ! -e "${Target}/var/db/shadow/hash" ] ; then
				mkdir -p "${Target}/var/db/shadow/hash"
				chmod -R 0700 "${Target}/var/db/shadow"
			fi
			if [ -n "${GeneratedUID}" ] && [ -e "/var/db/shadow/hash/${GeneratedUID}" ] ; then
				mv "/var/db/shadow/hash/${GeneratedUID}" "${Target}/var/db/shadow/hash/" &>/dev/null
			fi
		fi
		# Begin: Debug Output
		printf ":	"
		if [ -n "${Passwords[i]}" ] ; then
			j=0 ; while [ ${j} -lt ${#Passwords[i]} ] ; do printf "*" ; let j++ ; done
		else
			printf "-"
		fi
		# End: Debug Output
		printf "\n"
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -passwd /Local/Target/Users/"${RecordName}" "${Passwords[i]}"
		printf "		Setting Password Hint"
		# Begin: Debug Output
		printf ":	" ; if [ -n "${AuthenticationHints[i]}" ] ; then printf "${AuthenticationHints[i]}" ; else printf "-" ; fi
		# End: Debug Output
		printf "\n"
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Users/"${RecordName}" AuthenticationHint "${AuthenticationHints[i]}"
		printf "		Setting User ID"
		# Begin: Debug Output
		printf ":	${UniqueIDs[i]}"
		# End: Debug Output
		printf "\n"
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Users/"${RecordName}" UniqueID ${UniqueIDs[i]}
		if [ ${UniqueIDs[i]} -lt 501 ] ; then
			defaults write "${Target}/Library/Preferences/com.apple.loginwindow" Hide500Users -bool TRUE
			defaults write "${Target}/Library/Preferences/com.apple.loginwindow" HiddenUsersList -array-add "${RecordName}"
			chmod 0644 "${Target}/Library/Preferences/com.apple.loginwindow.plist"
		fi
		printf "		Setting Group ID"
		# Begin: Debug Output
		printf ":	20"
		# End: Debug Output
		printf "\n"
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Users/"${RecordName}" PrimaryGroupID 20
		printf "		Setting Login Shell"
		# Begin: Debug Output
		printf ":	${UserShells[i]}"
		# End: Debug Output
		printf "\n"
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Users/"${RecordName}" UserShell "${UserShells[i]}"
		printf "		Setting Home Directory"
		# Begin: Debug Output
		printf ":	${NFSHomeDirectories[i]}"
		# End: Debug Output
		printf "\n"
		dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Users/"${RecordName}" NFSHomeDirectory "${NFSHomeDirectories[i]}"
		ditto "${Target}/System/Library/User Template/Non_localized" "${Target}/${NFSHomeDirectories[i]}"
		ditto "${Target}/System/Library/User Template/${Localization}.lproj" "${Target}/${NFSHomeDirectories[i]}"
		defaults write "${Target}/${NFSHomeDirectories[i]}/Library/Preferences/.GlobalPreferences" AppleMiniaturizeOnDoubleClick -bool FALSE
		defaults write "${Target}/${NFSHomeDirectories[i]}/Library/Preferences/.GlobalPreferences" AppleScrollAnimationEnabled -bool TRUE
		# Begin: User Preferences
		if [ ${UserSettings} -eq 1 ] ; then
			if [ ${TargetOSMinor} -ge 7 ] ; then
				defaults write "${Target}/${NFSHomeDirectories[i]}/Library/Preferences/.GlobalPreferences" "AppleShowScrollBars" -string "${AppleShowScrollBars}"
				defaults write "${Target}/${NFSHomeDirectories[i]}/Library/Preferences/com.apple.finder" "WindowState" -dict "ShowStatusBar" -bool ${ShowStatusBar}
				defaults write "${Target}/${NFSHomeDirectories[i]}/Library/Preferences/com.apple.finder" "NewWindowTarget" -string "${NewWindowTarget}"
				defaults write "${Target}/${NFSHomeDirectories[i]}/Library/Preferences/com.apple.SetupAssistant" "GestureMovieSeen" -string "${GestureMovieSeen}"
				if [ ${SuppressCloudSetup} -eq 1 ] ; then
					defaults write "${Target}/${NFSHomeDirectories[i]}/Library/Preferences/com.apple.SetupAssistant" "DidSeeCloudSetup" -bool TRUE
					defaults write "${Target}/${NFSHomeDirectories[i]}/Library/Preferences/com.apple.SetupAssistant" "LastSeenCloudProductVersion" -string "10.${TargetOSMinor}"
				fi
			fi
		fi
		# End: User Preferences
		chown -Rh ${UniqueID}:staff "${Target}/${NFSHomeDirectories[i]}"
		if [ ${TargetOSMinor} -eq 5 ] || [ "${AccountTypes[i]}" == "Administrator" ] ; then
			printf "		Adding to Group(s)"
			# Begin: Debug Output
			printf ":	"
			# End: Debug Output
		fi
		if [ ${TargetOSMinor} -eq 5 ] ; then
			# Begin: Debug Output
			printf "staff\n"
			printf "					"
			# End: Debug Output
			dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Groups/staff GroupMembership "${RecordName}"
		fi
		if [ "${AccountTypes[i]}" == "Administrator" ] ; then
			# Begin: Debug Output
			printf "admin\n"
			# End: Debug Output
			dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Groups/admin GroupMembership "${RecordName}"
			# Begin: Debug Output
			printf "					_lpadmin\n"
			# End: Debug Output
			dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Groups/_lpadmin GroupMembership "${RecordName}"
			# Begin: Debug Output
			printf "					_appserverusr\n"
			# End: Debug Output
			dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Groups/_appserverusr GroupMembership "${RecordName}"
			# Begin: Debug Output
			printf "					_appserveradm\n"
			# End: Debug Output
			dscl -f "${Target}/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Groups/_appserveradm GroupMembership "${RecordName}"
		fi
		printf "\n"
		let i++
	done
	if [ ${#Packages[@]} -gt 0 ] ; then
		printf "Installing Packages\n"
		for Package in "${Packages[@]}" ; do
			find "${PackageFolder}" -name "${Package}" -a \! -path "*pkg/*" | while read PackagePath ; do
				IFS=$'\n'
				AvailableTargets=( `installer -volinfo -pkg "${PackagePath}" | grep "/Volumes/"` )
				unset IFS
				PostponedInstall=1
				for AvailableTarget in "${AvailableTargets[@]}" ; do
					if [ "${AvailableTarget}" == "${Target}" ] ; then PostponedInstall=0 ; break ; fi
				done
				if [ ${PostponedInstall} -eq 0 ] ; then
					install_Package "${PackagePath}" "${Target}" 0
				else
					IFS=$'\n'
					PackageTitles=( `installer -pkginfo -pkg "${PackagePath}"` )
					unset IFS
					printf "installer: Package name is ${PackageTitles[0]}\n"
					printf "installer: Target volume unavailable, will attempt postponed install.\n"
					if [ ! -e "${Target}/${FirstBootPath}/Packages/${Package}" ] ; then
						ditto "${PackagePath}" "${Target}/${FirstBootPath}/Packages/${Package}"
					else
						printf "installer: Duplicate package, skipping.\n"
					fi
				fi
			done
		done
		printf "\n"
	fi
	if [ ${#RemovableItems[@]} -gt 0 ] ; then
		for Item in "${RemovableItems[@]}" ; do
			unset bundleID
			case "${Item}" in
				"iPhoto" )
					Removables=(
						"Applications/iPhoto.app"
						"Library/Application Support/iLife"
						"Library/Application Support/iPhoto"
						"Library/Application Support/NetServices"
						"Library/Frameworks/iLifeKit.framework"
						"Library/Frameworks/iLifePageLayout.framework"
						"Library/Frameworks/iLifeSQLAccess.framework"
						"Library/Internet Plug-Ins/iPhotoPhotocast.plugin"
						"Library/Receipts/iPhoto.pkg"
						"Library/Receipts/iPhotoContent.pkg"
						"var/db/receipts/com.apple.pkg.iPhoto_AppStore.bom"
						"var/db/receipts/com.apple.pkg.iPhoto_AppStore.plist"
						"var/db/receipts/com.apple.pkg.iPhoto.bom"
						"var/db/receipts/com.apple.pkg.iPhoto.plist"
						"var/db/receipts/com.apple.pkg.iPhotoContent.bom"
						"var/db/receipts/com.apple.pkg.iPhotoContent.plist"
						"var/db/receipts/com.apple.pkg.iPhotoLibraryUpgradeTool.bom"
						"var/db/receipts/com.apple.pkg.iPhotoLibraryUpgradeTool.plist"
					) ;
					bundleID="com.apple.iPhoto" ;
					if [ -e "${Target}/Applications/iPhoto.app" ] ; then echo "Removing:	iPhoto" ; else break ; fi ;;
				"iMovie" )
					Removables=(
						"Applications/iMovie.app"
						"Library/Receipts/iMovie.pkg"
						"var/db/receipts/com.apple.pkg.iMovie_AppStore.bom"
						"var/db/receipts/com.apple.pkg.iMovie_AppStore.plist"
						"var/db/receipts/com.apple.pkg.iMovie.bom"
						"var/db/receipts/com.apple.pkg.iMovie.plist"
					) ;
					bundleID="com.apple.iMovieApp" ;
					if [ -e "${Target}/Applications/iMovie.app" ] ; then echo "Removing:	iMovie" ; else break ; fi ;;
				"iDVD" )
					Removables=(
						"Applications/iDVD.app"
						"Library/Application Support/iDVD"
						"Library/Application Support/iDVD/Themes"
						"Library/Documentation/Applications/iDVD"
						"Library/Receipts/iDVD.pkg"
						"Library/Receipts/iDVDExtraContent.pkg"
						"Library/Receipts/iDVDThemes.pkg"
						"var/db/receipts/com.apple.pkg.iDVD.bom"
						"var/db/receipts/com.apple.pkg.iDVD.plist"
						"var/db/receipts/com.apple.pkg.iDVDExtraContent.bom"
						"var/db/receipts/com.apple.pkg.iDVDExtraContent.plist"
						"var/db/receipts/com.apple.pkg.iDVDThemes.bom"
						"var/db/receipts/com.apple.pkg.iDVDThemes.plist"
					) ;
					if [ -e "${Target}/Applications/iDVD.app" ] ; then echo "Removing:	iDVD" ; else break ; fi ;;
				"GarageBand" )
					Removables=(
						"Applications/GarageBand.app"
						"Library/Application Support/GarageBand"
						"Library/Application Support/GarageBand/Instrument Library"
						"Library/Application Support/GarageBand/Learn to Play"
						"Library/Application Support/GarageBand/Magic GarageBand"
						"Library/Application Support/GarageBand/Templates"
						"Library/Audio/Apple Loops"
						"Library/Audio/Apple Loops Index"
						"Library/Audio/Apple Loops/Apple/Apple Loops for GarageBand"
						"Library/Audio/MIDI Drivers/EmagicUSBMIDIDriver.plugin"
						"Library/QuickLook/GBQLGenerator.qlgenerator"
						"Library/Receipts/GarageBand_Instruments.pkg"
						"Library/Receipts/GarageBand_Loops.pkg"
						"Library/Receipts/GarageBand_LTPContent.pkg"
						"Library/Receipts/GarageBand_MagicContent.pkg"
						"Library/Receipts/GarageBand.pkg"
						"Library/Receipts/GarageBandExtraContent.pkg"
						"Library/Receipts/GarageBandFactoryContent.pkg"
						"Library/Spotlight/GBSpotlightImporter.mdimporter"
						"Library/Spotlight/LogicPro.mdimporter"
						"var/db/receipts/com.apple.pkg.GarageBand_AppStore.bom"
						"var/db/receipts/com.apple.pkg.GarageBand_AppStore.plist"
						"var/db/receipts/com.apple.pkg.GarageBand_Instruments.bom"
						"var/db/receipts/com.apple.pkg.GarageBand_Instruments.plist"
						"var/db/receipts/com.apple.pkg.GarageBand_Loops.bom"
						"var/db/receipts/com.apple.pkg.GarageBand_Loops.plist"
						"var/db/receipts/com.apple.pkg.GarageBand_LTPContent.bom"
						"var/db/receipts/com.apple.pkg.GarageBand_LTPContent.plist"
						"var/db/receipts/com.apple.pkg.GarageBand_MagicContent.bom"
						"var/db/receipts/com.apple.pkg.GarageBand_MagicContent.plist"
						"var/db/receipts/com.apple.pkg.GarageBand.bom"
						"var/db/receipts/com.apple.pkg.GarageBand.plist"
						"var/db/receipts/com.apple.pkg.GarageBandBasicContent.bom"
						"var/db/receipts/com.apple.pkg.GarageBandBasicContent.plist"
						"var/db/receipts/com.apple.pkg.GarageBandExtraContent.bom"
						"var/db/receipts/com.apple.pkg.GarageBandExtraContent.plist"
						"var/db/receipts/com.apple.pkg.GarageBandFactoryContent.bom"
						"var/db/receipts/com.apple.pkg.GarageBandFactoryContent.plist"
					) ;
					bundleID="com.apple.garageband" ;
					if [ -e "${Target}/Applications/GarageBand.app" ] ; then echo "Removing:	GarageBand" ; else break ; fi ;;
				"Sounds & Jingles" )
					Removables=(
						"Library/Audio/Apple Loops/Apple/iLife Sound Effects"
						"Library/Receipts/iLifeSoundEffects_Loops.pkg"
						"var/db/receipts/com.apple.pkg.iLifeSoundEffects_Loops.bom"
						"var/db/receipts/com.apple.pkg.iLifeSoundEffects_Loops.plist"
					) ;
					if [ -e "${Target}/Library/Receipts/iLifeSoundEffects_Loops.pkg" ] || [ -e "${Target}/var/db/receipts/com.apple.pkg.iLifeSoundEffects_Loops.bom" ] ; then echo "Removing:	Sounds & Jingles" ; else break ; fi ;;
				"iWeb" )
					Removables=(
						"Applications/iWeb.app"
						"Library/Fonts/AppleCasual.dfont"
						"Library/Fonts/BlairMdITC TT-Medium"
						"Library/Fonts/Bordeaux Roman Bold LET Fonts"
						"Library/Fonts/Cracked"
						"Library/Fonts/Handwriting - Dakota"
						"Library/Fonts/Palatino"
						"Library/Fonts/PortagoITC TT"
						"Library/Receipts/iWeb.pkg"
						"var/db/receipts/com.apple.pkg.iWeb.bom"
						"var/db/receipts/com.apple.pkg.iWeb.plist"
					) ;
					if [ -e "${Target}/Applications/iWeb.app" ] ; then echo "Removing:	iWeb" ; else break ; fi ;;
			esac
			for Removable in "${Removables[@]}" ; do
				if [ -e "${Target}/${Removable}" ] ; then
					echo "		/${Removable}"
					rm -rf "${Target}/${Removable}"
				fi
			done
			if [ -n "${bundleID}" ] ; then
				i=0 ; while : ; do
					MASbundleID=`/usr/libexec/PlistBuddy -c "Print :${i}:bundleID" "${Target}/var/db/.MASManifest" 2>/dev/null`
					if [ ${?} -ne 0 ] ; then break ; fi
					if echo "${MASbundleID}" | grep -q "${bundleID}" ; then
						/usr/libexec/PlistBuddy -c "Delete :${i}" "${Target}/var/db/.MASManifest"
						break
					fi
					let i++
				done
			fi
		done
		if [ -e "${Target}/Library/Receipts/iLifeCookie.pkg" ] || [ -e "${Target}/var/db/receipts/com.apple.pkg.iLifeCookie.bom" ] ; then
			if [ ! -e "${Target}/Applications/iPhoto.app" ] && [ ! -e "${Target}/Applications/iMovie.app" ] && [ ! -e "${Target}/Applications/iDVD.app" ] && [ ! -e "${Target}/Applications/GarageBand.app" ] && [ ! -e "${Target}/Library/Receipts/iLifeSoundEffects_Loops.pkg" ] && [ ! -e "${Target}/var/db/receipts/com.apple.pkg.iLifeSoundEffects_Loops.bom" ] && [ ! -e "${Target}/Applications/iWeb.app" ] ; then
				Removables=(
					"Library/Application Support/iLifeSlideshow"
					"Library/Documentation/Applications/iMovie"
					"Library/Documentation/Applications/iPhoto"
					"Library/Documentation/Applications/iWeb"
					"Library/Frameworks/iLifeFaceRecognition.framework"
					"Library/Frameworks/iLifeSlideshow.framework"
					"Library/Receipts/iLifeCookie.pkg"
					"Library/Receipts/iLifeSlideshow.pkg"
					"System/Library/CoreServices/CoreTypes.bundle/Contents/Library/iLifeSlideshowTypes.bundle"
					"System/Library/PrivateFrameworks/iLifeSlideshow.framework"
					"var/db/receipts/com.apple.pkg.iLifeCookie.bom"
					"var/db/receipts/com.apple.pkg.iLifeCookie.plist"
					"var/db/receipts/com.apple.pkg.iLifeFaceRecognition.bom"
					"var/db/receipts/com.apple.pkg.iLifeFaceRecognition.plist"
					"var/db/receipts/com.apple.pkg.iLifeRegistration.bom"
					"var/db/receipts/com.apple.pkg.iLifeRegistration.plist"
					"var/db/receipts/com.apple.pkg.iLifeRegistrationPost.bom"
					"var/db/receipts/com.apple.pkg.iLifeRegistrationPost.plist"
					"var/db/receipts/com.apple.pkg.iLifeSlideshow_v2.bom"
					"var/db/receipts/com.apple.pkg.iLifeSlideshow_v2.plist"
					"var/db/receipts/com.apple.pkg.iLifeSlideshow.bom"
					"var/db/receipts/com.apple.pkg.iLifeSlideshow.plist"
					"var/tmp/.BlankFile"
				)
				echo "Removing:	iLife Support"
				for Removable in "${Removables[@]}" ; do
					if [ -e "${Target}/${Removable}" ] ; then
						echo "		/${Removable}"
						rm -rf "${Target}/${Removable}"
					fi
				done
			fi
		fi
		/usr/libexec/PlistBuddy -c "Print :0" "${Target}/var/db/.MASManifest" &>/dev/null
		if [ ${?} -ne 0 ] ; then rm -f "${Target}/var/db/.MASManifest" ; fi
		echo
	fi
	# Pause prior to exporting to make any additional changes
	# press_anyKey
	if [ ${TargetType} -eq 1 ] ; then
		set_TargetProperties
	fi
	if [ ${TargetType} -eq 2 ] ; then
		printf "Exporting Image(s)\n"
		if [ ! -d "${MasterFolder}" ] ; then mkdir -p "${MasterFolder}" ; fi
		if [ -e "${MasterFolder}/${MasterName}" ] ; then rm -f "${MasterFolder}/${MasterName}" ; fi
		if [ -e "${MasterFolder}/${RecoveryName}" ] ; then rm -f "${MasterFolder}/${RecoveryName}" ; fi
		for TargetVolume in "${TargetVolumes[@]}" ; do
			rm -rf "/Volumes/${TargetVolume}/.Spotlight-V100"
			rm -rf "/Volumes/${TargetVolume}/.Trashes"
			rm -rf "/Volumes/${TargetVolume}/.fseventsd"
		done
		case ${ExportType} in
			1 )
				hdiutil eject "${Target}" -force &>/dev/null ;
				while [ -e "${Target}" ] ; do sleep 1 ; done ;
				hdiutil convert -format UDZO "${LibraryFolder}/${TargetName}" -shadow "${LibraryFolder}/${TargetName}.shadow" -o "${MasterFolder}/${MasterName}" ;;
			2 )
				hdiutil create -srcfolder "${Target}" -layout SPUD "${MasterFolder}/${MasterName}" ;
				hdiutil eject "${Target}" -force &>/dev/null ;
				while [ -e "${Target}" ] ; do sleep 1 ; done ;;
			3 )
				printf "Initializing…\n"
				printf "Creating…\n"
				printf "copying \"${Target}\"."
				hdiutil create -srcfolder "${Target}" -layout SPUD "${MasterFolder}/${MasterName}" ;
				if [ ${#TargetVolumes[@]} -gt 1 ] ; then
					TargetDevice=`diskutil info "${Target}" | grep -m 1 "Part of Whole:" | awk '{print $NF}'` ;
					hdiutil unmount "/dev/${TargetDevice}s3" &>/dev/null
					hdiutil create -srcdevice "/dev/${TargetDevice}s3" "${MasterFolder}/${RecoveryName}" ;
				fi
				hdiutil eject "${Target}" -force &>/dev/null ;
				while [ -e "${Target}" ] ; do sleep 1 ; done ;;
		esac
		printf "\n"
		printf "Scanning Image(s) for Restore\n"
		asr imagescan --source "${MasterFolder}/${MasterName}"
		if [ -e "${MasterFolder}/${RecoveryName}" ] ; then asr imagescan --source "${MasterFolder}/${RecoveryName}" ; fi
		rm -f "${LibraryFolder}/${TargetName}.shadow"
		Volume=`hdiutil attach -owners on -noverify "${LibraryFolder}/${TargetName}" | grep "Apple_HFS" | awk -F "/Volumes/" '{print $NF}'`
		set_Target "${Volume}"
		printf "\n"
	fi
	press_anyKey
}

function menu_SystemSetup {
	SystemSetupOptions=( "Main Menu" "Select Target" "Configurations" "System Preferences" "Users" "Packages" "Remove Software" "Apply Configuration" )
	while [ "${Option}" != "Main Menu" ] ; do
		display_Subtitle "Configure System"
		display_Target
		display_Options "Options" "Select an option: "
		select Option in "${SystemSetupOptions[@]}" ; do
			case "${Option}" in
				"Main Menu" ) break ;;
				"Select Target" ) select_Target ; unset Option ; break ;;
				"Configurations" ) menu_Configurations ; unset Option ; break ;;
				"System Preferences" ) menu_SystemPreferences ; unset Option ; break ;;
				"Users" ) menu_Users ; unset Option ; break ;;
				"Packages" ) menu_Packages ; unset Option ; break ;;
				"Remove Software" ) menu_RemoveSoftware ; unset Option ; break ;;
				"Apply Configuration" ) apply_Configuration ; unset Option ; break ;;
			esac
		done
	done
	if [ ${TargetType} -eq 2 ] ; then hdiutil eject "${Target}" &>/dev/null ; fi
	unset TargetName
	unset TargetType
	set_TargetProperties
}

function main_Menu {
	while [ "${Option}" != "Exit" ] ; do
		display_Subtitle "Main Menu"
		Options=( "Exit" "Help" "Preferences" "Create Image" "System Setup" )
		display_Options "Options" "Select an option: "
		select Option in "${Options[@]}" ; do
			case "${Option}" in
				"Exit" ) echo ; exit 0 ;;
				"Help" ) menu_Help ; unset Option ; break ;;
				"Preferences" ) menu_Preferences ; unset Option ; break ;;
				"Create Image" ) menu_CreateImage ; unset Option ; break ;;
				"System Setup" ) menu_SystemSetup ; unset Option ; break ;;
			esac
		done
	done
}

privelege_Check
get_LicenseStatus
menu_License
get_SystemOSVersion
get_LocalUsers
get_Preferences
set_TargetProperties
set_LanguageCountryCodes "${LanguageCode}"
set_OtherCountryCodes
main_Menu

exit 0