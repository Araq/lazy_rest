#!/usr/bin/env bash

# Test git command.
echo "Checking installation of git command."
git --version|grep "git version"
if [ $? != 0 ]; then
	apt-get update
	apt-get install -y git
else
	echo "Seems to be installed, not updating."
fi

# Test zip command.
echo "Checking installation of zip command."
zip | grep Copyright
if [ $? != 0 ]; then
	apt-get update
	apt-get install -y zip
else
	echo "Seems to be installed, not updating."
fi

# Regenerate bash profile with good paths.
su vagrant << EOF
echo "export PATH=\"\$PATH\":~/.nimble/bin:~/.babel/bin:~/project/Nimrod/bin" > ~/.bash_profile

EOF

su -l vagrant << EOF

cd && mkdir -p project && cd project

if [ ! -d Nimrod ]; then
	echo "Installing Nimrod 0.9.6 from git…"
	rm -Rf tmp
	git clone -b master git://github.com/Araq/Nimrod.git tmp
	cd tmp && git checkout v0.9.6 &&
	git clone -b v0.9.6 --depth 1 git://github.com/gradha/csources.git &&
	cd csources && sh build.sh && cd .. &&
	bin/nimrod c koch && ./koch boot -d:release &&
	cd .. && mv tmp Nimrod
else
	echo "Nimrod checkout already installed and compiled"
fi

EOF

su -l vagrant << EOF

cd ~/project

if [ ! -d nimble ]; then
	echo "Installing Nimble from git…"
	rm -Rf tmp &&
	git clone https://github.com/nim-lang/nimble.git tmp &&
	cd tmp && git checkout master &&
	nimrod c -r src/nimble install -y &&
	cd .. && mv tmp nimble
else
	echo "Nimble already installed and compiled"
fi

EOF

su -l vagrant << EOF

nimrod -v
nimble -v

EOF

su -l vagrant << EOF

echo '#!/bin/sh

for package in argument_parser nake; do
	echo "Testing \${package}"
	PKG_PATH=\`nimble path \${package}\`
	if [ ! -d "\$PKG_PATH" ]; then
		echo "Installing nimble package \${package}…"
		nimble install -y \${package}
	else
		echo "Nimble package \${package} already installed"
	fi
done
' > install_nimble_packages.sh
sh install_nimble_packages.sh

EOF