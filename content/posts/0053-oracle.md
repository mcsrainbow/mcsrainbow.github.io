---
title: "Linux下Oracle数据库的启动、关闭和数据字典的利用"
date: "2008-08-27"
tags: ["Oracle"]
categories: ["DevOps"]
---

注：该文章系网上多篇文档和资料的查询，并结合实际操作而完成，未能一一列举出处，仅在此表示感谢。

<!--more-->


注意`$`代表shell命令提示符，这里的Oracle是9.0以上版本。

**启动步骤**

```bash
$ su – oracle
$ sqlplus / nolog
sql> conn / as sysdba
sql> startup #一般不需要加参数，只要设置好环境变量
sql> quit #退出sql模式
$ lsnrctl start #启动监听器
```

**`startup`等于以下三个命令**

```bash
startup nomount
alter database mount
alter database open
```

**`startup`有七个参数，七个参数的含义如下**

* `nomount`非安装启动， 读取init.ora文件，启动instance，即启动SGA和后台进程，这种启动只需要init.ora文件。

  这种方式启动下可执行：重建控制文件、重建数据库。

* `mount dbname`安装启动，执行`nomount`，然后打开控制文件，确认数据文件和联机日志文件的位置， 但此时不对数据文件和日志文件进行校验检查。

  这种方式启动下可执行：数据库日志归档、数据库介质恢复、使数据文件联机或脱机，重新定位数据文件、重做日志文件。

* `open dbname`先执行`nomount`，然后执行`mount`，再打开包括Redo log文件在内的所有数据库文件。

  这种方式下可访问数据库中的数据。

* `restrict`约束方式启动

  这种方式能够启动数据库，但只允许具有一定特权的用户访问，非特权用户访问时，会出现以下提示：

```
ERROR：
ORA-01035: ORACLE 只允许具有 RESTRICTED SESSION 权限的用户使用
```

* `force`强制启动方式，先关闭数据库，再执行正常启动数据库命令。

  当不能关闭数据库时，可以用startup force来完成数据库的关闭 。

* `pfile=参数文件名`带初始化参数文件的启动方式，先读取参数文件，再按参数文件中的设置启动数据库。

  例：

```
startup pfile=E:Oracleadminoradbpfileinit.ora
```

**关闭步骤**

```bash
$ lsnrctl stop #关闭监听器，在这之前，应该先关闭应用程序
$ sqlplus /nolog
sql>shutdown
```

**`shutdown`有四个参数，四个参数的含义如下**

* `normal`需要在所有连接用户断开后才执行关闭数据库任务，所以有的时候看起来好象命令没有运行一样！在执行这个命令后不允许新的连接

* `immediate`在用户执行完正在执行的语句后就断开用户连接，并不允许新用户连接。

* `transactional` 在拥护执行完当前事物后断开连接，并不允许新的用户连接数据库。

* `abort` 执行强行断开连接并直接关闭数据库。

前三种方式不回丢失用户数据，第四种在不的已的情况下，不建议采用！

**经常遇到的问题**

* 权限问题，解决方法，切换到oracle用户；
* 没有关闭监听器 ，解决方法：关闭监听器
* 有Oracle实例没有关闭，解决办法：关闭oracle实例
* 环境变量设置不全，解决办法：修改环境变量。

**用户如何有效地利用数据字典**

ORACLE的数据字典是数据库的重要组成部分之一，它随着数据库的产生而产生, 随着数据库的变化而变化,

体现为sys用户下的一些表和视图。数据字典名称是大写的英文字符。

数据字典里存有用户信息、用户的权限信息、所有数据对象信息、表的约束条件、统计分析数据库的视图等。

我们不能手工修改数据字典里的信息。

很多时候，一般的ORACLE用户不知道如何有效地利用它。

dictionary 全部数据字典表的名称和解释，它有一个同义词dict；

dict_column 全部数据字典表里字段名称和解释；

如果我们想查询跟索引有关的数据字典时，可以用下面这条SQL语句:

