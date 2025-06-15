# Ochoba
### Установка библиотек:

* Рекомендуемая версия perl: 5.12+


### Доустановка библиотек:

<pre>
cpan

install JSON::XS DateTime MongoDB Cache::Memcached::Fast FCGI::ProcManager Image::Size GD

install MongoDB
</pre>
### Создаём папку бд:
<pre>
mkdir /data

mkdir /data/db
</pre>
### добавляем в автозагрузку:
<pre>
/mongo/mongod --fork --logpath /dev/null --logappend

memcached -d -u nobody -m 512

/usr/local/nginx/sbin/nginx
</pre>
### реаплексор
<pre>
cd /etc/realplexor/

perl dklab_realplexor.pl
</pre>
<pre>
####################################################

# Возможно придётся доустанавливать это:

# DateTime: sudo apt-get install libdatetime-perl

# cpan

# notest install Cache::Memcached::Fast

# install DateTime

# install YAML

####################################################
</pre>
# Запуск после ребута:
<pre>
memcached -d -u nobody -m 512

/usr/local/nginx/sbin/nginx

perl /realplexor/dklab_realplexor.pl
</pre>
# Mongo
Иногда делать бекапы, data/db

Если в папке `/data/db` сотается `mongod.lock` запусать `/mongo/mongod --repair`

После запускаете `/mongo/mongod --fork --logpath /dev/null --logappend`

Как выключать базу [Подробно](https://web.archive.org/web/20120524005351/http://www.mongodb.org/display/DOCS/Starting+and+Stopping+Mongo)

запустить `/mongo/mongo` - консоль монги

`$ ./mongo`

`use admin`

`db.shutdownServer()`

`/mongo/mongod --fork --logpath /dev/null --logappend` - включать

`/mongo/mongo`

`use admin`

`db.shutdownServer()` - выключать

`/mongo/mongod --repair` - всосстанавливать если не включается

Можно просто `mongod.lock` из `/data/db` удалять но есть риск что база может быть битая

Имеется `mongodump` в папке монги. Запускаешь и он беквапит

# Очоба
Скрипт запуска очобы - `w.pl`

`#perl w.pl` - запуск в обычном режиме

`#perl w.pl &` - запуск в фоновом

`#perl w.pl d`- демонизация

`#perl w.pl d количество_ворекров` - демонизация, запуск заданного числа воркеров

Пример запуска очобы:

`root@nyaka:~# cd /var/www/desuchan`

`root@nyaka:/var/www/desuchan# perl w.pl`

После этого вы должны увидеть `Ochoba loaded!`

Убить: `ps aux` - находите процесс `perl-fcgi-pm` и убиваешь его по `pid` ( пример: `kill 32306` )

Или же можно использовать `htop/singkill`

убивайте `perl-fcgi-pm` а не `perl-fcgi`. если убить `perl-fcgi` то менеджер `perl-fcgi-pm` запустить нового. убивайте менеджера, он заодно процессы закроет

Полезное
Конфиг: `config.pl`


Админка: `http://site.ru/b/adminlogin.pl?podpassword=ваш пасс с config.pl`

Пример nginx конфига
<pre>
server { # быстрая подгрузка постов
        server_name comet.desuchan.ru;
        charset utf-8;
        location / {
            proxy_pass http://127.0.0.1:8088;
        }
    }
    ############ ochoba #######
server {
        server_name localhost desuchan.ru www.desuchan.ru;
        
        charset utf-8;
        location / {
            root /var/www/desuchan;
            rewrite '^/([A-z]{1,3})/?$' /$1/0.memhtml redirect;
            index index.html index.htm;
        }
        
        location ~ \.memhtml$ { # перенаправление в мемкеш
                memcached_pass 127.0.0.1:11211;
                set $memcached_key $document_uri;
                memcached_connect_timeout 1s;
                memcached_read_timeout 1s;
                default_type text/html;
                error_page 404 = @fallback;
                }
                
        location @fallback { # если в мемкеше не нашли - скатываемся сюда
                fastcgi_pass localhost:9000;
                include fastcgi_params;
        }        
                        
        location ~ \.pm$ { # а нечего исходники скачивать
                deny all;
                }
        location ~ \.f?pl$ { # передаем управлеение fcgi
                fastcgi_pass localhost:9000;
                include fastcgi_params;
        }
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /var/www/desuchan;
        }
}
</pre>
_Оригинальный readme: https://web.archive.org/web/20120516120758/https://wakaba.ru/ochoba.html_

© 2012
