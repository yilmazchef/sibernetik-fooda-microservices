docker run `
    --name mysql-server `
    -e MYSQL_ROOT_PASSWORD=fooda `
    -e MYSQL_DATABASE=foodadb `
    -e MYSQL_USER=fooda `
    -e MYSQL_PASSWORD=fooda `
    -d mysql:latest

