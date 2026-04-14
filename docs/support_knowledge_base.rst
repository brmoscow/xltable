Часто задаваемые вопросы (поддержка)
====================================

Справочная информация
---------------------

- https://xltable.com/
- https://xltable-olap.readthedocs.io/en/latest/

Какие минимальные системные требования для установки XLTable?
--------------------------------------------------------------

Страница документации:
https://xltable-olap.readthedocs.io/en/latest/overview.html#system-requirements

После установки отображается сообщение об отсутствии лицензии или файла xltable.lic
-------------------------------------------------------------------------------------

Необходимо загрузить файл лицензии.

1. Откройте административную панель:
   https://xltable-olap.readthedocs.io/en/latest/install.html#admin-panel
2. Перешлите ``server_id`` вендору или партнеру, который предоставил дистрибутив.
3. Полученный файл лицензии загрузите через административную панель.

Не удается подключиться к серверу XLTable из Excel
---------------------------------------------------

Признаки: ошибка подключения, таймаут или сбой на первом шаге мастера подключения.

- Проверьте подключение:
  https://xltable-olap.readthedocs.io/en/latest/excel.html
- Проведите диагностику:
  https://xltable-olap.readthedocs.io/en/latest/support.html#excel-connection-issues
- В поле сервера Excel указывайте полный URL с протоколом: ``http://...`` или ``https://...``.
- Проверьте доступ к XLTable по порту ``80/443``.

В Excel появляется сообщение о неудачном разборе XML или curl возвращает HTTP 500
-----------------------------------------------------------------------------------

- Проверьте ``settings.json`` по схеме:
  https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema
- Убедитесь, что обязательные блоки, включая ``WRITE_LOG`` и ``CREDENTIAL_DB``, присутствуют.
- После правок перезапустите сервис и проверьте подключение из Excel:
  https://xltable-olap.readthedocs.io/en/latest/excel.html

Можно ли хранить метаданные куба в одном экземпляре ClickHouse, а фактические данные - в другом?
---------------------------------------------------------------------------------------------------

Да, можно. Подключения задаются в ``settings.json`` (блок ``CREDENTIAL_DB``), а описание куба хранится в таблице ``olap_definition``.

Подробнее:

- https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections
- https://xltable-olap.readthedocs.io/en/latest/cubes.html#cube-definition-storage

Не удается подключиться к базам на сервере ClickHouse с компонента XLTable
----------------------------------------------------------------------------

- Проверьте параметры ``CREDENTIAL_DB`` (``host``, ``port``, ``secure``):
  https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections
- Если ClickHouse принимает только TLS/HTTPS, установите на сервер XLTable корректную цепочку сертификатов и повторите подключение.

Где в настройках указывается конкретная база данных ClickHouse?
---------------------------------------------------------------

Нужная база и параметры подключения задаются в ``settings.json``, блок ``CREDENTIAL_DB``:

- https://xltable-olap.readthedocs.io/en/latest/install.html#database-connections
- https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema

Если таблицы ``olap_definition`` нет, создайте ее по примеру:
https://xltable-olap.readthedocs.io/en/latest/cubes.html#cube-definition-storage

Как увидеть SQL-запросы, которые XLTable отправляет в ClickHouse?
------------------------------------------------------------------

- Включите ``WRITE_LOG=true`` в ``settings.json``
- Перезапустите сервис
- Проверьте логи XLTable:
  - https://xltable-olap.readthedocs.io/en/latest/support.html#enable-logging
  - https://xltable-olap.readthedocs.io/en/latest/reference.html#settings-json-schema
- Дополнительно можно искать запросы в ClickHouse через ``system.query_log`` с меткой ``log_comment``.

Данные в хранилище обновляются часто; нужно обновить кэш. Планируется ли настраиваемое время жизни кэша?
-----------------------------------------------------------------------------------------------------------

Используйте два штатных способа:

- обновление в Excel (``Refresh/Refresh All``)
- очистка кэша через административную панель (``Clear Cache``)

Документация:

