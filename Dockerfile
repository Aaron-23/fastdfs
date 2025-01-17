#参考https://github.com/happyfish100/fastdfs/wiki
#nginx相关模块根据需要可以删掉 依赖pcre pcre-devel zlib zlib-devel openssl-devel
FROM centos:7
#设置时间为中国时区 并且 更新
RUN \cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& yum -y update \
#编译环境
&& yum install wget git gcc gcc-c++ make automake autoconf libtool pcre pcre-devel zlib zlib-devel openssl-devel -y \
#创建跟踪服务器数据目录
&& mkdir -p /fastdfs/tracker \
#创建存储服务器数据目录
&& mkdir -p /fastdfs/storage \
#切换到安装目录#安装libfatscommon
&& cd /usr/local/src \
&& git clone https://github.com/happyfish100/libfastcommon.git --depth 1 \
&& cd /usr/local/src/libfastcommon/ \
&& ./make.sh && ./make.sh install \
#切换到安装目录#安装FastDFS
&& cd /usr/local/src \
&& git clone https://github.com/happyfish100/fastdfs.git --depth 1 \
&& cd /usr/local/src/fastdfs/ \
&& ./make.sh && ./make.sh install \
#配置文件准备
#RUN cp /etc/fdfs/tracker.conf.sample /etc/fdfs/tracker.conf
#RUN cp /etc/fdfs/storage.conf.sample /etc/fdfs/storage.conf
#RUN cp /etc/fdfs/client.conf.sample /etc/fdfs/client.conf #客户端文件，测试用
#RUN cp /usr/local/src/fastdfs/conf/http.conf /etc/fdfs/ #供nginx访问使用
#RUN cp /usr/local/src/fastdfs/conf/mime.types /etc/fdfs/ #供nginx访问使用
#切换到安装目录#安装fastdfs-nginx-module
&& cd /usr/local/src \
&& git clone https://github.com/happyfish100/fastdfs-nginx-module.git --depth 1 \
&& cp /usr/local/src/fastdfs-nginx-module/src/mod_fastdfs.conf /etc/fdfs \
#切换到安装目录#安装安装nginx
&& cd /usr/local/src \
&& wget http://nginx.org/download/nginx-1.13.9.tar.gz \
&& tar -zxvf nginx-1.13.9.tar.gz \
&& cd /usr/local/src/nginx-1.13.9 \
#添加fastdfs-nginx-module模块
&& ./configure --add-module=/usr/local/src/fastdfs-nginx-module/src/ \
&& make && make install \
#tracker配置服务端口默认22122#存储日志和数ca据的根目录
&& sed 's/^base_path.*/base_path=/fastdfs/tracker/g' /etc/fdfs/tracker.conf.sample > /etc/fdfs/tracker.conf \
&& fdfs_trackerd /etc/fdfs/tracker.conf start \
&& sed 's/^base_path./base_path=/fastdfs/storage/g' /etc/fdfs/storage.conf.sample > /etc/fdfs/storage.conf \
&& sed 's/^store_path0./store_path0=/fastdfs/storage/g' /etc/fdfs/storage.conf > /etc/fdfs/storage.conf.tmp \
&& cat /etc/fdfs/storage.conf.tmp > /etc/fdfs/storage.conf \
&& sed 's/^tracker_server.*/tracker_server=127.0.0.1:22122/g' /etc/fdfs/storage.conf > /etc/fdfs/storage.conf.tmp \
&& cat /etc/fdfs/storage.conf.tmp > /etc/fdfs/storage.conf \
&& fdfs_storaged /etc/fdfs/storage.conf start \

WORKDIR /usr/local/src/
EXPOSE 22122 23000

#ENTRYPOINT tail -f /fastdfs/storage/logs/storaged.log
#ENTRYPOINT tail -f /fastdfs/tracker/logs/trackerd.log
ENTRYPOINT tail -f /dev/null
#执行dockerfile
#docker build -t="lkp/fastdfs-storaged:0.9" .
#docker build -t="lkp/fastdfs-trackerd:0.9" .
