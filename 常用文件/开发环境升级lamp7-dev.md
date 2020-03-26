# 切换到PHP7

登录虚拟机按以下步骤说明进行操作。

1. 关闭原有的服务

```shell
cd /home/dev/devops/lamp5-dev
docker-compose down
```



2. 克隆lamp7-dev docker-compose项目：

```shell
cd /home/dev/devops/
git clone http://git.mancando.cn/devops/lamp7-dev.git
```



3. 启动新环境

```shell
cd lamp7-dev
docker-compose up -d
```



4. 修改系统启动脚本

编辑/etc/rc.local

```shell
sudo vi /etc/rc.local
```

将其中的：

```shell
/usr/bin/docker-compose -f /home/dev/devops/lamp5-dev/docker-compose.yml up -d
```

修改为：

```shell
/usr/bin/docker-compose -f /home/dev/devops/lamp7-dev/docker-compose.yml up -d
```





# 数据库

数据库数据可以使用原有的数据库，或重新导入数据。

## 使用原有数据库

关闭mysql

```shell
cd /home/dev/devops/lamp7-dev
docker-compose stop mysql
```



删除新库数据，并拷贝旧库的数据：

```shell
sudo rm /var/lib/docker/volumes/lamp7-dev_mysql-data/_data/ -rf
sudo cp /var/lib/docker/volumes/lamp5-dev_mysql-data/_data/ /var/lib/docker/volumes/lamp7-dev_mysql-data/_data/ -r
```



重新启动mysql

```shell
cd /home/dev/devops/lamp7-dev
docker-compose start mysql
```



进入mysql容器

```shell
docker-compose exec mysql /bin/bash
```

执行升级脚本

```shell
mysql_upgrade
```





## 重新导入数据

1. 删除install-dev-db 本地docker镜像

```shell
docker rmi docker-hub.mancando.cn/install-dev-db:latest
```



2. 更新install-dev-db项目

```shell
cd /home/dev/devops/install-dev-db
git pull
```



3. 重新导入数据

```shell
sh recovery.sh -d all
```





# 切换回PHP5

如果需要切换回PHP5版本的环境，只需关闭lamp7-dev的环境，并重新启动lamp5-dev即可，如下：

```shell
cd /home/dev/devops/lamp7-dev
docker-compose down

cd /home/dev/devops/lamp5-dev
docker-compose up -d
```

或者

```shell
docker-compose -f /home/dev/devops/lamp7-dev/docker-compose.yml down
docker-compose -f /home/dev/devops/lamp5-dev/docker-compose.yml up -d
```

