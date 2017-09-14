#dta=$(date '+%Y');
#dn=$(date '+%m_%d_%H_%M');

#git add log.txt
#git commit -m "backup log"
#git push -u origin master

#echo "" >> /var/www/bakgit/git.txt
#echo "work0" >> /var/www/bakgit/git.txt
rout=/var/www/bakgit/git.txt

echo "-----------------" >> $rout
git pull &>> $rout
git add 2017/.
git commit -m "backu"
git push -u origin master &>> $rout
echo "-----------------" >> $rout





#echo "" >> /var/www/bakgit/git.txt
#echo "work" >> /var/www/bakgit/git.txt
