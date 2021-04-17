#!/bin/bash

#===========================================================================================================
# GLOBAL VARIABLES
#===========================================================================================================
RED='\033[1;31m'
GREEN='\033[1;32m'
RESET='\033[0m'

#===========================================================================================================
# HELPER FUNCTIONS
#===========================================================================================================
print_menu_item()
{
	local index=$1
	local status=$2
	local itemname=$3

	local checkmark="${GREEN}OK${RESET}"

	if [[ $status -eq 0 ]]; then
		checkmark="  "
	fi

	echo -e "\n $index. [ $checkmark ] $itemname"
}

print_submenu_heading()
{
	clear

	echo -e ":: ${GREEN}$1${RESET}\n"
}

print_progress_text()
{
	echo ""
	echo -e "${GREEN}==>${RESET} $1"
	echo ""
}

print_warning()
{
	echo -e "${RED}WARNING:${RESET} $1"
}

print_file_contents()
{
	echo ""
	echo -e "---------------------------------------------------------------------------"
	echo -e "-- ${GREEN}$1${RESET}"
	echo -e "---------------------------------------------------------------------------"
	echo ""
	cat $1
	echo ""
	echo -e "---------------------------------------------------------------------------"
	echo ""
}

get_any_key()
{
	echo ""
	read -s -e -n 1 -p "Press any key to continue ..."
}

get_user_confirm()
{
	local ret_val=1
	local yn_choice="n"

	echo ""
	read -s -e -n 1 -p "Are you sure you want to continue [y/N]: " yn_choice

	if [[ "${yn_choice,,}" == "y" ]]; then
		ret_val=0
	fi

	return $ret_val
}

get_user_variable()
{
	local var_name=$1
	local user_input

	read -e -p "Enter $2: " -i "$3" user_input
	echo ""

	declare -g "$var_name"=$user_input
}

