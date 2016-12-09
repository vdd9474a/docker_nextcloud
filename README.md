# Pour build l'image:
# Se placer dans le repertoire ou se trouve le Dockerfile

docker build -t nom_image .

# Pour la lancer :

docker run -d -p 80:80 -p 443:443 --name nom_instance -v /var/www/html/data:/var/www/html/data nom_image
# option : 
#	-p "port hote":"port docker"
#	-v "rep hote":"rep docker"

# STOP image

docker stop nom_instance

# START image

docker start nom_instance


##########################
# avec un Docker mariadb #
##########################

docker pull mariadb

docker run --name some_mariadb \
        -e MYSQL_ROOT_PASSWORD=my-secret-pw \ 
        -e MYSQL_DATABASE=nextcloud \
        -e MYSQL_USER=nextcloud \
        -e MYSQL_PASSWORD=my-other-secret-pw \
        -d mariadb
        
docker run --name nextcloud -p 80:80 -p 443:443 --link some_mariadb:nc_mariadb -v /var/www/html/data:/var/www/html/data -d my_nextcloud

# Lors du premier lancement de nextcloud, remplacer localhost par nc_mariadb