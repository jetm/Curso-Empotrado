#!/bin/sh

echo -e "\t'__CURSO EMPOTRADO__'\n"
echo "Generating configure files... may take a while."

autoreconf --install --force && \
  echo -e "If there was no error messages above, then there is not problems.	" && \
  echo -e "Now run:" && \
  echo -e "\t ./configure && make"  && \
  echo -e "\tor"
  echo -e "\t sb2 ./configure && sb2 make # to Cross-Compile\n"  && \
  echo -e "More information run './configure --help' for more information\n"
