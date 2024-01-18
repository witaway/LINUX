![[Shell scripting.pdf]]

---

# Задание 1 - читаем скрипты

1. Выводит "Is true", если UID=0 (root), иначе "No."
2. Выводит числа от 46 (не 45, поскольку в начале первой итерации `a` инкрементируется) вплоть до 40 (поскольку для `a` > 40 происходит `break`) и пропускает число 32 (42 не пропускается, потому что мы уже выйдем из цикла через break)

# Задание 2 - меняем приглашение терминала

Отредактируем `~/.bashrc`, добавив в конец следующую строку:

```bash
PS1='\t : \u@\H : \w\ $ '
```

Переменная `PS1` означает содержимое приветствия терминала.

Если переменная `PS1` уже где-то задавалась, можно и заменить, но так будет сложнее откатиться.

В документации `man bash` (секция `PROMPTING`) можно посмотреть, что означает каждый из экранируемых символов:

![[Pasted image 20240115042438.png | center | 800]]

# Задание 3 -  пишем дископеречислятор

```bash
#!/bin/bash

echo "Hard Disk Information:"

# Display information for each hard disk
for disk in $(lsblk -o NAME -n | grep -E '^([s|h|xv]d[a-z]+|[vhs]d[a-z]+|[nvm]vme[0-9]n[0-9]+)$'); do
    echo "----------------------------------------"
    echo "Device: /dev/$disk"

    # Disk size
    size=$(lsblk -o SIZE -n -d /dev/$disk)
    echo "Size: $size"

    # Mounted partitions
    mounted_partitions=$(lsblk -o MOUNTPOINT -n /dev/$disk | grep -v '^$' | tr '\n' ' ')
    if [ -n "$mounted_partitions" ]; then
        echo "Mounted Partitions: $mounted_partitions"
    else
        echo "Mounted Partitions: None"
    fi
done
```

# Задание 4 - пишем файлоудалятор

```bash
#!/bin/bash

# Requesting the filename from the user
read -p "Enter the filename to delete: " filename

# Checking if the file exists
if [ ! -e "$filename" ]; then
    echo "File $filename does not exist."
    exit 1
fi

# Requesting confirmation from the user with a clear prompt
read -p "Are you sure you want to delete the file $filename? (y/n):" confirmation

# Checking the confirmation
if [ "$confirmation" != "y" ]; then
    echo "Deletion canceled."
    exit 0
fi

# Checking if the user has the necessary permissions to delete the file
if [ ! -w "$filename" ]; then
    echo "You do not have the necessary permissions to delete the file $filename."
    exit 2
fi

# Deleting the file
rm "$filename"
echo "File $filename successfully deleted."
exit 0

```


# Задание 5 - пишем число-оператор (калькулятор)

**Примечания:**
1. В моём скрипте использован пакет `bc`. Он предоставляет функционал работы с числовыми выражениями. Возможно, его придётся доустановить в систему.
2. На самом деле, bash тоже поддерживает арифметику - но только целочисленную. Если нас это устраивает, синтаксис будет выглядеть так:
	1. `echo $(($1 + $2))`
	2. `echo $(($1 - $2))`
	3. `echo $(($1 * $2))`
	4. `echo $(($1 / $2))`

```bash
#!/bin/bash

add() {
    echo "$1 + $2" | bc
}

subtract() {
    echo "$1 - $2" | bc
}

multiply() {
    echo "$1 * $2" | bc
}

divide() {
    if [ "$2" -eq 0 ]; then
        echo "Error: Division by zero."
    else
        echo "scale=2; $1 / $2" | bc
    fi
}

# Проверка наличия аргументов
if [ "$#" -eq 0 ]; then
    # Запрос чисел и оператора от пользователя
    read -p "Enter the first number: " num1
    read -p "Enter the second number: " num2
    read -p "Enter the operation (+, -, *, /): " operator
else
    # Использование переданных аргументов
    num1=$1
    num2=$2
    operator=$3
fi

case "$operator" in
    "+")
        result=$(add "$num1" "$num2")
        ;;
    "-")
        result=$(subtract "$num1" "$num2")
        ;;
    "*")
        result=$(multiply "$num1" "$num2")
        ;;
    "/")
        result=$(divide "$num1" "$num2")
        ;;
    *)
        echo "Error: Invalid operator."
        exit 1
        ;;
esac

echo "Result: $result"
```

# Задание 6 - пишем дато-проверятор

