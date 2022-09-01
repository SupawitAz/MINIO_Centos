#! /bin/bash

end_point="192.168.24.21"
port="9001"
ssl="false"
access_key="minioadmin"
secret_key="minioadmin"
file_upload_path="/home/supawit/js/100MB.zip"
file_name_in_minio="100MB_3.zip"
js_path_name="/home/supawit/js/upload_file_test_1.js"
bucket_name="test3"

cat<<EOF>$js_path_name
var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: '${end_point}',
    port: $port,
    useSSL: $ssl,
    accessKey: '$access_key',
    secretKey: '$secret_key'
});


var Fs = require('fs')
var file = '$file_upload_path'
var fileStream = Fs.createReadStream(file)
var fileStat = Fs.stat(file, function(err, stats) {
  if (err) {
    return console.log(err)
  }

  var metaData = {
      'ContentType': 'application/octet-stream',
      'X-Amz-Storage-Class': 'REDUCED_REDUNDANCY'
  }
  minioClient.putObject('$bucket_name', '$file_name_in_minio', fileStream, stats.size, metaData, function(err, objInfo) {
      if(err) {
          return console.log(err) // err should be null
      }
   console.log("Success", objInfo)
  })

})

EOF
