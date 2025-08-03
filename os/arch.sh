# install yay (or yaourt, packer, or equiv)
# fix mirrorlist with reflector
sudo pacman -S reflector
sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# bare minimum, ag and jq, images, pdf and djavu
sudo pacman -S --noconfirm \
  rofi rofi-emoji xdotool screenfetch \
  vim git hub zip unzip tree htop wget openssh \
  the_silver_searcher jq \
  pinta scrot imagemagick vlc \
  zathura zathura-djvu zathura-pdf-mupdf \
  flameshot

# yay : fpp
yay -S fpp-git
