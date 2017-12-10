pscp.exe -unsafe -l svc_user -pw ******* 192.168.10.10:/dumps/iostats/* C:\Users\novikovav2\Documents\svc\
plink -l svc_user -pw ******* 192.168.10.10 "cleardumps -prefix /dumps/iostats"
