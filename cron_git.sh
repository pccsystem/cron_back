#dta=$(date '+%Y');
dn=$(date '+%m_%d_%H_%M');

#git add log.txt
#git commit -m "backup log"
#git push -u origin master

#echo "" >> /var/www/bakgit/git.txt
#echo "work0" >> /var/www/bakgit/git.txt
rout=/var/www/bakgit/git.txt

chmod -R 777 /var/www/bakgit/2017/* |& tee -a mod.txt

echo "--- $dn ---" >> $rout
git pull |& tee -a $rout
git add 2017/. |& tee -a $rout
git commit -m "backup" |& tee -a $rout
git push -u origin master |& tee -a $rout


#echo "" >> /var/www/bakgit/git.txt
#echo "work" >> /var/www/bakgit/git.txt
