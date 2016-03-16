if [ $# -eq 1 ]
then
  PID=`ps -A -o pid,cmd | grep "bin/start_service.rb $1" | grep -v grep | awk '{print $1}' | tr "\n" " "`
else
  PID=`ps -A -o pid,cmd | grep "bin/start_service.rb" | grep -v grep | awk '{print $1}' | tr "\n" " "`
fi

echo $PID
