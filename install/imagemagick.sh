set -ex

im_download_path=$(curl -sf http://www.imagemagick.org/download/releases/ | grep -o "ImageMagick-$IM_VERSION-.*.tar.gz" -m 1)
curl -f "http://www.imagemagick.org/download/releases/$im_download_path" > ImageMagick.tar.gz
tar xzf ImageMagick.tar.gz
cd ImageMagick-*
./configure --prefix=/usr
sudo make install
