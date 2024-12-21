# thesis-work
## Дипломная работа по профессии «Системный администратор»-Рустам Ахмадеев
- Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в Yandex Cloud и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git.

Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.

Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.
Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.
Виртуальные машины не должны обладать внешним Ip-адресом, те находится во внутренней сети. Доступ к ВМ по ssh через бастион-сервер. Доступ к web-порту ВМ через балансировщик yandex cloud.

Настройка балансировщика:
Создайте Target Group, включите в неё две созданных ВМ.
Создайте Backend Group, настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.
Создайте HTTP router. Путь укажите — /, backend group — созданную ранее.
Создайте Application load balancer для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.
Протестируйте сайт curl -v <публичный IP балансера>:80

Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix.
Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.
Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.
Настройте Security Groups соответствующих сервисов на входящий трафик только к нужным портам.
Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Эта вм будет реализовывать концепцию bastion host . Синоним "bastion host" - "Jump host". Подключение ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью ProxyCommand . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)
Исходящий доступ в интернет для ВМ внутреннего контура через NAT-шлюз.

Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.


Дополнительно
Не входит в минимальные требования.
Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте Yandex Managed Service for PostgreSQL. Разверните кластер из двух нод с автоматическим failover.
Вместо конкретных ВМ, которые входят в target group, можно создать Instance Group, для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

## Выполнение задания:
1. В yandex cloud создан новый каталог diplom с сервисным аккаунтом ahmrust и ролью admin,editor. Вместо IAM-токена создан API-ключ для упрощенной аутентификации и сохранен в рабочий каталог проекта.

2. Написан манифест terraform main.tf, создающий в yandex cloud следующие ресурсы:

2.1 Виртуальные машины (прерываемые) 
- nginx-1
- nginx-2
- bastion host
- elastic
- kibana
- zabbix-server.

Публичные ip адреса kibana, bastion и zabbix-server будут выведены в терминал 

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/1.png) 
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/2.png)

2.2 Сеть и подсети в разных зонах 
- nginx-1 (192.168.10.10 в ru-central1-a)
- nginx-2 (192.168.20.10 в ru-central1-b)
- bastion-host (192.168.30.30 в ru-central1-d)
- elastic (192.168.40.10 в ru-central1-d)
- kibana (192.168.30.20 в ru-central1-d)
- zabbix-server (192.168.30.10 в ru-central1-d)

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/3.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/4.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/5.png)

2.3 NAT-шлюз для доступа во внутреннюю сеть

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/6.png) 

2.4 Группы безопасности соответствующих сервисов на входящий трафик только к нужным портам
- bastion-sg (доступ открыт на 22 порт)
- elastic-sg (доступ открыт на 22, 10050, 9200 порты)
- kibana-sg (доступ открыт на 22, 10050, 5601 порты)
- nginx-sg (доступ открыт на 22, 80, 10050 порты)
- zabbix-sg (доступ на 22, 8080, 10051 порты)

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/7.png)

2.5 Балансировщик нагрузки для распределения запросов на сайт и обеспечения безопасности

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/8.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/9.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/10.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/11.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/12.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/13.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/27.png)

3. Дальнейшая установка и настройка  web-серверов, elasticsearch, zabbix производилась по ssh через bastion host плейбуками Ansible после написания inventory.ini

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/16.png)


3.1 Установка nginx-1, nginx-2

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/14.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/18.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/19.png)

3.2 Установка elasticsearch, kibana, filebeat производилась из заранее скачанных с зеркала deb.пакетов. Во время установки автоматически корректируется шаблон для установки filebeat (вносится пароль elastic в filebeat.yml.j2), а также в терминал выводится информация об успешности запуска сервиса и пароль пользователя и токен для подключения kibana

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/15.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/17.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/20.png)

3.3 Установка zabbix-server, zabbix-agent

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/21.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/22.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/23.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/24.png)


4. Резервное копирование

4.1 Для резервного копирования был написан манифест terraform snapshot.tf, ограничивающий время жизни snaphot в неделю. Сами snapshot настроены на ежедневное копирование. 

![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/25.png)
![alt text](https://github.com/ahmrust/thesis-work/blob/main/img/26.png)

### Инфраструктура готова к эксплуатации
P.S. На некоторых скриншотах возможно зафиксированы неверные публичные ip адреса, т.к. работа выполнялась с остановкой виртуальных машин с последующей сменой публичных адресов.
На момент перевода виртуальных машин в разряд непрерываемых были получены следующие публичные адреса:
- bastion 84.201.181.19
- kibana 130.193.59.222
- zabbix-server 51.250.47.145
- balancer 158.160.144.182
