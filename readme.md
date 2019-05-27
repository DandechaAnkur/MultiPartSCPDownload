This will use DD over SSH and download a file from remote machine in parallel.

One can exec something like,

```
    ./mpdl.sh  user@xx.yy.zz.ww   /tmp/very-big-file  /tmp/big-file-0  3  --time  --checksum
```

Thus,
* This program will download "/tmp/very-big-file"
* From machine "user@xx.yy.zz.ww",
* And download it using 3 background tasks - each downloading one part of this file,
* And save it on the local machine at path "/tmp/big-file-0",
* And also display how much time it took,
* And if the remote and local file have same md5 checksum.

For the command line parameters please see this [USAGE](usage.txt) file.

NOTE:
----
As cool as it sounds to download in multipart, this script isn't doing multithreading though!

It's just launching DD over SCP into background, and waits for all the separate DD commands to finish copying various parts of the file.

So it depends on the system how much in parallel this background jobs are executed.

**So, this utility should be used typically when file size is considerably large.**

Otherwise, there isn't much scope of time reduction for a normal sized file.

