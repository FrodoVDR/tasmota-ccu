# tasmota-ccu

usage:
         sonoff.sh -f [status|switch|switch-t|switch-th] -c CUX2801xxx:x -i ipaddr [-n relayr_nr] [-a apikey] [-u user] [-p password] [-o value] [-d] [-h]

         examples espurna firmware:
         sonoff.sh -h # this usage info
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456      # status switch
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 0 # switch off
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 1 # switch on
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 2 # switch toggle on/off
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 0 -n 3 # switch 4 relay off
         sonoff.sh -f switch-t  -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 0 # switch off with temperature
         sonoff.sh -f switch-t  -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 1 # switch on  with temperature
         sonoff.sh -f switch-th -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456      # status switch, temperature and humidity
         sonoff.sh -f switch-th -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 0 # switch off with status temperature and humidity
         sonoff.sh -f switch-th -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456 -o 1 # switch on  with status temperature and humidity
         sonoff.sh -f status    -c CUX2801xxx:x -i 192.168.x.x -a 1234567890123456      # espurna available restapi

         examples tasmota firmware:
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password      # status switch
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password -n 2 # status switch relay nr 2
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password -o 1 # switch on
         sonoff.sh -f switch    -c CUX2801xxx:x -i 192.168.x.x -u user -p password -o 2 # switch toggle on/off
         sonoff.sh -f switch-th -c CUX2801xxx:x -i 192.168.x.x -u user -p password      # status switch, temperature and humidity
         sonoff.sh -f switch-p  -c CUX2801xxx:x -i 192.168.x.x -u user -p password      # status switch, power, volt, ampere, ...
         sonoff.sh -f status    -c CUX2801xxx:x -i 192.168.x.x -u user -p password      # tasmota status

