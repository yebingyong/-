CREATE TABLE `admin_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `username` varchar(20) COLLATE utf8_bin NOT NULL COMMENT '用户名',
  `password_hash` char(60) COLLATE utf8_bin NOT NULL COMMENT '登录密码',
  `name` varchar(20) COLLATE utf8_bin NOT NULL COMMENT '姓名',
  `mobi` varchar(20) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '手机号码',
  `email` varchar(90) COLLATE utf8_bin NOT NULL COMMENT 'Email',
  `status` smallint(6) NOT NULL COMMENT '状态(1000有效，1100冻结，8000不可登录，9000已注销)',
  `timeout` smallint(6) NOT NULL COMMENT '登录超时时间',
  `note` varchar(255) COLLATE utf8_bin DEFAULT NULL COMMENT '备注',
  `create_time` datetime NOT NULL COMMENT '添加时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `i_username` (`username`),
  KEY `i_create_time` (`create_time`)
) ENGINE=InnoDB AUTO_INCREMENT=350 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='后台用户';

CREATE TABLE `garage` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '修理厂ID',
  `number` char(10) COLLATE utf8mb4_bin NOT NULL COMMENT '编号',
  `name` varchar(64) COLLATE utf8mb4_bin NOT NULL COMMENT '名称',
  `type` smallint(6) NOT NULL COMMENT '类型(1000个人，2000企业)',
  `province_id` int(11) NOT NULL COMMENT '省份',
  `city_id` int(11) NOT NULL COMMENT '城市',
  `district_id` int(11) NOT NULL COMMENT '区县',
  `address` varchar(120) COLLATE utf8mb4_bin NOT NULL COMMENT '地址',
  `contact_name` varchar(20) COLLATE utf8mb4_bin NOT NULL COMMENT '联系人姓名',
  `contact_tel` varchar(20) COLLATE utf8mb4_bin NOT NULL COMMENT '联系电话',
  `status` smallint(6) NOT NULL COMMENT '状态(1000有效，9000已删除)',
  `default_distribution_id` int(11) NOT NULL DEFAULT '0' COMMENT '默认加盟商ID',
  `note` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '备注',
  `user_id` int(11) NOT NULL COMMENT '创建人ID',
  `register_channel` tinyint(4) NOT NULL DEFAULT '0' COMMENT '创建渠道（0 为默认方式后台创建，1 邀请注册）',
  `business_hours_start` datetime NOT NULL COMMENT '营业开始时间',
  `business_hours_end` datetime NOT NULL COMMENT '营业结束时间',
  `create_time` datetime NOT NULL COMMENT '添加时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `number` (`number`),
  KEY `name` (`name`),
  KEY `province_id` (`province_id`),
  KEY `city_id` (`city_id`),
  KEY `district_id` (`district_id`)
) ENGINE=InnoDB AUTO_INCREMENT=59105 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='修理厂';


CREATE TABLE `garage_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `garage_id` int(11) NOT NULL COMMENT '修理厂ID',
  `username` varchar(20) COLLATE utf8_bin DEFAULT NULL COMMENT '用户名(手机号)',
  `password_hash` char(60) COLLATE utf8_bin NOT NULL DEFAULT '' COMMENT '登录密码',
  `status` smallint(6) NOT NULL COMMENT '状态(1000有效，2000停用，9000已删除)',
  `create_time` datetime NOT NULL COMMENT '添加时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `garage_id` (`garage_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6048 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='修理厂用户';

CREATE TABLE `store_pic` (
  `id` bigint(20) NOT NULL COMMENT 'ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL COMMENT '门店ID',
  `pic` varchar(100) NOT NULL COMMENT '图片地址',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`),
  KEY `store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='门店图片';

CREATE TABLE `store_tag` (
  `id` bigint(20) NOT NULL COMMENT 'ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL COMMENT '门店ID',
  `name` varchar(10) NOT NULL COMMENT '标签名',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`),
  KEY `store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='门店标签';

CREATE TABLE `reservation_service_category` (
  `id` bigint(20) NOT NULL COMMENT '类别ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL COMMENT '门店ID',
  `name` varchar(10) COLLATE utf8_bin NOT NULL COMMENT '类别名称',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`),
  KEY `store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='预约项目分类';

CREATE TABLE `shopping_mall_product_category` (
  `id` bigint(20) NOT NULL COMMENT '类别ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL COMMENT '门店ID',
  `name` varchar(10) COLLATE utf8_bin NOT NULL COMMENT '类别名称',
  `create_time` datetime NOT NULL COMMENT '创建时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`),
  KEY `store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='商城商品分类';