**Примечание.** 

В ходе тестирования скрипта я попробовал ввести значение `03:03:0865` - использовать значения с ведущими нулями и получил ошибку: `./date_checker.sh: line 17: ((: 0865: value too great for base (error token is "0865")`.

По умолчанию bash интерпретирует числа, начинающиеся с нуля, как восьмеричные, а не десятичные. В случае с восьмеричными числами, `8` и `9` являются недопустимыми цифрами, что и привело к ошибке.

Чтобы избежать этой проблемы, использован синтаксис `10#`, чтобы явно указать на интерпретацию строки в качестве десятичного числа, независимо от ведущих нулей.

Это решение можно наблюдать начиная со строки 16.

```bash
#!/bin/bash

# Функция для проверки введенной даты
is_valid_date() {
    local date_str=$1

    # Регулярное выражение для проверки формата даты
    local date_pattern='^[0-9]{2}:[0-9]{2}:[0-9]{4}$'

    if ! [[ $date_str =~ $date_pattern ]]; then
        return 1
    fi

    IFS=':' read -r day month year <<< "$date_str"

    # Убираем ведущие нули
    day=$((10#$day))
    month=$((10#$month))
    year=$((10#$year))

    # Проверка корректности значений дня, месяца и года
    if ((day < 1 || day > 31 || month < 1 || month > 12 || year < 1000)); then
        return 1
    fi

    # Проверка корректности числа дней в месяце
    days_in_month=(0 31 28 31 30 31 30 31 31 30 31 30 31)

    if ((month == 2 && ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)))); then
        days_in_month[2]=29
    fi

    if ((day > days_in_month[month])); then
        return 1
    fi

    return 0
}

# Проверка наличия аргументов командной строки
if [ "$#" -eq 0 ]; then
    # Получаем ввод от пользователя
    read -p "Enter date in format dd:mm:yyyy: " date_input
else
    # Используем дату из аргументов командной строки
    date_input=$1
fi


# Проверяем введенную дату
if is_valid_date "$date_input"; then
    echo "Entered date is correct."
else
    echo "Entered date is incorrect"
fi
```

# Задание 7 - пишем число-строкатор

```bash
#!/bin/bash

number_to_text() {
    case $1 in
        0) echo "ноль" ;;
        1) echo "один" ;;
        2) echo "два" ;;
        3) echo "три" ;;
        4) echo "четыре" ;;
        5) echo "пять" ;;
        6) echo "шесть" ;;
        7) echo "семь" ;;
        8) echo "восемь" ;;
        9) echo "девять" ;;
        10) echo "десять" ;;
        11) echo "одиннадцать" ;;
        12) echo "двенадцать" ;;
        *) echo "Некорректное число" ;;
    esac
}

if [ "$#" -eq 0 ]; then
    read -p "Enter number in range 0..12: " user_input
else
    user_input=$1
fi

echo $(number_to_text "$user_input")
```

# Задание 8 - пишем калькулятор факториала

**Примечание.**

В bash нет поддержки длинной арифметики по-умолчанию, поэтому для слишком больших числах (экспериментально я выяснил, что на моей 64-битной системе этот факториал 20) мы выходим в переполнение. Поэтому в код добавлена соответствующая проверка.

Диапазон integer в bash тоже не гарантирован и зависит от битности системы.

```bash
#!/bin/bash

factorial() {
    if [ "$1" -eq 0 ]; then
        echo 1
    else
        echo $(( $1 * $(factorial $(( $1 - 1 ))) ))
    fi
}

if [ "$#" -eq 0 ]; then
    read -p "Enter a number to calculate the factorial: " user_input
else
    user_input=$1
fi

if [[ "$user_input" =~ ^[0-9]+$ ]]; then
    if ((user_input > 20)); then
        echo "The entered number is too large. Please enter a number from 0 to 20."
    else
        result=$(factorial "$user_input")
        echo "The factorial of $user_input is $result"
    fi
else
    echo "Incorrect input. Please enter a non-negative integer."
fi
```

# Задание 9 - ищем скрипт и объясняем его

Для начала, скрипт надо найти... Воспользуемся следующим однострочником, чтобы получить список файлов в системе, которые имеют не менее 10 строк кода, имеют расширение `.sh` и начинаются с `#!/bin/bash`

```bash
find / -type f -name "*.sh" -exec awk 'NR<=20 && /^#!/ && /\/bin\/bash/ {print FILENAME; exit}' {} \; 2>/dev/null
```

