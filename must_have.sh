# install yay (or yaourt, packer, or equiv)
# fix mirrorlist with reflector
sudo pacman -S reflector
sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# bare minimum, ag and jq, images, pdf and djavu
sudo pacman -S --noconfirm \
  vim git hub zip unzip tree wget openssh \
  the_silver_searcher jq \
  pinta scrot imagemagick vlc \
  zathura zathura-djvu zathura-pdf-mupdf

# yay : fpp and postman
yay -S postman fpp-git
