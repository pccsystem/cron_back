dta=$(date '+%Y');
dtm=$(date '+%m_%d');
dt=$(date '+%Y_%m_%d__%H_%M_%S.backup');

if [ -d $dta ]; then
	echo "1_1";
	if [ -d $dta/$dtm ]; then
		echo "2_1";
	else
		mkdir $dta/$dtm;
		echo "2_2";
	fi
else
	mkdir $dta;
	echo "1_2";
	if [ -d $dta/$dtm ]; then
		echo "2_1";
	else
		mkdir $dta/$dtm;
		echo "2_2";
	fi
fi

if [ -d $dta/$dtm ]; then
	PGPASSWORD="joec2107" pg_dump -U joec -h 127.0.1.1 -d procarni_prod -F c > /var/www/bak/$dta/$dtm/$dt
	echo ""  >> /var/www/bak/log.txt
	echo "bakcup realizado: $dt"  >> /var/www/bak/log.txt
else
	echo "fichero no creado";
	echo ""  >> /var/www/bak/log.txt
	echo "error backup: $dt"  >> /var/www/bak/log.txt
fi