И аналогично для скриптов, начинающихся с `#!/bin/sh`

```bash
find / -type f -name "*.sh" -exec awk 'NR<=20 && /^#!/ && /\/bin\/sh/ {print FILENAME; exit}' {} \; 2>/dev/null
```

Честно, этот однострочник выше мне написала нейронная сеть. Искать скрипты, которые имеют не меньше 10 строк и не больше, чем очень много - оказалось сложно.

Я нашёл скрипт `cat /usr/share/apr-1/build/mkdir.sh`. Он оказался идеальным кандидатом:

```bash
#!/bin/sh  
##    
##  mkdir.sh -- make directory hierarchy  
##  
##  Based on `mkinstalldirs' from Noah Friedman <friedman@prep.ai.mit.edu>  
##  as of 1994-03-25, which was placed in the Public Domain.  
##  Cleaned up for Apache's Autoconf-style Interface (APACI)  
##  by Ralf S. Engelschall <rse@apache.org>  
##  
#  
# This script falls under the Apache License.  
# See http://www.apache.org/docs/LICENSE  
  
  
umask 022  
errstatus=0  
for file in ${1+"$@"} ; do    
   set fnord `echo ":$file" |\  
              sed -e 's/^:\//%/' -e 's/^://' -e 's/\// /g' -e 's/^%/\//'`  
   shift  
   pathcomp=  
   for d in ${1+"$@"}; do  
       pathcomp="$pathcomp$d"  
       case "$pathcomp" in  
           -* ) pathcomp=./$pathcomp ;;  
           ?: ) pathcomp="$pathcomp/"    
                continue ;;  
       esac  
       if test ! -d "$pathcomp"; then  
           thiserrstatus=0  
           mkdir "$pathcomp" || thiserrstatus=$?  
           # ignore errors due to races if a parallel mkdir.sh already  
           # created the dir  
           if test $thiserrstatus != 0 && test ! -d "$pathcomp" ; then  
               errstatus=$thiserrstatus  
           fi  
       fi  
       pathcomp="$pathcomp/"  
   done  
done  
exit $errstatus
```

Этот скрипт используется в процессе сборки APR (Apache Portable Runtime) - вспомогательной библиотеки Apache веб-сервера. Полагаю, оно появилось у меня на ПК после установки Apache. 

APR предоставляет набор API, которые предоставляют доступ к функционалу ОС, на котором запущена. При этом, если ОС не поддерживает определённую функцию, APR обеспечивает её эмуляцию. Таким образом, APR может использоваться программистами для обеспечения своему ПО переносимости.

Конкретный скрипт `/usr/share/apr-1/build/mkdir.sh` выполняет создание директорий в соответствии с требованиями проекта. Он используется для обеспечения наличия необходимых директорий в процессе настройки и сборки проекта с использованием инструмента сборки Apache (обычно Autoconf и Automake).

В кратце, скрипт `mkdir.sh` гарантирует, что требуемые директории существуют перед началом процесса сборки.

А если ещё в кратнце, `mkdir.sh` это почти как `mkdir`, только создаёт все промежуточные директории, которых не существует - сам. 

Теперь разберём его подробно:

```bash
#!/bin/sh

umask 022
# Устанавливаем маску доступа по умолчанию для создаваемых файлов и каталогов. В данном случае, она устанавливается в `022`, что означает, что для создаваемых файлов и каталогов разрешения будут `rw-r--r--` (644), а для каталогов `rwxr-xr-x` (755).

errstatus=0
# Устанавливаем начальное значение переменной для отслеживания ошибок.

