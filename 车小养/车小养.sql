CREATE TABLE `sequence` (
  `name` varchar(50) NOT NULL,
  `nextid` int(20) NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='序列生成表';
