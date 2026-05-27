#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "Welcome to the theme setup process\n\n"

echo "Checking dependencies..."
if ! command -v pacman &>/dev/null; then
  echo "Pacman not found... This script is for Arch-based systems only. Please install Arch (or ur cringe)" >&2
  exit 1
fi

verifypacman=(qt5ct qt6ct papirus-icon-theme catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd)
verifyaur=(darkly-bin)
notpacman=()
notaur=()

for item in "${verifypacman[@]}"; do
  if ! pacman -Q "$item" &> /dev/null; then
    notpacman+=("$item")
  fi
done
for item in "${verifyaur[@]}"; do
  if ! pacman -Q "$item" &> /dev/null; then
    notaur+=("$item")
  fi
done

if [ ${#notpacman[@]} -ne 0 ]; then
  echo "You seem to be missing some potentially wanted dependencies from the official repos:"
  for item in "${notpacman[@]}"; do
    echo "$item"
  done
  echo
  read -r -p "Would you like to install them now? [Y/n]" confirm
  case "$confirm" in
    [nN]*)
      echo "Skipping installation..."
      ;;
    *)
      echo "Now installing..."
      sudo pacman -S --noconfirm "${notpacman[@]}"
      ;;
  esac
else
  echo "All official repo dependencies already installed!"
fi

if [ ${#notaur[@]} -ne 0 ]; then
  echo "You seem to be missing some potentially wanted dependencies from the aur:"
  for item in "${notaur[@]}"; do
    echo "$item"
  done
  echo
  read -r -p "Would you like to install them now? [Y/n] " confirm
  case "$confirm" in
    [nN]*)
      echo "Skipping installation..."
      ;;
    *)
      echo "Now installing..."
      if command -v yay &>/dev/null; then
        yay -S --noconfirm "${notaur[@]}"
      elif command -v paru &>/dev/null; then
        paru -S --noconfirm "${notaur[@]}"
      else
        echo "No AUR helper found (yay/paru). Install AUR packages manually: ${notaur[*]}"
      fi
      ;;
  esac
else
  echo "All aur dependencies already installed!"
fi


echo "Checking config folder..."
configd="$HOME/.config"
folders=("qt5ct" "qt6ct" "gtk-3.0" "gtk-4.0")
existing=()

for item in "${folders[@]}"; do
  if [ -d "$configd/$item" ]; then
    existing+=("$configd/$item")
  fi
done

if [ ${#existing[@]} -ne 0 ]; then
  echo "Looks like you already have some config folders set up:"
  for item in "${existing[@]}"; do
    echo "$item"
  done
  echo
  read -r -p "Would you like to remove them? [y/N] " confirm
  case "$confirm" in
    [yY]*)
      echo "Removing files now..."
      rm -rf -- "${existing[@]}"
      ;;
    *)
      echo "Ok, we'll just install the ones we can."
      ;;
  esac
else 
  echo "All good! you don't seem to have config folders already set up."
fi

echo "Now creating symbolic links between this folder and the config folder."

for i in "${folders[@]}"; do
  src="$SCRIPT_DIR/$i"
  dest="$configd/$i"

  if [ ! -e "$src" ]; then
    echo "Warning: source '$src' does not exist, skipping."
    continue
  fi

  if [ -L "$dest" ]; then
    ln -sfn "$src" "$dest"
    echo "Updated symlink: $dest -> $src"
  elif [ -e "$dest" ]; then
    echo "Skipping '$dest' because it already exists and is not a symlink."
  else
    ln -s "$src" "$dest"
    echo "Created symlink: $dest -> $src"
  fi
done

echo "Finished making links, if you move this folder, please remember to re-run this script"
echo "Current folder location: $SCRIPT_DIR"
echo "All done!"