```sql
SQL>select * from dictionary where instr(comments,'index')>0;
```

如果我们想知道user_indexes表各字段名称的详细含义，可以用下面这条SQL语句:

```sql
SQL>select column_name,comments from dict_columns where table_name='USER_INDEXES';
```

依此类推，就可以轻松知道数据字典的详细名称和解释，不用查看ORACLE的其它文档资料了。

**下面按类别列出一些ORACLE用户常用数据字典的查询使用方法**

1、用户

查看当前用户的缺省表空间

```sql
SQL>select username,default_tablespace from user_users;
```

查看当前用户的角色

```sql
SQL>select * from user_role_privs;
```

查看当前用户的系统权限和表级权限

```sql
SQL>select * from user_sys_privs;
SQL>select * from user_tab_privs;
```

2、表

查看用户下所有的表

```sql
SQL>select * from user_tables;
```

查看名称包含log字符的表

```sql
SQL>select object_name,object_id from user_objects where instr(object_name,'LOG')>0;
```

查看某表的创建时间

```sql
SQL>select object_name,created from user_objects where object_name=upper('&table_name');
```

查看某表的大小

```sql
SQL>select sum(bytes)/(1024*1024) as "size(M)" from user_segments where segment_name=upper('&table_name');
```

查看放在ORACLE的内存区里的表

```sql
SQL>select table_name,cache from user_tables where instr(cache,'Y')>0;
```

3、索引

查看索引个数和类别

```sql
SQL>select index_name,index_type,table_name from user_indexes order by table_name;
```

查看索引被索引的字段

```sql
SQL>select * from user_ind_columns where index_name=upper('&index_name');
```

查看索引的大小

```sql
SQL>select sum(bytes)/(1024*1024) as "size(M)" from user_segments where segment_name=upper(''&index_name');
```

4、序列号

查看序列号，last_number是当前值

```sql
SQL>select * from user_sequences;
```

5、视图

查看视图的名称

```sql
SQL>select view_name from user_views;
```

查看创建视图的select语句

```sql
SQL>set view_name,text_length from user_views;
SQL>set long 2000; 说明：可以根据视图的text_length值设定set long 的大小
SQL>select text from user_views where view_name=upper('&view_name');
```

6、同义词

查看同义词的名称

```sql
SQL>select * from user_synonyms;
```

7、约束条件

查看某表的约束条件

```sql
SQL>select constraint_name, constraint_type,search_condition, r_constraint_name from user_constraints where table_name = upper('&table_name');

SQL>select c.constraint_name,c.constraint_type,cc.column_name
　　 from user_constraints c,user_cons_columns cc
　　 where c.owner = upper(‘&table_owner’) and c.table_name = upper(‘&table_name’)
　　 and c.owner = cc.owner and c.constraint_name = cc.constraint_name
　　 order by cc.position;
```

8、存储函数和过程

查看函数和过程的状态

```sql
SQL>select object_name,status from user_objects where object_type='FUNCTION';
SQL>select object_name,status from user_objects where object_type='PROCEDURE';
```

查看函数和过程的源代码

```sql
SQL>select text from all_source where owner=user and name=upper('&plsql_name');
```

**查看数据库的SQL**

1、查看表空间的名称及大小

```sql
SQL>select t.tablespace_name, round(sum(bytes/(1024*1024)),0) ts_size
　　 from dba_tablespaces t, dba_data_files d
　　 where t.tablespace_name = d.tablespace_name
　　 group by t.tablespace_name;*
```

2、查看表空间物理文件的名称及大小

```sql
SQL>select tablespace_name, file_id, file_name,
　　 round(bytes/(1024*1024),0) total_space
　　 from dba_data_files
　　 order by tablespace_name;
```

3、查看回滚段名称及大小

```sql
SQL>select segment_name, tablespace_name, r.status,
　　 (initial_extent/1024) InitialExtent,(next_extent/1024) NextExtent,
　　 max_extents, v.curext CurExtent
　　 From dba_rollback_segs r, v$ro
```