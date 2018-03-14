#!/bin/bash

discovery(){
  hostalive $1
  subdomaintakeover $1
  screenshot $1
  cleanup $1
  cd ~/BBP/
  cat ./$1/$foldername/responsive-$(date +"%Y-%m-%d").txt | sort -u | while read line; do
    sleep 1
    report $1 $line
    echo "$line report generated."
    sleep 1
  done
}

cleanup(){
  cd ~/BBP/$1/$foldername/screenshots/
  sudo rename 's/_/-/g' -- *
  cd $path
}

hostalive(){
  cd ~/BBP/
  cat ./$1/$foldername/$1.txt | sort -u | while read line; do
    if [ $(curl --write-out %{http_code} --silent --output /dev/null -m 5 $line) = 000 ]
    then
      echo "$line was unreachable."
      touch ./$1/$foldername/unreachable.html
      echo "<b>$line</b> was unreachable<br>" >> ./$1/$foldername/unreachable.html
    else
      echo "$line is up"
      echo $line >> ./$1/$foldername/responsive-$(date +"%Y-%m-%d").txt
    fi
  done
}

screenshot(){
    echo "Taking a screenshot of $line"
    python /opt/EyeWitness/EyeWitness.py --headless -d ./$1/$foldername/screenshots/ -i ./$1/$foldername/responsive-$(date +"%Y-%m-%d").txt --timeout 10
}

subdomaintakeover(){
    echo "Running subdomain takeover checks..."
    ./opt/DomainWatch/domainwatch.sh scan ./$1/$foldername/$1.txt > ./$1/$foldername/subdomain-takeover.txt
    aquatone-takeover -d $1
    cat ~/aquatone/$1/takeovers.json | jq | tee -a ./$1/$foldername/subdomain-takeover.txt > /dev/null
}

recon(){
  echo "Doing subdomain enumeration..."
  python /opt/Sublist3r/sublist3r.py -d $1 -t 10 -v -o ./$1/$foldername/$1.txt
  aquatone-discover -d $1
  sed "s/,.*//" ~/aquatone/$1/hosts.txt > ./$1/$foldername/$1.txt
  curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $1 >> ./$1/$foldername/$1.txt
  discovery $1
  cat ./$1/$foldername/$1.txt | sort -u > ./$1/$foldername/$1.txt
}

report(){
  touch ./$1/$foldername/reports/$line.html
  echo "<title> report for $line </title>" >> ./$1/$foldername/reports/$line.html
  echo "<html>" >> ./$1/$foldername/reports/$line.html
  echo "<head>" >> ./$1/$foldername/reports/$line.html
  echo "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css?family=Mina\" rel=\"stylesheet\">" >> ./$1/$foldername/reports/$line.html
  echo "</head>" >> ./$1/$foldername/reports/$line.html
  echo "<body><meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"> <link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css\"> <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js\"></script> <script src=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js\"></script></body>" >> ./$1/$foldername/reports/$line.html
  echo "<div class=\"jumbotron text-center\"><h1> Recon Report for <a/href=\"http://$line.com\">$line</a></h1>" >> ./$1/$foldername/reports/$line.html
  echo "<p> Generated by <a/href=\"https://github.com/nahamsec/lazyrecon\"> LazyRecon</a> on $(date) </p></div>" >> ./$1/$foldername/reports/$line.html


  echo "   <div clsas=\"row\">" >> ./$1/$foldername/reports/$line.html
  echo "     <div class=\"col-sm-6\">" >> ./$1/$foldername/reports/$line.html
  echo "</pre>   </div>" >> ./$1/$foldername/reports/$line.html

  echo "     <div class=\"col-sm-6\">" >> ./$1/$foldername/reports/$line.html
  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Screeshot</h2></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  echo "Port 80                              Port 443" >> ./$1/$foldername/reports/$line.html
  echo "<img/src=\"../screenshots/http-$line-80.png\" style=\"max-width: 500px;\"> <img/src=\"../screenshots/https-$line-443.png\" style=\"max-width: 500px;\"> <br>" >> ./$1/$foldername/reports/$line.html
  echo "</pre>" >> ./$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Dig Info</h2></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  dig $line >> ./$1/$foldername/reports/$line.html
  echo "</pre>" >> ./$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Host Info</h1></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  host $line >> ./$1/$foldername/reports/$line.html
  echo "</pre>" >> ./$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Response Header</h1></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  curl -sSL -D - $line  -o /dev/null >> ./$1/$foldername/reports/$line.html
  echo "</pre>" >> ./$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h1>Nmap Results</h1></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  echo "nmap -sV -T3 -Pn -p3868,3366,8443,8080,9443,9091,3000,8000,5900,8081,6000,10000,8181,3306,5000,4000,8888,5432,15672,9999,161,4044,7077,4040,9000,8089,443,7447,7080,8880,8983,5673,7443" >> ./$1/$foldername/reports/$line.html
  nmap -sV -T3 -Pn -p3868,3366,8443,8080,9443,9091,3000,8000,5900,8081,6000,10000,8181,3306,5000,4000,8888,5432,15672,9999,161,4044,7077,4040,9000,8089,443,7447,7080,8880,8983,5673,7443 $line -oX ./$1/$foldername/nmap-report.xml
  echo "</pre></div>" >> ./$1/$foldername/reports/$line.html


  echo "</html>" >> ./$1/$foldername/reports/$line.html

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
  cd ~/BBP/
  clear
  logo

  if [ -d "./$1" ]
  then
    echo "This is a known target."
  else
    sudo mkdir ./$1
  fi
  mkdir ./$1/$foldername
  mkdir ./$1/$foldername/reports/
  mkdir ./$1/$foldername/screenshots/
  touch ./$1/$foldername/nmap-report.xml
  touch ./$1/$foldername/unreachable.html
  touch ./$1/$foldername/subdomain-takeover.txt
  touch ./$1/$foldername/responsive-$(date +"%Y-%m-%d").txt

    recon $1
}
logo
if [[ -z $@ ]]; then
  echo "Error: No target specified."
  echo "Usage: sudo ./lazyrecon.sh <target>"
  exit 1
fi

path=$(pwd)
foldername=recon-$(date +"%Y-%m-%d")
main $1
