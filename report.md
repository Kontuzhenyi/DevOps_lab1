Запуск скрипта руками
./weather_to_html.sh 

Право на запуск для скрипта
chmod +x /home/viktor/weather_to_html.sh

Добавляем в cron
sudo crontab -e
* * * * * /usr/bin/env bash /home/viktor/weather_to_html.sh Perm /var/www/html/index.html >>/tmp/weather_root.log 2>&1

Ошибки будут записываться туда же куда и основной поток
2>&1
