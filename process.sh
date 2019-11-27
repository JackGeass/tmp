./migrations.sh
if [ $? -eq 0 ]; then
	./remove.sh
elif [ $? -eq 3]; then
	#TODO send email
	tail -f /dev/null
else
	#TODO but had sync/ restart sync?
	exit 1
fi
