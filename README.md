# MINIO_Centos
install and set up minio in vm (centos 7)
## Scope
- use 1 VM use centos 7
- minio mount 4 disk (minimum disk for erasure code)
- ip that vm use = 192.168.24.21 
## Get start to setup system
### Set up disk
> create 4 pv (each disk have 1GB) 
```
pvcreate /dev/sdb
pvcreate /dev/sdc
pvcreate /dev/sdd
pvcreate /dev/sde
```
> create 4 vg
```
vgcreate vg_data1 /dev/sdb
vgcreate vg_data2 /dev/sd
vgcreate vg_data3 /dev/sdd
vgcreate vg_data4 /dev/sde
```
> create 4 lv
```
lvcreate -L 1G -n data1 vg_data1
lvcreate -L 1G -n data2 vg_data2
lvcreate -L 1G -n data3 vg_data3
lvcreate -L 1G -n data4 vg_data4
```
> create a filesystem (recomment XFS filesystems)

ref: https://docs.min.io/minio/baremetal/installation/deploy-minio-distributed.html#deploy-minio-distributed
```
mkfs.xfs /dev/vg_data1/data1
mkfs.xfs /dev/vg_data2/data2
mkfs.xfs /dev/vg_data3/data3
mkfs.xfs /dev/vg_data4/data4
```
> create dir for mount
```
mkdir /mnt/data1 /mnt/data2 /mnt/data3 /mnt/data4
```
> mount file system (don't forget to edit file /etc/fstab)
```
mount  /dev/vg_data1/data1 /mnt/data1
mount  /dev/vg_data2/data2 /mnt/data2
mount  /dev/vg_data3/data3 /mnt/data3
mount  /dev/vg_data4/data4 /mnt/data4
```
> file /etc/fstab

![image](https://user-images.githubusercontent.com/112536860/187628889-30eae785-d8b2-4766-9aab-39b946f23755.png)

### install and setup MINIO
> Install minIO server
```
wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio-20220826195315.0.0.x86_64.rpm -O minio.rpm
sudo install minio.rpm
```
> Install minIO client
command line tool provides a modern alternative to UNIX commands like ls, cat, cp, mirror, and diff 
```
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/
```
> Run single node server on 4 drives

When run this command. You can access via web gui with
username & password that show up on terminal
```
minio server --address :9001 /mnt/data{1...4}
```

> Example after run "minio server" command

![image](https://user-images.githubusercontent.com/112536860/187629504-8b243959-d7b0-451e-b3de-c140b57938a9.png)


> Access web GUI via url

username & password = minioadmin

![image](https://user-images.githubusercontent.com/112536860/187630492-74d2d79f-6e76-4c9b-9c2c-e7d2b6886eed.png)

> Adds or updates an alias to the local mc 

Use alias for identify minio server
```
# alias set
mc alias set minio_9001 http://192.168.24.21:9001 minioadmin minioadmin
# alias list
mc alias ls
# Test the Connection
mc admin info minio_9001
```
> Set MinIO storage classes

Standard away >= Reduced Redundancy

Standard has maximum value is half of the total drives, minimum is 2

```
# set Standard 
mc admin config set minio_9001 storage_class standard=EC:2

# set Reduced Redundancy (rcc)
mc admin config set minio_9001 storage_class rrs=EC:2

# after set, check config with this command
mc admin config get minio_9001 storage_class

# restart minio server
mc admin service restart minio_9001
```
### Use JavaScript Client API to test MINIO system

This test use other VM enviroment (Debain 10) to store data by use MinIO JavaScript Library

ref: https://docs.min.io/docs/javascript-client-api-reference.html

> Install npm
```
sudo apt install npm 
```

> Install MinIO JavaScript Client SDK via npm
```
npm install --save minio
```

> Download dummy data for test (100 and 500 MiB)
```
wget http://212.183.159.230/100MiB.zip
wget http://ipv4.download.thinkbroadband.com/512MiB.zip
```

> Script for Create MINIO bucket

Run this script by use command "node create-bucket.js"


This js script wil create MINIO bucket name test3 
```
// this file name is create-bucket.js
var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: '192.168.24.21',
    port: 9001,
    useSSL: false,
    accessKey: 'minioadmin',
    secretKey: 'minioadmin'
});

minioClient.makeBucket('test3', 'us-east-1', function(err) {
  if (err) return console.log('Error creating bucket.', err)
  console.log('Bucket created successfully in "us-east-1".')
})
```

> Script for upload to MINIO bucket

This js script wil upload data to "test3" bucket

```
var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: '192.168.24.21',
    port: 9001,
    useSSL: false,
    accessKey: 'minioadmin',
    secretKey: 'minioadmin'
});

var Fs = require('fs')
var file = '/home/supawit/js/100MB.zip'
var fileStream = Fs.createReadStream(file)
var fileStat = Fs.stat(file, function(err, stats) {
  if (err) {
    return console.log(err)
  }
  minioClient.putObject('test3', '100MB.zip', fileStream, stats.size, function(err, objInfo) {
      if(err) {
          return console.log(err) // err should be null
      }
   console.log("Success", objInfo)
  })
})
```
> Script for list object on MINIO bucket

This js script wil list all object in "test3" bucket

```
var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: '192.168.24.21',
    port: 9001,
    useSSL: false,
    accessKey: 'minioadmin',
    secretKey: 'minioadmin'
});

var data = []
var stream = minioClient.listObjects('test3','', true)
stream.on('data', function(obj) { data.push(obj) } )
stream.on("end", function (obj) { console.log(data) })
stream.on('error', function(err) { console.log(err) } )
```

> Script for list object on MINIO bucket

This js script wil list bucket for this user (admin)

```
var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: '192.168.24.21',
    port: 9001,
    useSSL: false,
    accessKey: 'minioadmin',
    secretKey: 'minioadmin'
});

minioClient.listBuckets(function(err, buckets) {
  if (err) return console.log(err)
  console.log('buckets :', buckets)
})
```

## Test erasure code theory

Now MINIO have 4 disks if we want to set erasure code we must set parity to 2 (minimum parity is 2).
In the theory when set data drive = parity drive. Storage Usage will incress to two time. So In this section will be prove this theory

![image](https://user-images.githubusercontent.com/112536860/187640336-99a45055-b928-44b0-b960-2dfecfb65e46.png)

### Set up MINIO by disable storage class (normal usage)

> Check empty storage 

Each disk used 34.4 MiB at start 

![image](https://user-images.githubusercontent.com/112536860/187642072-92a2990a-f443-4566-9159-d30a87255a1a.png)

> Disable storage class
```
# set Standard 
mc admin config set minio_9001 storage_class standard=

# set Reduced Redundancy (rcc)
mc admin config set minio_9001 storage_class rrs=

# restart minio server
mc admin service restart minio_9001
```

> Upload data 3 files 100 + 100 + 512 = 712 MiB


![image](https://user-images.githubusercontent.com/112536860/187642950-59dfe96b-d11b-4c96-9c3d-b63416be1a30.png)
![image](https://user-images.githubusercontent.com/112536860/187662835-836d29b1-7fa6-4571-83ae-f5a29c1ef66d.png)

**Calculate**

Each disk used 212.5 MiB

**data usage for each disk**

712/4 = 178 MiB

**sum with data init 34.4 Mib from each data**

178 + 34.5 =  212.5 MiB

**We can see that data will spilt between 4 disks**

### Set up MINIO by enable storage class Standard EC:2 (2 times disk usage)

> Check empty storage 

Each disk used 34.4 MiB at start 

![image](https://user-images.githubusercontent.com/112536860/187642072-92a2990a-f443-4566-9159-d30a87255a1a.png)

> Enable storage class by set to EC:2
```
# set Standard 
mc admin config set minio_9001 storage_class standard=EC:2

# set Reduced Redundancy (rcc)
mc admin config set minio_9001 storage_class rrs=EC:2

# restart minio server
mc admin service restart minio_9001
```

> Upload data 3 files 100 + 100 + 512 = 712 MiB

![image](https://user-images.githubusercontent.com/112536860/187645443-8fc49773-51e8-4a48-bd29-bbf2aa219e7b.png)
![image](https://user-images.githubusercontent.com/112536860/187663062-29938cb2-5a75-43e7-bcb7-456adc3492dd.png)

**Calculate**

Each disk used 390.5 MiB

**data usage for each disk**

(much multiple by 2 because EC:2)

(712/4)*2 = 356 MiB

**sum with data init 34.4 Mib from each data**

356 + 34.5 =  390.5 MiB

**We can see that data will spilt between 4 disks with 2 times usage**

### Set up MINIO by enable storage class Reduced Redundancy EC:1

> Check empty storage 

Each disk used 34.4 MiB at start 

![image](https://user-images.githubusercontent.com/112536860/187672872-f7902684-4e31-4f23-b43f-6e5363c562c0.png)

> Enable storage class Reduced Redundancy by set to EC:1
```
# set Standard 
mc admin config set minio_9001 storage_class standard=EC:2

# set Reduced Redundancy (rcc)
mc admin config set minio_9001 storage_class rrs=EC:1

# restart minio server
mc admin service restart minio_9001
```

> js script that upload data by use rcc (EC:1)

In metadata must specific 'X-Amz-Storage-Class': 'REDUCED_REDUNDANCY' for use Reduced Redundancy in this object

ref: https://blog.min.io/configurable-data-and-parity-drives-on-minio-server/
```
var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: '192.168.24.21',
    port: 9001,
    useSSL: false,
    accessKey: 'minioadmin',
    secretKey: 'minioadmin'
});


var Fs = require('fs')
var file = '/home/supawit/js/100MB.zip'
var fileStream = Fs.createReadStream(file)
var fileStat = Fs.stat(file, function(err, stats) {
  if (err) {
    return console.log(err)
  }

  var metaData = {
      'ContentType': 'application/octet-stream',
      'X-Amz-Storage-Class': 'REDUCED_REDUNDANCY'
  }
  minioClient.putObject('test3', '100MB.zip', fileStream, stats.size, metaData, function(err, objInfo) {
      if(err) {
          return console.log(err) // err should be null
      }
   console.log("Success", objInfo)
  })

})
```


> Upload data 3 files 100 + 100 + 512 = 712 MiB

![image](https://user-images.githubusercontent.com/112536860/187828546-3a7406c0-5ab0-40d0-9083-7ccce27f7a74.png)
![image](https://user-images.githubusercontent.com/112536860/187829260-ff6df567-615e-4eda-8e35-6f4af32c6f86.png)

**Calculate**

Each disk used 271.9 MiB

**data usage for each disk**

(712/4)*(4/3) = 237.4 MiB

**sum with data init 34.4 Mib from each data**

237.4 + 34.5 =  271.9 MiB

**We can see that data will spilt between 4 disks with 2 times usage**

## Umount disk for test disks durability

> Set up standard EC:2

In theory, disks can't loss more than 2 drives.

![image](https://user-images.githubusercontent.com/112536860/187852608-09545fcb-38e8-47c4-ba71-26364b5adc50.png)

> create 3 file

```
echo hello_1 > hello.txt
echo hi > hi.txt
echo hello_woeld > world.txt
```

> Let start to umount 1 disk => /mnt/data1

```
umount  /dev/vg_data1/data1
```
![image](https://user-images.githubusercontent.com/112536860/187865278-50396d05-787d-4039-9ee1-18dd373ac1ae.png)

now disk "mnt/data1" is missing

> Test download object gorm bucket

This script will download obj name 'hello.txt', 'hi.txt', 'world.txt' from bucket name 'test3'

```
var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: '192.168.24.21',
    port: 9001,
    useSSL: false,
    accessKey: 'minioadmin',
    secretKey: 'minioadmin'
});


var size = 0
minioClient.fGetObject('test3', 'hello.txt', '/home/supawit/js/test_dir/hello.txt', function(err) {
  if (err) {
    return console.log(err)
  }
  console.log('success')
})

var size = 0
minioClient.fGetObject('test3', 'hi.txt', '/home/supawit/js/test_dir/hi.txt', function(err) {
  if (err) {
    return console.log(err)
  }
  console.log('success')
})

var size = 0
minioClient.fGetObject('test3', 'world.txt', '/home/supawit/js/test_dir/world.txt', function(err) {
  if (err) {
    return console.log(err)
  }
  console.log('success')
})

```

After run this script, client still communicate with server.

![image](https://user-images.githubusercontent.com/112536860/187866595-f3e605f7-9307-49ab-a6b7-8a0c676e0ac8.png)

> umount 2 disks => /mnt/data1 and /mnt/data2

```
umount  /dev/vg_data2/data2
```


