./migrations.sh
res=$?
if [ $res -eq 0 ]; then
	./remove.sh
elif [ $res -eq 3 ]; then
	#TODO send email
	tail -f /dev/null
else
	#TODO but had sync/ restart sync?
	echo "Get Fail"
	exit 1
fi
