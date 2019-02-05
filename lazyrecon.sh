#!/bin/bash

discovery(){
  hostalive $1
  subdomaintakeover $1
  screenshot $1
  cleanup $1
  cat ~/BBP/$1/$foldername/responsive-$(date +"%Y-%m-%d").txt | sort -u | while read line; do
    sleep 1
    report $1 $line
    echo -e "\n$line report generated.\n\n"
    sleep 1
  done
}

cleanup(){
  cd ~/BBP/$1/$foldername/screenshots/
  sudo rename 's/_/-/g' -- *
  cd $path
}

hostalive(){
    echo -e "Checking if which hosts are online...\n\n"
    cat ~/BBP/$1/$foldername/$1.txt | sort -u | while read line; do
    if [ $(curl --write-out %{http_code} --silent --output /dev/null -m 5 $line) = 000 ]
    then
      echo "$line was unreachable."
      touch ~/BBP/$1/$foldername/unreachable.html
      echo "<b>$line</b> was unreachable<br>" >> ~/BBP/$1/$foldername/unreachable.html
    else
      echo "$line is up"
      echo $line >> ~/BBP/$1/$foldername/responsive-$(date +"%Y-%m-%d").txt
    fi
  done
}

screenshot(){
    echo -e "\n\nTaking screenshots\n\n"
    cat ~/BBP/$1/$foldername/screenshots/responsive-$(date +"%Y-%m-%d").txt | aquatone
}

subdomaintakeover(){
    echo -e "\n\nRunning subdomain takeover checks, starting with DomainWatch\n\n"
    cd /opt/DomainWatch/
    ./domainwatch.sh scan ~/BBP/$1/$foldername/$1.txt >> ~/BBP/$1/$foldername/subdomain-takeover.txt
    echo -e "\n\nNext up, Aquatone-Takeover!\n\n"
    aquatone-takeover --nameservers 1.1.1.1,8.8.8.8 -t 10 -d $1
    cat ~/aquatone/$1/takeovers.json | jq '.' >> ~/BBP/$1/$foldername/subdomain-takeover.txt
}

recon(){
  echo -e "Doing subdomain enumeration, starting with Sublist3r!\n\n"
  python /opt/Sublist3r/sublist3r.py -d $1 -b -t 10 -v -o ~/BBP/$1/$foldername/$1.txt
  echo -e "\n\nNext up, Aquatone-Discover!"
  aquatone-discover --nameservers 1.1.1.1,8.8.8.8 -t 10 -d $1
  sed "s/,.*//" ~/aquatone/$1/hosts.txt >> ~/BBP/$1/$foldername/$1.txt
  echo -e "\n\nNext up, FDNS script!"
  domain="\.${1//\./\\.}\","
  pv /opt/2018-10-26-1540512295-fdns_any.json.gz | pigz -dc | grep -E ${domain} | jq -r .name >> ~/BBP/$1/$foldername/$1.txt
  echo -e "\n\nAnd now Certspotter!\n\n"
  curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $1 >> ~/BBP/$1/$foldername/$1.txt
  discovery $1
  cat ~/BBP/$1/$foldername/$1.txt | sort -u >> ~/BBP/$1/$foldername/$1.txt
}

report(){
  touch ~/BBP/$1/$foldername/reports/$line.html
  echo "<title> report for $line </title>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<html>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<head>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css?family=Mina\" rel=\"stylesheet\">" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "</head>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<body><meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"> <link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css\"> <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js\"></script> <script src=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js\"></script></body>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<div class=\"jumbotron text-center\"><h1> Recon Report for <a/href=\"http://$line.com\">$line</a></h1>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<p> Generated by <a/href=\"https://github.com/nahamsec/lazyrecon\"> LazyRecon</a> on $(date) </p></div>" >> ~/BBP/$1/$foldername/reports/$line.html

  echo "   <div clsas=\"row\">" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "     <div class=\"col-sm-6\">" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "</pre>   </div>" >> ~/BBP/$1/$foldername/reports/$line.html

  echo "     <div class=\"col-sm-6\">" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Screeshot</h2></div>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<pre>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "Port 80                              Port 443" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "</pre>" >> ~/BBP/$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Dig Info</h2></div>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<pre>" >> ~/BBP/$1/$foldername/reports/$line.html
  dig $line >> ~/BBP/$1/$foldername/reports/$line.html
  echo "</pre>" >> ~/BBP/$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Host Info</h1></div>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<pre>" >> ~/BBP/$1/$foldername/reports/$line.html
  host $line >> ~/BBP/$1/$foldername/reports/$line.html
  echo "</pre>" >> ~/BBP/$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Response Header</h1></div>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<pre>" >> ~/BBP/$1/$foldername/reports/$line.html
  curl -sSL -D - $line  -o /dev/null >> ~/BBP/$1/$foldername/reports/$line.html
  echo "</pre>" >> ~/BBP/$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h1>Nmap Results</h1></div>" >> ~/BBP/$1/$foldername/reports/$line.html
  echo "<pre>" >> ~/BBP/$1/$foldername/reports/$line.html
  nmap -sS -sV -Pn -p- -iL ~/BBP/$1/$foldername/responsive-$(date +"%Y-%m-%d").txt -oN ~/BBP/$1/$foldername/nmap-report.txt
  echo "</pre></div>" >> ./$1/$foldername/reports/$line.html

  echo "</html>" >> ~/BBP/$1/$foldername/reports/$line.html

}

logo(){
  echo "

  _     ____  ____ ___  _ ____  _____ ____ ____  _
 / \   /  _ \/_   \\  \///  __\/  __//   _Y  _ \/ \  /|
 | |   | / \| /   / \  / |  \/||  \  |  / | / \|| |\ ||
 | |_/\| |-||/   /_ / /  |    /|  /_ |  \_| \_/|| | \||
 \____/\_/ \|\____//_/   \_/\_\\____\\____|____/\_/  \|

                                                      "
}

main(){
  clear
  logo

  if [ -d "~/BBP/$1" ]
  then
    echo "This is a known target."
  else
    mkdir ~/BBP/$1
  fi
  mkdir ~/BBP/$1/$foldername
  mkdir ~/BBP/$1/$foldername/reports/
  touch ~/BBP/$1/$foldername/unreachable.html
  touch ~/BBP/$1/$foldername/subdomain-takeover.txt
  touch ~/BBP/$1/$foldername/responsive-$(date +"%Y-%m-%d").txt

    recon $1
}

if [[ -z $@ ]]; then
  echo "Error: No target specified."
  echo "Usage: sudo ./lazyrecon.sh <target>"
  exit 1
fi

path=$(pwd)
foldername=recon-$(date +"%Y-%m-%d")
main $1