- https://xltable-olap.readthedocs.io/en/latest/excel.html#refreshing-data
- https://xltable-olap.readthedocs.io/en/latest/install.html#admin-panel

Длительное выполнение или таймаут в Excel; в ClickHouse view медленно, а физическая таблица быстрее
-----------------------------------------------------------------------------------------------------

- Включите логирование и проверьте фактический SQL
- Сократите набор полей и измерений в модели и в сводной таблице
- Для тяжелых источников используйте более узкие представления или материализованные таблицы ClickHouse

Почему число строк в результате XLTable больше, чем в другой аналитической системе при схожей визуальной настройке отчета?
----------------------------------------------------------------------------------------------------------------------------

Число строк может отличаться из-за разной детализации результата: в XLTable в выборку могут входить промежуточные итоги, а не только листовой уровень.

Сравнивайте системы при одинаковых:

- измерениях
- фильтрах
- уровне итогов

Как формируется SQL:
https://xltable-olap.readthedocs.io/en/latest/cubes.html#sql-generation-logic

Служба XLTable не запускается автоматически после перезагрузки сервера
-----------------------------------------------------------------------

- Проверьте управление сервисом:
  https://xltable-olap.readthedocs.io/en/latest/install.html#service-management
- На Linux базовый сценарий - ``supervisor``:
  - статус: ``sudo supervisorctl status olap``
  - логи: ``sudo supervisorctl tail olap``
  - права на запуск бинарного файла

Какие доступы обычно нужны подрядчику для настройки куба?
----------------------------------------------------------

Обычно нужны:

- SSH/админ-доступ к серверу XLTable
- доступ XLTable к ClickHouse
- права на таблицу ``olap_definition`` для загрузки и обновления куба
- сетевой доступ пользователей Excel к XLTable по ``80/443`` (или через VPN)

По шагам:

- https://xltable-olap.readthedocs.io/en/latest/install.html
- https://xltable-olap.readthedocs.io/en/latest/excel.html

Клиент мигрирует с Microsoft SQL Server и SQL Server Analysis Services; можно ли не создавать лишние объекты в ClickHouse?
-----------------------------------------------------------------------------------------------------------------------------

Да, можно сократить количество промежуточных объектов в ClickHouse: часть логики переносится в определение куба XLTable (SQL + теги).

Ссылки:

- Сравнение с SSAS:
  https://xltable-olap.readthedocs.io/en/latest/overview.html#comparison-with-ssas
- Правила описания куба:
  https://xltable-olap.readthedocs.io/en/latest/cubes.html

Нужно объединить в одном измерении два атрибута из разных таблиц; при построении возникает ошибка
----------------------------------------------------------------------------------------------------

Для атрибутов из разных таблиц создавайте отдельные измерения и связывайте источники через ``LEFT JOIN`` в определении куба.

Рабочий пример (Unified example):
https://xltable-olap.readthedocs.io/en/latest/reference.html#unified-example

В ClickHouse нельзя вкладывать оконные функции в агрегаты так же, как в MDX на платформе Microsoft; требуется повторить многошаговую логику меры
-----------------------------------------------------------------------------------------------------------------------------------------------------

Для многошаговой логики меры используйте Jinja в определении куба: так можно подставлять фильтры и изменять SQL до выполнения запроса.

Подробно в документации:

- https://xltable-olap.readthedocs.io/en/latest/cubes.html#jinja-scripts
- https://xltable-olap.readthedocs.io/en/latest/reference.html#jinja-context-variables

Стоимость лицензий и длительность тестового периода
----------------------------------------------------

Информация о ценах:
https://xltable.com/#pricing

Доступна ли пробная установка на Microsoft Windows; зачем нужен сервер под Windows?
-------------------------------------------------------------------------------------

Да, дистрибутив для Windows Server доступен по запросу.

Инструкция по установке:
https://xltable-olap.readthedocs.io/en/latest/install.html#windows

Для пилота обычно проще Linux-развертывание. Windows выбирают, когда по ИТ-политике нужен IIS и доменный контур Microsoft.
