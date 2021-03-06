# Terminal
My Terminal Configs

## Install Oh my Posh on Linux

https://ohmyposh.dev/

```bash
sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh
```

### Download the themes
```bash
mkdir ~/.poshthemes
wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O ~/.poshthemes/themes.zip
unzip ~/.poshthemes/themes.zip -d ~/.poshthemes
chmod u+rw ~/.poshthemes/*.json
rm ~/.poshthemes/themes.zip
```

### Change prompt and point at Github hosted config file
```bash
eval "$(oh-my-posh --init --shell bash --config https://github.com/russshearer/terminal/raw/main/oh-my-posh/themes/myterm.omp.json)"
```

## Install .bash_aliases
```bash
wget https://github.com/russshearer/terminal/raw/main/.bash_aliases -O ~/.bash_aliases

# Reload
source .bashrc
```

# Powershell

## Install PowerShell Profile
Invoke-WebRequest -Uri "https://github.com/russshearer/terminal/raw/main/Microsoft.PowerShell_profile.ps1" -OutFile $profile
