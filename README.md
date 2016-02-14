# securetomb
Backup to the cloud with local encryption

## Disclaimer
I'm not the a security professional nor do I play one on TV. I know enough about crypto to trust my data with this program and had the design critiqued by security professionals. YMMV

## How to use 
```securetomb init file:///backups backupname /interesting/stuff aes 256```
```securetomb syncup file:///backups```
```securetomb download file:///backups /restore/path```

Securetomb is not too bandwith eficient because security consideration but it's basically smart 
regarding chosing files to upload. Only unix path and mode are preserved. 

## Supported remote drivers
Currently only file:, Amazon Cloud Drive to come next.

## Crypto design
Three things are kept in clear in the remote repo in a plain json file:
 - name of the tomb
 - cipher and params (key length)
 - base random seed 
Everything else is kept ciphered, including the directory. 
Current only AES-OFB is supported but the cripto engines are pluggable so you're free to write your one. 
On the AES engine a master key is derived from the user password and the base random seed using PBKDF2. 
For each encripted file we create a new random key which we cipher with the master and place in the file 
header along with the file IV and an HMAC of the IV using the file key for sanity check.
We don't share encripted blobs between files and the blobs names on the remote storate are random. 
We do leak original file sizes through the blob sizes but the link to the original files is ciphered. One 
way to not leak sizes would be to create fixed sized blobs and chain them. 

## Ruby ??
Yeah sorry about that. Needed a ruby pet project. 

## License 
Distributed under the GNU General Public License v3
(c) Carlos Morgado 2016
