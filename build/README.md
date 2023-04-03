# get source content

```bash
docker run -it --name tmpdispatchersdk -e AEM_HOST=localhost -e AEM_PORT=4502 --rm adobe/aem-cs/dispatcher-publish:2.0.169 sh

docker cp tmpdispatchersdk:/usr/lib/apache2/mod_qos.so ./modules/mod_qos.so
docker cp tmpdispatchersdk:/usr/lib/apache2/mod_security2.so ./modules/mod_security2.so
docker cp tmpdispatchersdk:/usr/lib/apache2/mod_dispatcher.so ./modules/mod_dispatcher.so


docker cp tmpdispatchersdk:/docker_entrypoint.d ./source/docker_entrypoint.d
docker cp tmpdispatchersdk:/docker_entrypoint.sh ./source/docker_entrypoint.sh
mkdir .\source\etc\httpd
docker cp tmpdispatchersdk:/etc/httpd ./source/etc/httpd

mkdir ./source/usr/local/bin
docker cp tmpdispatchersdk:/usr/local/bin/validator ./source/usr/local/bin/validator

mkdir ./source/usr/sbin/
docker cp tmpdispatchersdk:/usr/sbin/httpd-foreground ./source/usr/sbin/httpd-foreground
docker cp tmpdispatchersdk:/usr/sbin/httpd-test ./source/usr/sbin/httpd-test
docker cp tmpdispatchersdk:/usr/sbin/httpd-reload-monitor ./source/usr/sbin/httpd-reload-monitor
docker cp tmpdispatchersdk:/usr/sbin/httpd-reload ./source/usr/sbin/httpd-reload

mkdir ./source/scripts
docker cp tmpdispatchersdk:/scripts/is_alive.sh  ./source/scripts/is_alive.sh
docker cp tmpdispatchersdk:/scripts/is_ready.sh  ./source/scripts/is_ready.sh

```

