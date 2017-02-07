#! /bin/sh
 
if [ "$(lspci | grep -c "7952")" -ne "1" ]; then
        echo "FAIL."
        exit 1
fi
  
echo "PASS"      

