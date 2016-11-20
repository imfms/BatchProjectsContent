#
# Table structure for table 'acct_param_table'
#

CREATE TABLE acct_param_table (
  `param_index` int(11) default NULL,
  `max_down_speed` int(11) default NULL,
  `max_up_speed` int(11) default NULL,
  `max_user_conn` int(11) default NULL,
  `max_conn_per_ip` int(11) default NULL,
  `max_session_time` int(11) default NULL,
  `max_down_file_num` int(11) default NULL,
  `max_up_file_num` int(11) default NULL,
  `max_session_down` int(11) default NULL,
  `max_session_up` int(11) default NULL,
  `max_down_file_size` int(11) default NULL,
  `max_up_file_size` int(11) default NULL,
  `disk_quotas` int(11) default NULL,
  `disk_quota_unit` varchar(4) default NULL,
  `ratios_type` int(11) default NULL,
  `download_ratios` int(11) default NULL,
  `upload_ratios` int(11) default NULL,
  `starting_credit` int(11) default NULL,
  `ftp_cmd_speed` int(11) default NULL,
  `allowed_login_ip` varchar(255) default NULL,
  `denied_login_ip` varchar(255) default NULL,
  `allowed_login_time` varchar(255) default NULL,
  `deny_ftp_commands` varchar(128) default NULL,
  `files_allow_access` varchar(255) default NULL,
  `files_deny_access` varchar(255) default NULL,
  `send_socket_buffer` int(11) default NULL,
  `recv_socket_buffer` int(11) default NULL
);



#
# Table structure for table 'acct_table'
#

CREATE TABLE acct_table (
  `host_id` int(11) default NULL,
  `host_port` int(11) default NULL,
  `username` varchar(65) default NULL,
  `password` varchar(65) default NULL,
  `no_password` int(11) default NULL,
  `home_path` varchar(255) default NULL,
  `home_perm` varchar(10) default NULL,
  `groupname` varchar(65) default NULL,
  `expire_time` varchar(24) default NULL,
  `hide_pub_path` int(11) default NULL,
  `hide_grp_path` int(11) default NULL,
  `enable_quotas` int(11) default NULL,
  `enable_ratios` int(11) default NULL,
  `freeze_user` int(11) default NULL,
  `bypass_svr_max` int(11) default NULL,
  `virtual_path_indexes` varchar(255) default NULL,
  `param_index` int(11) default NULL
);

#
# Table structure for table 'virtual_path_table'
#

CREATE TABLE virtual_path_table (
  `virtual_path_index` int(11) default NULL,
  `virtual_path` varchar(255) default NULL,
  `permission` varchar(10) default NULL,
  `real_path` varchar(255) default NULL
);

#
# Table structure for table 'transfer_log_table'
#

CREATE TABLE transfer_log_table (
  `finish_time` varchar(24) default NULL,
  `direction` int(11) default NULL,
  `file_name` varchar(255) default NULL,
  `file_path` varchar(255) default NULL,
  `transfer_bytes` double default NULL,
  `starting_offset` double default NULL,
  `transfer_time` float default NULL,
  `transfer_status` int(11) default NULL,
  `username` varchar(65) default NULL,
  `client_ip` varchar(65) default NULL,
  `server_ip` varchar(65) default NULL,
  `server_port` int(11) default NULL
);