for file in ${1+"$@"} ; do 
# Начало цикла `for`, который перебирает все аргументы, переданные скрипту.

    set fnord `echo ":$file" |\
               sed -e 's/^:\//%/' -e 's/^://' -e 's/\// /g' -e 's/^%/\//'`
    # Используем echo и sed для преобразования пути к файлу в последовательность аргументов,
    # с разделением каталогов пробелами.

    shift
    # Смещение аргументов командной строки влево, 
    # чтобы избежать повторного использования уже обработанных аргументов.

    pathcomp=
    # Инициализируем переменную для построения пути.

    for d in ${1+"$@"}; do
    # Вложенный цикл `for`, который перебирает компоненты пути.

        pathcomp="$pathcomp$d"
        # Добавляет текущий компонент пути к переменной `pathcomp`.

        case "$pathcomp" in
            -* ) pathcomp=./$pathcomp ;;
            # Если путь начинается с -, добавляем ./ в начало.
            ?: ) pathcomp="$pathcomp/" 
                 continue ;;
            # Если путь начинается с :, добавляем / в конец и продолжаем.
        esac

        if test ! -d "$pathcomp"; then
        # Проверка существования каталога по указанному пути.

            thiserrstatus=0
            # Устанавливаем временное значение для отслеживания ошибок при создании каталога.

            mkdir "$pathcomp" || thiserrstatus=$?
            # Создаем каталог, обновляя временное значение ошибки при неудаче.

            # ignore errors due to races if a parallel mkdir.sh already
            # created the dir
            if test $thiserrstatus != 0 && test ! -d "$pathcomp" ; then
                errstatus=$thiserrstatus
                # Если не удалось создать каталог, обновляем значение ошибки.
            fi
        fi

        pathcomp="$pathcomp/"
        # Добавляем / в конец пути для следующей итерации.
    done
done

exit $errstatus
# Завершаем скрипт с кодом возврата, равным значению ошибки.
```

Объяснение конструкции `${1+"$@"}` можно найти [здесь](https://unix.stackexchange.com/questions/68484/what-does-1-mean-in-a-shell-script-and-how-does-it-differ-from):

![[Pasted image 20240115143350.png | center | 800]]

# Задание 9 - разбираемся в скриптах

## 1. А

```bash
#!/bin/bash

