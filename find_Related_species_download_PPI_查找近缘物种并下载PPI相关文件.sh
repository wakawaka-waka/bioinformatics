# path1:species.v11.0.txt obs path download url: https://stringdb-static.org/download/species.v11.0.txt  path2:taxidlineage.dmp   obs path,download url:https://ftp.ncbi.nih.gov/pub/taxonomy/   &download taxcat.* &unzip
# $1 taxid
# when show 'whether download PPI related files ?(y/n)' y=download PPIsequences|aliases|links.detailed,n=not download
# log : 20210809 & add download ppi.

path1=/cluster/home/fygong/data/protein/
path2=/cluster/home/fygong/data/protein/

set -eu
function rmo()
{
 if [[ -e 'nohup.out' ]];then
  rm nohup.out
 fi
}

function dppi()
{
echo 'Start downloding......'
nohup wget https://stringdb-static.org/download/protein.sequences.v11.0/$1'.protein.sequences.v11.0.fa.gz' &
nohup wget https://stringdb-static.org/download/protein.aliases.v11.0/$1'.protein.aliases.v11.0.txt.gz' &
nohup wget https://stringdb-static.org/download/protein.links.detailed.v11.0/$1'.protein.links.detailed.v11.0.txt.gz' &
wait
echo 'Start unzip ......'
gunzip $1'.protein.aliases.v11.0.txt.gz'
gunzip $1'.protein.links.detailed.v11.0.txt.gz'
gunzip $1'.protein.sequences.v11.0.fa.gz'
if [[ -e $1'.protein.aliases.v11.0.txt' ]] && [[ -e $1'.protein.links.detailed.v11.0.txt' ]] && [[ -e $1'.protein.sequences.v11.0.fa' ]];then
   echo 'Download & unzip successed !'
else
   echo 'Download maybe failed,please check !'
fi

}


awk -v spe=$1 'BEGIN{FS="\t"}{if($1 == spe){print "物种存在,taixid="$1}}' $path1'/species.v11.0.txt'
re1=`awk -v spe=$1 'BEGIN{FS="\t"}{if($1 == spe){print "物种存在,taixid="$1}}'  $path1'/species.v11.0.txt'`

if [[ $re1 == '' ]];then
   echo '搜索近缘物种.....'
   awk -v spe=$1 'BEGIN{FS="\t"}{if($1 == spe){split($3,a," ");for(i=1;i<length(a)+1;i++){print a[i]}print spe}}'  $path2'/taxidlineage.dmp' > link_id
   all_num=`wc -l link_id | awk '{print $1}'`
   for line in $(seq  1 $all_num)
   do
     let line=all_num-line+1
     echo 'line='$line
     tarid=`awk -v num=$line 'NR==num{print $1}' link_id`
     echo 'tarid='$taridi
     sleep 1s
     if [[ -e 'species-01.txt' ]];then
        grep $tarid   $path2'/taxidlineage.dmp' -w | awk 'BEGIN{FS="\t"}{print $1}' > species-02.txt
        awk 'NR==FNR{a[$1]}NR>FNR{if(!($1 in a)){print $1}}' species-01.txt species-02.txt > species_tari
        mv species_tari species-01.txt
     else
       grep $tarid   $path1'/taxidlineage.dmp' -w | awk 'BEGIN{FS="\t"}{print $1}' > species-01.txt
     fi
     for i in `cat species-01.txt`
     do
       re1=`awk -v spe=$i 'BEGIN{FS="\t"}{if($1 == spe){print "近缘物种存在,taixid="$1}}'  $path1'/species.v11.0.txt'`
       if [[ $re1 != "" ]];then
          echo $re1
          read -p "whether download PPI related files ?(y/n)" args1
          if [[ $args1 == *y* ]];then
             dppi $i
             rmo
          fi
          rm link_id species-0*
          exit 1
        else
          echo $i'_not_exit_try_next_taxid......'
        fi
    done
 done

else
  read -p "whether download PPI related files ?(y/n)" args1
  if [[ $args1 == *y* ]];then
     dppi $1
     rmo
  fi
     exit 1
fi


