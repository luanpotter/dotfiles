# install yay (or yaourt, packer, or equiv)
# fix mirrorlist with reflector
sudo pacman -S reflector
reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# bare minimum
sudo pacman -S vim git hub unzip tree wget openssh

# ag, jq
sudo pacman -S the_silver_searcher jq

# fpp
yay -S fpp-git

# postman
yay -S postman

# images
sudo pacman -S pinta scrot imagemagick

# pdf, djvu
sudo pacman -S zathura zathura-djvu zathura-pdf-mupdf