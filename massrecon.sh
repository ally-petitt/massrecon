#!/bin/bash
# Note: This is a pretty rough and quick script. Not optimal
# but I hope to optimize it in the future.

export PS4="\$LINENO: "
set -xv

########################################
#                                       
#  Default Values and configuration here
#
########################################
# auquatoneThreads=5
# subdomainThreads=10
# dirsearchThreads=50
# dirsearchWordlist=~/tools/dirsearch/db/dicc.txt
# massdnsWordlist=~/tools/SecLists/Discovery/DNS/clean-jhaddix-dns.txt
# chromiumPath=/snap/bin/chromium
outputdir="./output"
########################################
# Happy Hunting
########################################






red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
# reset=`tput sgr0`

SECONDS=0

usage() { echo -e "Usage: ./massrecon.sh -s scope.txt -o output/ \n" 1>&2; exit 1; }

while getopts ":s:o:" o; do
    case "${o}" in
        s)
            scope=${OPTARG}
            ;;

        o)
            outputdir=${OPTARG}
            ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "${scope}" ]
   then
   usage; exit 1;
fi


recon(){

  
  if [[ "$target" =~ ^\*.*$ ]] # make a more robust way to handle regex in the future.
  then
    target=${target:2} # remove wildcard from front of target
    echo "${red}Performing passive subdomain enum on $target"
    find_subdomains $target
  fi
  echo "$target" >> $outputdir/all_domains.txt

  dig @1.1.1.1 $target >> ./$outputdir/${target}_dig.out

  ## gau, katana, 
 
  # echo "Starting discovery..."
  # discovery $domain
  # cat ./$domain/$foldername/$domain.txt | sort -u > ./$domain/$foldername/$domain.txt

}


find_subdomains() {
 echo "${red}Listing subdomains using sublister..."
  sublist3r -d $target -t 10 -v -o ./$outputdir/${target}_sublister.out > /dev/null
  echo "${red}Checking certspotter..."
  curl -s https://certspotter.com/api/v0/certs\?domain\=$target | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $target >> ./$outputdir/${target}_certspotter.out
  curl -s "https://crt.sh/?q=${target}&output=json"| jq '.[].common_name' | sort -u | cut -d '"' -f 2 >> $outputdir/${target}_cirtsh.out

  echo "google dorking"
  sd-goo.sh $target | sort -u > sd-goo.sh


}




discovery(){
	hostalive $domain
	cleandirsearch $domain
	aqua $domain
	cleanup $domain
	waybackrecon $domain
	dirsearcher
}

waybackrecon () {
echo "Scraping wayback for data..."
cat ./$domain/$foldername/urllist.txt | waybackurls > ./$domain/$foldername/wayback-data/waybackurls.txt
cat ./$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | unfurl --unique keys > ./$domain/$foldername/wayback-data/paramlist.txt
[ -s ./$domain/$foldername/wayback-data/paramlist.txt ] && echo "Wordlist saved to /$domain/$foldername/wayback-data/paramlist.txt"

cat ./$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | grep -P "\w+\.js(\?|$)" | sort -u > ./$domain/$foldername/wayback-data/jsurls.txt
[ -s ./$domain/$foldername/wayback-data/jsurls.txt ] && echo "JS Urls saved to /$domain/$foldername/wayback-data/jsurls.txt"

cat ./$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | grep -P "\w+\.php(\?|$) | sort -u " > ./$domain/$foldername/wayback-data/phpurls.txt
[ -s ./$domain/$foldername/wayback-data/phpurls.txt ] && echo "PHP Urls saved to /$domain/$foldername/wayback-data/phpurls.txt"

cat ./$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | grep -P "\w+\.aspx(\?|$) | sort -u " > ./$domain/$foldername/wayback-data/aspxurls.txt
[ -s ./$domain/$foldername/wayback-data/aspxurls.txt ] && echo "ASP Urls saved to /$domain/$foldername/wayback-data/aspxurls.txt"

cat ./$domain/$foldername/wayback-data/waybackurls.txt  | sort -u | grep -P "\w+\.jsp(\?|$) | sort -u " > ./$domain/$foldername/wayback-data/jspurls.txt
[ -s ./$domain/$foldername/wayback-data/jspurls.txt ] && echo "JSP Urls saved to /$domain/$foldername/wayback-data/jspurls.txt"
}

cleanup(){
  cd ./$domain/$foldername/screenshots/
  rename 's/_/-/g' -- *

  cd $path
}

hostalive(){
echo "Probing for live hosts..."
cat ./$domain/$foldername/alldomains.txt | sort -u | httprobe -c 50 -t 3000 >> ./$domain/$foldername/responsive.txt
cat ./$domain/$foldername/responsive.txt | sed 's/\http\:\/\///g' |  sed 's/\https\:\/\///g' | sort -u | while read line; do
probeurl=$(cat ./$domain/$foldername/responsive.txt | sort -u | grep -m 1 $line)
echo "$probeurl" >> ./$domain/$foldername/urllist.txt
done
echo "$(cat ./$domain/$foldername/urllist.txt | sort -u)" > ./$domain/$foldername/urllist.txt
echo  "${yellow}Total of $(wc -l ./$domain/$foldername/urllist.txt | awk '{print $1}') live subdomains were found${reset}"
}


