FROM ubuntu:20.04

USER root
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt -y update && \
    apt -y install apache2 && \
    apt -y install php libapache2-mod-php php-mysql php-curl php-gd php-json php-zip php-mbstring wget

RUN wget https://wordpress.org/latest.tar.gz

RUN tar -xzf latest.tar.gz

RUN cp -r wordpress/* /var/www/html/

RUN rm -rf latest.tar.gz

RUN rm -rf wordpress/

WORKDIR /var/www/html
RUN rm -rf index.html
RUN chmod -R 755 wp-content
RUN chown -R www-data:www-data wp-content

COPY ./efs/container-ssl/certificate.crt /root/
COPY ./efs/container-ssl/private.key /root/
COPY ./efs/container-ssl/ca_bundle.crt /root/
COPY ./efs/container-ssl/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
COPY ./efs/wp-config/wp-config.php /var/www/html/

RUN echo '. /etc/apache2/envvars' > /root/run_apache.sh && \
 echo 'mkdir -p /var/run/apache2' >> /root/run_apache.sh && \
 echo 'mkdir -p /var/lock/apache2' >> /root/run_apache.sh && \ 
 echo 'a2enmod ssl' >> /root/run_apache.sh && \
 echo 'a2ensite default-ssl.conf' >> /root/run_apache.sh && \
 echo '/usr/sbin/apache2 -D FOREGROUND' >> /root/run_apache.sh && \ 
 chmod 755 /root/run_apache.sh

EXPOSE 80 443 3306

CMD /root/run_apache.sh