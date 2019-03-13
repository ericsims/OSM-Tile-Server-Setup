#!/bin/bash

set -x

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get install curl

sudo useradd -m tileserver sudo
sudo usermod -aG sudo tileserver
echo "1234
1234" | sudo passwd tileserver


echo "password for tileserver is now 1234"

sudo su - tileserver <<HERE

sudo apt-get install -y git

echo "Old freetype version:"
dpkg -l|grep freetype6

sudo add-apt-repository -y ppa:no1wantdthisname/ppa
sudo add-apt-repository -y ppa:talaj/osm-mapnik
sudo apt-get update 
sudo apt-get install -y libfreetype6 libfreetype6-dev

echo "Updated freetype version:"
dpkg -l | grep freetype6

sudo apt-get install -y git autoconf libtool libxml2-dev libbz2-dev \
  libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal-dev g++ \
  libmapnik-dev mapnik-utils python-mapnik

sudo apt-get install -y libboost-all-dev

sudo apt-get install -y libharfbuzz-dev

echo "mapnik version"
mapnik-config -v

sudo apt-get install -y apache2 apache2-dev

sudo service apache2 start

sudo sh -c 'echo "AcceptFilter http none" >> /etc/apache2/apache2.conf'
echo "does it apache work?"
curl localhost| grep 'It works!'


sudo add-apt-repository -y ppa:osmadmins/ppa
sudo apt-get update

sudo apt-get install -y libapache2-mod-tile

sudo apt-get install -y python-yaml
sudo apt-get install -y python-pip

sudo apt-get install -y mapnik-utils

# now we get carto
mkdir -p ~/src
cd ~/src
git clone https://github.com/gravitystorm/openstreetmap-carto.git
cd openstreetmap-carto

sudo apt-get install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont

cd ~/src
git clone https://github.com/googlei18n/noto-emoji.git
git clone https://github.com/googlei18n/noto-fonts.git
sudo cp noto-emoji/fonts/NotoColorEmoji.ttf /usr/share/fonts/truetype/noto
sudo cp noto-emoji/fonts/NotoEmoji-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansArabicUI-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoNaskhArabicUI-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansArabicUI-Bold.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoNaskhArabicUI-Bold.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansAdlam-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansAdlamUnjoined-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansChakma-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansOsage-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansSinhalaUI-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansArabicUI-Regular.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansCherokee-Bold.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansSinhalaUI-Bold.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansSymbols-Bold.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/hinted/NotoSansArabicUI-Bold.ttf /usr/share/fonts/truetype/noto
sudo cp noto-fonts/unhinted/NotoSansSymbols2-Regular.ttf /usr/share/fonts/truetype/noto
sudo apt install fontconfig
sudo fc-cache -fv
fc-list
fc-list | grep Emoji

sudo apt-get install -y fonts-dejavu-core

cd ~/src
cd openstreetmap-carto
scripts/get-shapefiles.py


# install nodejs
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - && sudo apt-get install -y nodejs
node -v
nodejs -v
npm -v
sudo npm install -g carto

cd ~/src
cd openstreetmap-carto
carto -a "3.0.20" project.mml > style.xml
ls -l style.xml

# env vars
export PGHOST=localhost
export PGPORT=5432
export PGUSER=postgres
export PGPASSWORD=1234

# install psql

sudo apt-get update
sudo apt-get install -y postgresql
sudo service postgresql start

sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password '1234';"


# setup db
export PGPASSWORD=1234
HOSTNAME=localhost # set it to the actual ip address or host name
psql -U postgres -h $HOSTNAME -c "CREATE DATABASE gis ENCODING 'UTF-8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8' TEMPLATE template0"
sudo service postgresql restart
sudo mkdir /mnt/db # Suppose this is the tablespace location
sudo chown postgres:postgres /mnt/db
psql -U postgres -h $HOSTNAME -c "CREATE TABLESPACE gists LOCATION '/mnt/db'"
psql -U postgres -h $HOSTNAME -c "ALTER DATABASE gis SET TABLESPACE gists"
psql -U postgres -h $HOSTNAME -c "\connect gis"
psql -U postgres -h $HOSTNAME -d gis -c "CREATE EXTENSION postgis"
psql -U postgres -h $HOSTNAME -d gis -c "CREATE EXTENSION hstore"
sudo -u postgres psql -U postgres -c "create user tileserver;grant all privileges on database gis to tileserver;"

# Install Osm2pgsql
sudo apt-get install ppa-purge && sudo ppa-purge -y ppa:osmadmins/ppa # This if you need to downgrade osm2pgsql to the stock version
sudo apt-get install -y osm2pgsql


# now we need to get some maps...
wget -c https://download.geofabrik.de/north-america/us/connecticut-latest.osm.pbf

sudo sysctl -w vm.overcommit_memory=1

cd ~/src
cd openstreetmap-carto
HOSTNAME=localhost # set it to the actual ip address or host name
osm2pgsql -s -C 300 -c -G --hstore --style openstreetmap-carto.style --tag-transform-script openstreetmap-carto.lua -d gis -H $HOSTNAME -U postgres ../*.pbf

HOSTNAME=localhost # set it to the actual ip address or host name
cd ~/src
cd openstreetmap-carto
scripts/indexes.py | psql -U postgres -h $HOSTNAME -d gis

wget https://raw.githubusercontent.com/openstreetmap/osm2pgsql/master/install-postgis-osm-user.sh
chmod a+x ./install-postgis-osm-user.sh
sudo ./install-postgis-osm-user.sh gis tileserver


# configure renderd...
sudo sed -i 's#^plugins_dir=.*#plugins_dir=/usr/lib/mapnik/3.0/input#g' /etc/renderd.conf
sudo sed -i 's#^font_dir=.*#font_dir=/usr/share/fonts#g' /etc/renderd.conf
sudo sed -i 's#^font_dir_recurse=.*#font_dir_recurse=true#g' /etc/renderd.conf
sudo sed -i 's#^XML=.*#XML=/home/tileserver/src/openstreetmap-carto/style.xml#g' /etc/renderd.conf
sudo sed -i 's#^;HOST=.*#HOST=localhost#g' /etc/renderd.conf
sudo sed -i 's#^HOST=.*#HOST=localhost#g' /etc/renderd.conf
sudo sed -i 's#^URI=.*#URI=/osm_tiles/#g' /etc/renderd.conf

sudo sed -i 's#^DAEMON=.*#DAEMON=/usr/bin/$NAME#g' /etc/init.d/renderd
sudo sed -i 's#^DAEMON_ARGS=.*#DAEMON_ARGS="-c /etc/renderd.conf"#g' /etc/init.d/renderd
sudo sed -i 's#^RUNASUSER=.*#RUNASUSER=tileserver#g' /etc/init.d/renderd

sudo chown tileserver /var/run/renderd

sudo systemctl daemon-reload

sudo systemctl start renderd

sudo systemctl enable renderd
sudo service renderd start

# apache
sudo sh -c 'echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" > /etc/apache2/mods-available/mod_tile.load'
sudo ln -s /etc/apache2/mods-available/mod_tile.load /etc/apache2/mods-enabled/
sudo systemctl restart apache2

# check to see if we can get a tile
echo "can we get a tile?"
wget --spider http://localhost/osm_tiles/0/0/0.png

HERE