# excludedomains(){
#   # from @incredincomp with love <3
#   echo "Excluding domains (if you set them with -e)..."
#   IFS=$'\n'
#   # prints the $excluded array to excluded.txt with newlines 
#   printf "%s\n" "${excluded[*]}" > ./$domain/$foldername/excluded.txt
#   # this form of grep takes two files, reads the input from the first file, finds in the second file and removes
#   grep -vFf ./$domain/$foldername/excluded.txt ./$domain/$foldername/alldomains.txt > ./$domain/$foldername/alldomains2.txt
#   mv ./$domain/$foldername/alldomains2.txt ./$domain/$foldername/alldomains.txt
#   #rm ./$domain/$foldername/excluded.txt # uncomment to remove excluded.txt, I left for testing purposes
#   echo "Subdomains that have been excluded from discovery:"
#   printf "%s\n" "${excluded[@]}"
#   unset IFS
# }

dirsearcher(){

echo "Starting dirsearch..."
cat ./$domain/$foldername/urllist.txt | xargs -P$subdomainThreads -I % sh -c "python3 ~/tools/dirsearch/dirsearch.py -e php,asp,aspx,jsp,html,zip,jar -w $dirsearchWordlist -t $dirsearchThreads -u % | grep Target && tput sgr0 && ./lazyrecon.sh -r $domain -r $foldername -r %"
}

aqua(){
echo "Starting aquatone scan..."
cat ./$domain/$foldername/urllist.txt | aquatone -chrome-path $chromiumPath -out ./$domain/$foldername/aqua_out -threads $auquatoneThreads -silent
}

searchcrtsh(){
 ~/tools/massdns/scripts/ct.py $domain 2>/dev/null > ./$domain/$foldername/tmp.txt
 [ -s ./$domain/$foldername/tmp.txt ] && cat ./$domain/$foldername/tmp.txt | ~/tools/massdns/bin/massdns -r ~/tools/massdns/lists/resolvers.txt -t A -q -o S -w  ./$domain/$foldername/crtsh.txt
 cat ./$domain/$foldername/$domain.txt | ~/tools/massdns/bin/massdns -r ~/tools/massdns/lists/resolvers.txt -t A -q -o S -w  ./$domain/$foldername/domaintemp.txt
}

mass(){
 ~/tools/massdns/scripts/subbrute.py $massdnsWordlist $domain | ~/tools/massdns/bin/massdns -r ~/tools/massdns/lists/resolvers.txt -t A -q -o S | grep -v 142.54.173.92 > ./$domain/$foldername/mass.txt
}


nsrecords(){
                echo "Checking http://crt.sh"
                searchcrtsh $domain
                echo "Starting Massdns Subdomain discovery this may take a while"
                mass $domain > /dev/null
                echo "Massdns finished..."
                echo "${green}Started dns records check...${reset}"
                echo "Looking into CNAME Records..."


                cat ./$domain/$foldername/mass.txt >> ./$domain/$foldername/temp.txt
                cat ./$domain/$foldername/domaintemp.txt >> ./$domain/$foldername/temp.txt
                cat ./$domain/$foldername/crtsh.txt >> ./$domain/$foldername/temp.txt


                cat ./$domain/$foldername/temp.txt | awk '{print $3}' | sort -u | while read line; do
                wildcard=$(cat ./$domain/$foldername/temp.txt | grep -m 1 $line)
                echo "$wildcard" >> ./$domain/$foldername/cleantemp.txt
                done



                cat ./$domain/$foldername/cleantemp.txt | grep CNAME >> ./$domain/$foldername/cnames.txt
                cat ./$domain/$foldername/cnames.txt | sort -u | while read line; do
                hostrec=$(echo "$line" | awk '{print $1}')
                if [[ $(host $hostrec | grep NXDOMAIN) != "" ]]
                then
                echo "${red}Check the following domain for NS takeover:  $line ${reset}"
                echo "$line" >> ./$domain/$foldername/pos.txt
                else
                echo -ne "working on it...\r"
                fi
                done
                sleep 1
                cat ./$domain/$foldername/$domain.txt > ./$domain/$foldername/alldomains.txt
                cat ./$domain/$foldername/cleantemp.txt | awk  '{print $1}' | while read line; do
                x="$line"
                echo "${x%?}" >> ./$domain/$foldername/alldomains.txt
                done
                sleep 1

}



cleandirsearch(){
	cat ./$domain/$foldername/urllist.txt | sed 's/\http\:\/\///g' |  sed 's/\https\:\/\///g' | sort -u | while read line; do
  [ -d ~/tools/dirsearch/reports/$line/ ] && ls ~/tools/dirsearch/reports/$line/ | grep -v old | while read i; do
  mv ~/tools/dirsearch/reports/$line/$i ~/tools/dirsearch/reports/$line/$i.old
  done
  done
  }
cleantemp(){

    rm ./$domain/$foldername/temp.txt
  	rm ./$domain/$foldername/tmp.txt
    rm ./$domain/$foldername/domaintemp.txt
    rm ./$domain/$foldername/cleantemp.txt

}
main(){


  mkdir -p ./$outputdir/

  for target in $(cat $scope)
  do 
    recon $target
  done

  # master_report $domain # put results in json.
  duration=$SECONDS
  echo "Scan completed in : $(($duration / 60)) minutes and $(($duration % 60)) seconds."

}


main
