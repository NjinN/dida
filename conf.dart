var CONF = {
  "listen_port": 9090,  //服务器端口      
  "worker_count": 3,   //worker数量（处理请求的线程数）
  "timeout": 600,       //超时时间（每20秒检查一次，超时的请求返回超时错误，并从队列中剔除）
  "max_queue_size": 6000, //每个Worker的请求队列的最大长度，超出后直接拒绝请求
  "access_log": true,     //是否开启请求接收日志
  "db_log": true,         //是否开启数据库日志
  "error_log": true,      //是否开启异常日志

  "db": {                     //数据库配置，目前支持MySql                     
    "host": "localhost",      //数据库IP
    "port": 3306,             //数据库端口   
    "user": "root",           //数据库用户
    "password": "psw", //数据库密码
    "db": "test",              //使用的库
    "poolSize": 3,            //每个worker持有的连接数
  },

  "cross_domain": [     //跨域许可，目前没有做处理，localhost和127.0.0.1请分别添加
    // 'http://localhost:8080',    
    // 'http://127.0.0.1:8080',
  ],
};
 