if [ $# -ne1 ];
then
    echo "Usage: $0filename";
    exit -1
fi

filename=$1

egrep -o "\ b [[:alpha:]]+\b $ " filename | \
    awk '{count[$0]++ } END{ printf("%-14s%s\n","Word","Count");
    \for(ind in count) { printf("% -14s%d\n",ind,count[ind]); }
}'
```

Этот скрипт выполняет подсчёт уникальных слов в файле.

```bash
egrep -o "\b[[:alpha:]]+\b$" $filename |
```

В этой строке используется `egrep` для поиска слов файле, удовлетворяющих регулярному выражению. Суть регулярки в том, чтобы собирать отдельные слова, состоящие только из букв. 

`egrep` - это синоним `grep -E`, где аргумент `-E` означает интерпретацию паттерна (строки, которую grep принимает) как регулярное выражение. Есть и другие режимы работы `grep`:

![[Pasted image 20240115144652.png | center | 800]]

Далее вывод grep передаётся через pipe `|` в `stdin` следующей утилиты, коей является `awk`.
Символ `\` означает только лишь перенос кода на следующую строку - иначе говоря, это всё большой однострочный скрипт.

```bash
awk '{count[$0]++ } END{ printf("%-14s%s\n","Word","Count");
    \for(ind in count) { printf("% -14s%d\n",ind,count[ind]); }
}'
```

Здесь `awk` используется для, собственно, подсчёта уникальных слов. 

`{count[$0]++ }`- эта часть кода увеличивает счетчик для каждой строки (слова), прочитанной из входного потока. `$0` в AWK текущую строку (в данном случае, слово).

`END{ printf("%-14s%s\n","Word","Count");` - этот блок кода выполняется после того, как awk обработает весь входной поток. Здесь используется `printf` для вывода заголовка таблицы с двумя колонками: "Word" и "Count".

`\for(ind in count) { printf("% -14s%d\n",ind,count[ind]); }`: - этот блок кода также выполняется в секции `END`, после предыдущего, и в цикле for перебирает все ключи словаря `count` (в качестве ключей мы использовали слова) и через `printf` выводит само слово - и его подсчитанное количество.

## 2. Бэ

```bash
#!/bin/bash

for ip in 192.168.0.{1..254} ;
do
    (
        ping $ip -c2 &> /dev/null ;
        
        if [ $? -eq if 0 ];
        then
            echo $ip is alive
        fi
    ) &
done

wait

echo Done
```

Этот скрипт проверяет все ip-адреса из диапазона на доступность - и в случае доступности выводит `$ip is alive`.

`ping $ip-c2 &> /dev/null ;` - запускает `ping` для проверки доступности узла с IP-адресом `$ip`. Опция `-c2` указывает на отправку 2 пакетов. Результаты `ping` направляются в `/dev/null`, чтобы скрыть вывод от пользователя.

`if [ $?-eq if 0 ];`: - проверяет код возврата предыдущей команды `ping`. Если код возврата равен 0, то есть `ping` завершился успешно (узел доступен), то выполнится следующий блок кода.

`( ... ) &` - самая интересная часть. Все команды между скобками выполняются в подпроцессе, а оператор `&` запускает подпроцесс в фоном режиме - иначе говоря, все ip-адреса в диапазоне проверяются параллельно. 

`wait` - ожидание завершения всех запущенных в фоне процессов.

## 3. Вэ

```bash
#!/bin/bash

USER=$1

devices=`ls /dev/pts/* -l | \
    awk '{ print $3,$9 }' | \
    grep $USER | \
    awk '{ print $2 }'`

for dev in $devices;
do
    cat /dev/stdin > $dev
done
```

Данная скрипт, ПО ИДЕЕ, должен сначала получить список всех виртуальных терминалов, которые принадлежат указанному пользователю, а затем перенаправлять ввод в них.

Как-то так получилось, что на моей системе этот скрипт не работает как положено.

Во-первых, при парсинге `awk '{ print $3,$9 }'` я получал имя владельца и дату создания/последнего доступа к терминалу, в то время как нам нужны имя владельца и имя терминала. Я поменял `$9` на `$10`.

![[Pasted image 20240115153329.png | center | 800]]

Во-вторых, вывод `/dev/stdin` в терминал работал не вполне ожидаемым образом. Поскольку мы сначала проходимся по всем устройствам, а потом перенаправляем читаем `/dev/stdin`, в конечном итоге вывод попадает только в первый терминал из найденных (я его не нашёл, но в системе он был).

Я немного переписал скрипт, чтобы `/dev/stdin` [читался построчно](https://stackoverflow.com/questions/10929453/read-a-file-line-by-line-assigning-the-value-to-a-variable) и каждая полученная строка перенаправлялась в виртуальные терминалы:

```bash
#/bin/bash

USER=$1

devices=`ls /dev/pts/* -l | \
    awk '{ print $3,$10 }' | \
    grep $USER | \
    awk '{ print $2 }'`

while IFS= read -r line; do

    for dev in $devices;
    do
    echo $line > $dev
    done

done < /dev/stdin
```

1. `ls /dev/pts/* -l` - получает список всех виртуальных терминалов, а также дополнительные данные этих файлов (в том числе имя владельца)
2. `awk '{ print $3,$10 }'` - возвращает только 3 и 10 элементы строки (имя владельца и имя терминала)
3. `grep $USER` - выфильтровывет из этих строк те, в которых владелец - указанный пользователь
4. `awk '{ print $2 }'` - поскольку фильтрацию мы уже произвели, выводит уже только имена терминалов
5. `while IFS= read -r line; do ... done < /dev/stdin` - построчно читает `/dev/stdin`
	1. `IFS=` (или `IFS=''`) - запрещает обрезать пробелы в начале и конце строк
	2. `-r` - указывает интерпретировать escape-последовательности как обычные строки

Продемонстрируем работоспособность скрипта (я же его исправлял, надо проверить):
>[!blank | alt]
>![[Pasted image 20240115154441.png | center | 800]]
>
>Вводим буквы
>
>![[Pasted image 20240115154453.png | center | 800]]
>
>А они берут и там оказываются!

Ну и меня слегка раздражало получать свой вывод обратно в тот же терминал, поэтому ещё немного модифицировал скрипт:

```bash
#/bin/bash

USER=$1
CURRENT=$(tty)

devices=`ls /dev/pts/* -l | \
    awk '{ print $3,$10 }' | \
    grep $USER | \
    awk '{ print $2 }'`

while IFS= read -r line; do

    for dev in $devices;
    do
    [ $dev = $CURRENT ] && continue;
    echo $line > $dev
    done

done < /dev/stdin
```

Здесь мы при помощи утилиты `tty` узнаём имя текущего виртуального терминала и запоминаем его:
```bash
CURRENT=$(tty)
```

А здесь с использованием тернарного оператора пропускаем вывод, если терминал равен текущему:
```bash
[ $dev = $CURRENT ] && continue;
```

Демонстрация работы:

>[!blank | alt]
>
>![[Pasted image 20240115155326.png | center | 800]]
>
>Видим, что вывод уже не дублируется в текущий терминал
>
>![[Pasted image 20240115155337.png | center | 800]]
>
>Но всё ещё перенаправляется в остальные!

