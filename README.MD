```
  _     ____  ____ ___  _ ____  _____ ____ ____  _
 / \   /  _ \/_   \\  \///  __\/  __//   _Y  _ \/ \  /|
 | |   | / \| /   / \  / |  \/||  \  |  / | / \|| |\ ||
 | |_/\| |-||/   /_ / /  |    /|  /_ |  \_| \_/|| | \||
 \____/\_/ \|\____//_/   \_/\_\\____\\____|____/\_/  \|

```

# Usage

`$ ./lazyrecon.sh target.com`

# About

This script is intended to automate your reconnaissance process in an organized fashion by performing the following:

- Create a dated folder with recon notes
- Grab subdomains using Sublist3r, Aquatone, Subfinder, amass and Certspotter
- Check if subdomain takeovers are possible with Aquatone and DomainWatch
- Grab a screenshot of responsive hosts using EyeWitness
- Grab the response header
- Perform an Nmap scan
- Generate a HTML report with output from the tools above

This requires [Bug Bounty Hunting Tools](https://github.com/nahamsec/bbht) in order for the tools to work.
