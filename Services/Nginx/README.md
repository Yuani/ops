## NGINX 配置

官方： [nginx-rewrite-rules](https://www.nginx.com/blog/creating-nginx-rewrite-rules/)

### 1、隐藏版本号

    http {
      ...
      server_tokens  off;
      ....
    }


### 2、拒绝IP直接访问

    server {
            listen 80 default_server;
            server_name _;
            access_log  off;
            return 403;
       }

### 3、Nginx 反向代理 传递源IP

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_intercept_errors on;
    }
    
    
##### proxy_params.conf    
    proxy_next_upstream error timeout invalid_header http_500 http_503 http_404 http_502;
    proxy_store off;
    proxy_redirect off;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;



### 4、关闭favicon.ico不存在时记录日志
把以下配置放到 server {} 块.

    location /favicon.ico {
        log_not_found off;
        access_log off;
    }
### 5、不允许访问隐藏文件例如 .htaccess, .htpasswd, .DS_Store (Mac).

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

### 6、PHP 配置
    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000  
    #  
    location ~ \.php$ {  
        root html;  
        fastcgi_pass 127.0.0.1:9000;  
        fastcgi_index index.php;  
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;  
        include fastcgi_params;  
    }


### 7、proxy 多端口代理
    location ^~ /8081/ {
              rewrite /8081/(.*)  /$1   break;
              proxy_pass http://100.88.64.171:8081;
              proxy_redirect / /8081/;
            }

