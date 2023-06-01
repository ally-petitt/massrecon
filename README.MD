# Usage

`./massrecon.sh -s scope.txt`

# About

MassRecon is a script written in Bash, it is intended to automate some tedious tasks of reconnaissance and information gathering.
This tool allows you to gather some information that should help you identify what to do next and where to look. Originally forked from nahamsec/lazyrecon.
The main difference is that this adaptation of the script is quieter, more respecting of scope, uses different tools, cleaner output, and performs more thorough enumeration.


# Main Features 
- Create a dated folder with recon notes
- Grab subdomains using:

      * Sublist3r, certspotter and cert.sh
      * Dns bruteforcing using massdns
      
- Find any CNAME records pointing to unused cloud services like aws
- Probe for live hosts over ports 80/443
- Grab a screenshots of responsive hosts 
- Scrape wayback for data:

      * Extract javascript files
      * Build custom parameter wordlist, ready to be loaded later into Burp intruder or any other tool
      * Extract any urls with .jsp, .php or .aspx and store them for further inspection
      
- Perform nmap on specific ports 
- Get dns information about every subdomain
- Perform dirsearch for all subdomains 
- Generate a HTML report with output from the tools above
- Improved reporting and less output while doing the work
- Dark mode for html reports


# New features
- Directory search module is now MULTITHREADED (up to 10 subdomains scanned at a time)
- Enhanced html reports with the ability to search for strings, endpoints, reponse sizes or status codes
- Subdomain exclusion by using option `-e` like this: `-e excluded.domain.com,other.domain.com`

# DEMO
![cli output](https://github.com/plenumlab/lazyrecon/raw/dev/upgrade/recon.gif)
=================================================================================
![report demo](https://github.com/plenumlab/lazyrecon/raw/dev/upgrade/report.gif)


# Installation & Requirements
- Have Bash installed
- Install dependencies by running `./install_dependencies.sh`

### System Requirements
- Recommended to run on vps with 1VCPU and 2GB ram.

## TODO:
* strip whitespace from targets
* hande regex in scope.txt more robustly


# Authors and Thanks
This script makes use of tools developped by the following people
- [Tom Hudson - Tomonomnom](https://github.com/tomnomnom)
- [Ahmed Aboul-Ela - Aboul3la](https://github.com/aboul3la)
- [B. Blechschmidt - Blechschmidt](https://github.com/blechschmidt)
- [Thomas D. - Maaaaz](https://github.com/maaaaz)
- [Daniel Miessler - Danielmiessler](https://github.com/danielmiessler)

