# nicehive (nicehash hiveos autoswitcher)
Этот проект является доработкой оригинального nicehive разработчика sadm2014
https://github.com/sadm2014/nicehive

Позволяетавтоматически переключать полетные листы в зависимости от текущего профита на nicehash

Установка
curl https://raw.githubusercontent.com/ks99999/nicehive/main/nicehive-setup.sh | bash

Далее сгенерируйте в разделе account в HiveOS API key:
и поместите его в файл на риге командой:
echo Ваш_API_key > /hive-config/nicehive.token

Перезагрузите риг.

Создайте полетники согласно правил у оригинального проекта.
Для проверки работы выполните /hive/sbin/nicehash.sh
Если есть ошибки, то возможно надо добавить ваш алгоритм в таблицу коэффициентов. 
Они указаны в самом начале nicehive.sh

Чтобы nicehive начал работать просто активируйте любой полетник для него (AUTO-XXX-YYY)
Для деактивации nicehash активируйте полетник не для него.