#===========================================================================================================
# INSTALLATION FUNCTIONS
#===========================================================================================================
set_kbpermanent()
{
	print_submenu_heading "MAKE KEYBOARD LAYOUT PERMANENT"

	get_user_variable KB_CODE "keyboard layout" "it"

	echo -e "Make keyboard layout ${GREEN}${KB_CODE}${RESET} permanent."

	if get_user_confirm; then
		print_progress_text "Setting keyboard layout"
		echo KEYMAP=$KB_CODE > /etc/vconsole.conf

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

set_timezone()
{
	print_submenu_heading "CONFIGURE TIMEZONE"

	get_user_variable TIME_ZONE "timezone" "Europe/Sarajevo"

	echo -e "Set the timezone to ${GREEN}${TIME_ZONE}${RESET}."

	if get_user_confirm; then
		print_progress_text "Creating symlink for timezone"
		ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

sync_hwclock()
{
	print_submenu_heading "SYNC HARDWARE CLOCK"

	echo -e "Sync hardware clock."

	if get_user_confirm; then
		print_progress_text "Setting hardware clock to UTC"
		hwclock --systohc --utc

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

set_locale()
{
	print_submenu_heading "CONFIGURE LOCALE"

	get_user_variable LOCALE_US "language locale" "en_US"
	get_user_variable LOCALE_DK "format locale" "en_DK"

	echo -e "Set the language to ${GREEN}${LOCALE_US}${RESET} and the format locale to ${GREEN}${LOCALE_DK}${RESET}."

	if get_user_confirm; then
		print_progress_text "Setting language and format locales"
		LOCALE_US_UTF="$LOCALE_US.UTF-8"
		LOCALE_DK_UTF="$LOCALE_DK.UTF-8"

		sed -i "/#$LOCALE_US_UTF/ s/^#//" /etc/locale.gen
		sed -i "/#$LOCALE_DK_UTF/ s/^#//" /etc/locale.gen

		locale-gen

		cat > /etc/locale.conf <<-LOCALECONF
			LANG=$LOCALE_US_UTF
			LC_MEASUREMENT=$LOCALE_DK_UTF
			LC_MONETARY=$LOCALE_US_UTF
			LC_NUMERIC=$LOCALE_US_UTF
			LC_PAPER=$LOCALE_DK_UTF
			LC_TIME=$LOCALE_DK_UTF
		LOCALECONF

		export LANG=$LOCALE_US_UTF
		export LC_MEASUREMENT=$LOCALE_DK_UTF
		export LC_MONETARY=$LOCALE_US_UTF
		export LC_NUMERIC=$LOCALE_US_UTF
		export LC_PAPER=$LOCALE_DK_UTF
		export LC_TIME=$LOCALE_DK_UTF

		print_file_contents "/etc/locale.conf"

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

set_hostname()
{
	print_submenu_heading "CONFIGURE HOSTNAME"

	get_user_variable PC_NAME "hostname" "ProBook450"

	echo -e "Set the hostname to ${GREEN}${PC_NAME}${RESET}."

	if get_user_confirm; then
		print_progress_text "Setting hostname"
		echo $PC_NAME > /etc/hostname

		cat > /etc/hosts <<-HOSTSFILE
			127.0.0.1       localhost
			::1             localhost
			127.0.1.1       ${PC_NAME}.localdomain      ${PC_NAME}
		HOSTSFILE

		print_file_contents "/etc/hostname"
		print_file_contents "/etc/hosts"

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

enable_multilib()
{
	print_submenu_heading "ENABLE MULTILIB REPOSITORY"

	echo -e "Enable the multilib repository in ${GREEN}/etc/pacman.conf${RESET}."

	if get_user_confirm; then
		print_progress_text "Enabling multilib repository"
		sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf

		print_file_contents "/etc/pacman.conf"

		print_progress_text "Refreshing package databases"
		pacman -Syy

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

root_password()
{
	print_submenu_heading "CONFIGURE ROOT PASSWORD"

	echo -e "Set the password for the root user."

	if get_user_confirm; then
		passwd

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

add_sudouser()
{
	print_submenu_heading "ADD NEW USER WITH SUDO PRIVILEGES"

	get_user_variable NEW_USER "user name" "drakkar"
	get_user_variable USER_DESC "user description" "draKKar"

	echo -e "Create new user ${GREEN}${NEW_USER}${RESET} with sudo privileges."

	if get_user_confirm; then
		print_progress_text "Creating new user"
		useradd -m -G wheel -c $USER_DESC -s /bin/bash $NEW_USER

		print_progress_text "Setting password for user"
		passwd $NEW_USER

		print_progress_text "Enabling sudo privileges for user"
		bash -c 'echo "%wheel ALL=(ALL) ALL" | (EDITOR="tee -a" visudo)'

		print_progress_text "Verifying user identity"
		id $NEW_USER

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

install_bootloader()
{
	print_submenu_heading "INSTALL BOOT LOADER"

	echo -e "Install the GRUB bootloader."

	if get_user_confirm; then
		print_progress_text "Installing GRUB bootloader"
		pacman -S grub efibootmgr os-prober
		grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub

		print_progress_text "Installing microcode package"
		pacman -S intel-ucode

		print_progress_text "Generating GRUB config file"
		grub-mkconfig -o /boot/grub/grub.cfg

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

install_xorg()
{
	print_submenu_heading "INSTALL XORG GRAPHICAL ENVIRONMENT"

	echo -e "Install Xorg graphical environment."

	if get_user_confirm; then
		print_progress_text "Installing Xorg"
		echo -e "If prompted to select provider(s), select default options"
		echo ""
 		pacman -S xorg-server

		print_progress_text "Installing X widgets for testing"
		pacman -S xorg-xinit xorg-twm xterm

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

display_drivers()
{
	print_submenu_heading "INSTALL DISPLAY DRIVERS"

	echo -e "Install Mesa OpenGL, Intel VA-API (hardware accel) and Nouveau display drivers."

	if get_user_confirm; then
		print_progress_text "Installing display drivers"
		pacman -S mesa intel-media-driver xf86-video-nouveau

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

install_gnome()
{
	print_submenu_heading "INSTALL GNOME DESKTOP ENVIRONMENT"

	get_user_variable GNOME_IGNORE "GNOME packages to ignore" "epiphany,gnome-books,gnome-boxes,gnome-calendar,gnome-clocks,gnome-contacts,gnome-documents,gnome-maps,gnome-photos,gnome-software,orca,totem"

	echo -e "Install the GNOME desktop environment."

	if get_user_confirm; then
		print_progress_text "Installing GNOME"
		echo -e "If prompted to select provider(s), select default options"
		echo ""

		if [[ "$GNOME_IGNORE" != "" ]]; then
			pacman -S gnome --ignore $GNOME_IGNORE
		else
			pacman -S gnome
		fi

		print_progress_text "Enabling GDM service"
		systemctl enable gdm.service

		print_progress_text "Enabling Network Manager service"
		systemctl enable NetworkManager.service

		MAINCHECKLIST[$1]=1

		get_any_key
	fi
}

main_menu()
{
	MAINITEMS=("Make keyboard layout permanent|set_kbpermanent"
						 "Configure timezone|set_timezone"
						 "Sync hardware clock|sync_hwclock"
						 "Configure locale|set_locale"
						 "Configure hostname|set_hostname"
						 "Enable multilib repository|enable_multilib"
						 "Configure root password|root_password"
						 "Add new user with sudo privileges|add_sudouser"
						 "Install boot loader|install_bootloader"
						 "Install Xorg graphical environment|install_xorg"
						 "Install display drivers|display_drivers"
						 "Install GNOME desktop environment|install_gnome")
	MAINCHECKLIST=()

	# Initialize status array with '0'
	local i

	for i in ${!MAINITEMS[@]}; do
		MAINCHECKLIST+=("0")
	done

	# Main menu loop
	while true; do
		clear

		# Print header
		echo -e "-------------------------------------------------------------------------------"
		echo -e "-- ${GREEN} ARCH LINUX ${RESET}::${GREEN} POST INSTALL MENU${RESET}"
		echo -e "-------------------------------------------------------------------------------"

		# Print menu items
		for i in ${!MAINITEMS[@]}; do
			# Get character from ascii code (0->A,etc.)
			local item_index=$(printf "\\$(printf '%03o' "$(($i+65))")")

			local item_text=$(echo "${MAINITEMS[$i]}" | cut -f1 -d'|')

			print_menu_item $item_index ${MAINCHECKLIST[$i]} "$item_text"
		done

		# Print footer
		echo ""
		echo -e "-------------------------------------------------------------------------------"
		echo ""
		echo -e -n " => Select option or (q)uit: "

		# Get menu selection
		local main_index=-1

		until (( $main_index >= 0 && $main_index < ${#MAINITEMS[@]} ))
		do
			local main_choice

			read -r -s -n 1 main_choice

			# Exit main menu
			if [[ "${main_choice,,}" == "q" ]]; then
				clear
				echo -e "Exit the chroot environment:"
				echo ""
				echo -e "   ${GREEN}exit${RESET}"
				echo ""
				echo -e "Unmount partitions:"
				echo ""
				echo -e "   ${GREEN}umount -R /mnt/boot${RESET}"
				echo -e "   ${GREEN}umount -R /mnt/home${RESET}"
				echo -e "   ${GREEN}umount -R /mnt${RESET}"
				echo ""
				echo -e "Restart to boot into GNOME:"
				echo ""
				echo -e "   ${GREEN}reboot${RESET}"
				echo ""
				exit 0
			fi

			# Get selection index
			if [[ "$main_choice" == [a-zA-Z] ]]; then
				# Get ascii code from character (A->65, etc.)
				main_index=$(LC_CTYPE=C printf '%d' "'${main_choice^^}")
				main_index=$(($main_index-65))
			fi
		done

		# Execute function
		local item_func=$(echo "${MAINITEMS[$main_index]}" | cut -f2 -d'|')

		eval ${item_func} $main_index
	done
}

main_menu
