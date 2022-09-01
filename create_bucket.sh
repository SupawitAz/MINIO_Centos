#! /bin/bash

end_point="192.168.24.21"
port="9001"
ssl="false"
access_key="minioadmin"
secret_key="minioadmin"
bucket_name="test3"
js_path_name="/home/supawit/js/bucket_create.js"

cat<<EOF>$js_path_name
var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: '${end_point}',
    port: $port,
    useSSL: $ssl,
    accessKey: '$access_key',
    secretKey: '$secret_key'
});

minioClient.makeBucket('$bucket_name', 'us-east-1', function(err) {
  if (err) return console.log('Error creating bucket.', err)
  console.log('Bucket created successfully.')
})

EOF
