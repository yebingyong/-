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

ALTER TABLE `user` ADD COLUMN `status`  smallint(6) NOT NULL COMMENT '状态(1000有效，1100冻结，9000已注销)' AFTER `password_hash`;

CREATE TABLE `store_pic` (
  `id` bigint(20) NOT NULL COMMENT 'ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL COMMENT '门店ID',
  `pic` varchar(100) NOT NULL COMMENT '图片地址',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`),
  KEY `store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='门店图片';

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('store_pic',0);

CREATE TABLE `store_tag` (
  `id` bigint(20) NOT NULL COMMENT 'ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL COMMENT '门店ID',
  `name` varchar(10) NOT NULL COMMENT '标签名',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`),
  KEY `store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='门店标签';

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('store_tag',0);

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

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('reservation_service_category',0);

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

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('shopping_mall_product_category',0);

CREATE TABLE `shopping_mall_product` (
  `id` bigint(20) NOT NULL,
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL,
  `name` varchar(30) CHARACTER SET utf8 NOT NULL COMMENT '名称',
  `shopping_mall_product_category_id` bigint(20) NOT NULL,
  `sale_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '销售价(元)',
  `description` varchar(255) COLLATE utf8_bin DEFAULT '' COMMENT '描述',
  `create_time` datetime NOT NULL COMMENT '添加时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`) USING BTREE,
  KEY `store_id` (`store_id`) USING BTREE,
  KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='商场商品';

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('shopping_mall_product',0);

CREATE TABLE `shopping_mall_product` (
  `id` bigint(20) NOT NULL,
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL,
  `name` varchar(30) CHARACTER SET utf8 NOT NULL COMMENT '名称',
  `shopping_mall_product_category_id` bigint(20) NOT NULL,
  `sale_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '销售价(元)',
  `description` varchar(255) COLLATE utf8_bin DEFAULT '' COMMENT '描述',
  `create_time` datetime NOT NULL COMMENT '添加时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`) USING BTREE,
  KEY `store_id` (`store_id`) USING BTREE,
  KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='商城商品';

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('shopping_mall_product',0);

CREATE TABLE `shopping_mall_product_item` (
  `id` bigint(20) NOT NULL,
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL,
  `shopping_mall_product_id` bigint(20) NOT NULL COMMENT '商城商品ID',
  `product_id` bigint(20) NOT NULL COMMENT '商品ID',
  `unit_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '单价',
  `quantity` int(11) DEFAULT NULL COMMENT '数量',
  `price_calculation_method` tinyint(4) NOT NULL DEFAULT '1' COMMENT '价格计算方式（1：视加注量，2：自定义）',
  `create_time` datetime NOT NULL COMMENT '添加时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`) USING BTREE,
  KEY `store_id` (`store_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='商城商品单行';

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('shopping_mall_product_item',0);

CREATE TABLE `shopping_mall_product_item_pic` (
  `id` bigint(20) NOT NULL COMMENT 'ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL,
  `item_id` bigint(20) NOT NULL COMMENT '商城商品单行ID',
  `pic` varchar(100) NOT NULL COMMENT '图片地址',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`),
  KEY `store_id` (`store_id`),
  KEY `item_id` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商城商品单行图片';

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('shopping_mall_product_item_pic',0);

CREATE TABLE `hours_price` (
  `id` bigint(20) NOT NULL COMMENT 'ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL COMMENT '门店ID',
  `hours_price` decimal(8,2) NOT NULL COMMENT '工时单价(元)',
  `create_time` datetime NOT NULL COMMENT '添加时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`) USING BTREE,
  KEY `store_id` (`store_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='工时单价';

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('hours_price',0);

CREATE TABLE `hours_price_log` (
  `id` bigint(20) NOT NULL COMMENT 'ID',
  `tenant_id` int(11) NOT NULL COMMENT '租户ID',
  `store_id` bigint(20) NOT NULL COMMENT '门店ID',
  `last_hours_price` decimal(8,2) NOT NULL COMMENT '上次工时单价(元)',
  `hours_price` decimal(8,2) NOT NULL COMMENT '工时单价(元)',
  `user_id` int(11) NOT NULL COMMENT '操作人ID',
  `create_time` datetime NOT NULL COMMENT '添加时间',
  `update_time` datetime NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`) USING BTREE,
  KEY `store_id` (`store_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='工时单价日志';

INSERT INTO `sequence` (`name`,`nextid`) VALUES ('hours_price_log',0);

#服务表
ALTER TABLE `service_item` DROP COLUMN `cost_type5`,DROP COLUMN `cost_param5`,DROP COLUMN `cost_type4`,
DROP COLUMN `cost_param4`,DROP COLUMN `cost_type3`,DROP COLUMN `cost_param3`,DROP COLUMN `cost_type2`,
DROP COLUMN `cost_param2`,DROP COLUMN `price_type`,DROP COLUMN `working_hours2`,
DROP COLUMN `unit_price2`,DROP COLUMN `hours_price2`,DROP COLUMN `working_hours3`,
DROP COLUMN `unit_price3`,DROP COLUMN `hours_price3`,DROP COLUMN `working_hours4`,
DROP COLUMN `unit_price4`,DROP COLUMN `hours_price4`,DROP COLUMN `working_hours5`,
DROP COLUMN `unit_price5`,DROP COLUMN `hours_price5`,
CHANGE COLUMN `cost_type1` `cost_type`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '成本类型(1固定成本, 2比例成本, 3单位成本)' AFTER `category_id`,
CHANGE COLUMN `cost_param1` `cost_param`  decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '成本参数' AFTER `cost_type`,
CHANGE COLUMN `working_hours1` `working_hours`  decimal(8,2) NOT NULL DEFAULT 0.00 COMMENT '工时' AFTER `cost_param`,
CHANGE COLUMN `hours_price1` `hours_price`  decimal(8,2) NOT NULL COMMENT '工时单价(元)' AFTER `working_hours`,
CHANGE COLUMN `unit_price1` `unit_price`  decimal(11,2) NULL DEFAULT 0.00 COMMENT '单价' AFTER `hours_price`,
ADD COLUMN `hours_param`  decimal(8,2) NOT NULL COMMENT '工时系数' AFTER `working_hours`,
ADD COLUMN `basic_price`  decimal(11,2) NULL DEFAULT 0.00 COMMENT '服务基础价' AFTER `unit_price`,
ADD COLUMN `sale_price`  decimal(11,2) NULL DEFAULT 0.00 COMMENT '销售总价' AFTER `basic_price`;
#商品分类表
ALTER TABLE `category`
MODIFY COLUMN `level`  tinyint(4) NOT NULL COMMENT '品类级别(0：顶级分类，1：二级分类，2：三级分类）' AFTER `parent_id`,
ADD COLUMN `number`  varchar(30) NOT NULL COMMENT '编号' AFTER `name`,
ADD COLUMN `working_hours`  decimal(10,2) NOT NULL DEFAULT 0 COMMENT '工时' AFTER `level`,
ADD COLUMN `hours_param`  decimal(10,2) NOT NULL DEFAULT 0 COMMENT '工时系数' AFTER `working_hours`;
#商品表
ALTER TABLE `product`
DROP COLUMN `price_type`,
DROP COLUMN `sale_price2`,
DROP COLUMN `sale_price3`,
DROP COLUMN `sale_price4`,
DROP COLUMN `sale_price5`,
CHANGE COLUMN `sale_price1` `sale_price`  decimal(10,2) NULL DEFAULT 0.00 COMMENT '销售价(元)' AFTER `markup_type`,
ADD COLUMN `working_hours`  decimal(8,2) NOT NULL COMMENT '工时' AFTER `sale_price`,
ADD COLUMN `hours_price`  decimal(8,2) NOT NULL COMMENT '工时单价' AFTER `working_hours`,
ADD COLUMN `hours_param`  decimal(8,2) NOT NULL COMMENT '工时系数' AFTER `hours_price`,
ADD COLUMN `unit_price`  decimal(10,2) NOT NULL COMMENT '工时单价' AFTER `hours_param`;



