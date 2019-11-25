./migrations.sh
if [ $? -eq 0 ]; then
	./remove.sh
elif [ $? -eq 3]; then
	tail -f /dev/null
else
	exit 1
fi
