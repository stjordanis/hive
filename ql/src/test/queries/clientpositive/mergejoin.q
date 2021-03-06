--! qt:dataset:src1
--! qt:dataset:src

-- MASK_STATS

set hive.strict.checks.bucketing=false;

set hive.mapred.mode=nonstrict;
set hive.explain.user=false;
set hive.join.emit.interval=100000;
set hive.optimize.ppd=true;
set hive.ppd.remove.duplicatefilters=true;
set hive.tez.dynamic.partition.pruning=true;
set hive.optimize.metadataonly=false;
set hive.optimize.index.filter=true;
set hive.vectorized.execution.enabled=true;
set hive.tez.min.bloom.filter.entries=1;
set hive.tez.bigtable.minsize.semijoin.reduction=1;

-- SORT_QUERY_RESULTS

explain vectorization detail
select * from src a join src1 b on a.key = b.key;

select * from src a join src1 b on a.key = b.key;


CREATE TABLE srcbucket_mapjoin_n16(key int, value string) partitioned by (ds string) CLUSTERED BY (key) INTO 2 BUCKETS STORED AS TEXTFILE;
CREATE TABLE tab_part_n10 (key int, value string) PARTITIONED BY(ds STRING) CLUSTERED BY (key) SORTED BY (key) INTO 4 BUCKETS STORED AS ORCFILE;
CREATE TABLE srcbucket_mapjoin_part_n17 (key int, value string) partitioned by (ds string) CLUSTERED BY (key) INTO 4 BUCKETS STORED AS TEXTFILE;

load data local inpath '../../data/files/bmj/000000_0' INTO TABLE srcbucket_mapjoin_n16 partition(ds='2008-04-08');
load data local inpath '../../data/files/bmj1/000001_0' INTO TABLE srcbucket_mapjoin_n16 partition(ds='2008-04-08');

load data local inpath '../../data/files/bmj/000000_0' INTO TABLE srcbucket_mapjoin_part_n17 partition(ds='2008-04-08');
load data local inpath '../../data/files/bmj/000001_0' INTO TABLE srcbucket_mapjoin_part_n17 partition(ds='2008-04-08');
load data local inpath '../../data/files/bmj/000002_0' INTO TABLE srcbucket_mapjoin_part_n17 partition(ds='2008-04-08');
load data local inpath '../../data/files/bmj/000003_0' INTO TABLE srcbucket_mapjoin_part_n17 partition(ds='2008-04-08');



set hive.optimize.bucketingsorting=false;
insert overwrite table tab_part_n10 partition (ds='2008-04-08')
select key,value from srcbucket_mapjoin_part_n17;

CREATE TABLE tab_n9(key int, value string) PARTITIONED BY(ds STRING) CLUSTERED BY (key) SORTED BY (key) INTO 2 BUCKETS STORED AS ORCFILE;
insert overwrite table tab_n9 partition (ds='2008-04-08')
select key,value from srcbucket_mapjoin_n16;

explain vectorization detail
select count(*)
from tab_n9 a join tab_part_n10 b on a.key = b.key;

select * from tab_n9 a join tab_part_n10 b on a.key = b.key;

set hive.join.emit.interval=2;

select * from tab_n9 a join tab_part_n10 b on a.key = b.key;

explain vectorization detail
select count(*)
from tab_n9 a left outer join tab_part_n10 b on a.key = b.key;

select count(*)
from tab_n9 a left outer join tab_part_n10 b on a.key = b.key;

explain vectorization detail
select count (*)
from tab_n9 a right outer join tab_part_n10 b on a.key = b.key;

select count (*)
from tab_n9 a right outer join tab_part_n10 b on a.key = b.key;

explain vectorization detail
select count(*)
from tab_n9 a full outer join tab_part_n10 b on a.key = b.key;

select count(*)
from tab_n9 a full outer join tab_part_n10 b on a.key = b.key;

explain vectorization detail
select count(*) from tab_n9 a join tab_part_n10 b on a.key = b.key join src1 c on a.value = c.value;
select count(*) from tab_n9 a join tab_part_n10 b on a.key = b.key join src1 c on a.value = c.value;

explain vectorization detail
select count(*) from tab_n9 a join tab_part_n10 b on a.value = b.value;
select count(*) from tab_n9 a join tab_part_n10 b on a.value = b.value;

explain vectorization detail
select count(*) from (select s1.key as key, s1.value as value from tab_n9 s1 join tab_n9 s3 on s1.key=s3.key
UNION  ALL
select s2.key as key, s2.value as value from tab_n9 s2
) a join tab_part_n10 b on (a.key = b.key);

explain vectorization detail
select count(*) from tab_n9 a join tab_part_n10 b on a.value = b.value;
select count(*) from tab_n9 a join tab_part_n10 b on a.value = b.value;

explain vectorization detail
select count(*) from tab_n9 a join tab_part_n10 b on a.key = b.key join src1 c on a.value = c.value;
select count(*) from tab_n9 a join tab_part_n10 b on a.key = b.key join src1 c on a.value = c.value;

explain vectorization detail
select count(*) from (select s1.key as key, s1.value as value from tab_n9 s1 join tab_n9 s3 on s1.key=s3.key
UNION  ALL
select s2.key as key, s2.value as value from tab_n9 s2
) a join tab_part_n10 b on (a.key = b.key);

explain  vectorization detail
select count(*) from
(select rt1.id from
(select t1.key as id, t1.value as od from tab_n9 t1 order by id, od) rt1) vt1
join
(select rt2.id from
(select t2.key as id, t2.value as od from tab_part_n10 t2 order by id, od) rt2) vt2
where vt1.id=vt2.id;

select count(*) from
(select rt1.id from
(select t1.key as id, t1.value as od from tab_n9 t1 order by id, od) rt1) vt1
join
(select rt2.id from
(select t2.key as id, t2.value as od from tab_part_n10 t2 order by id, od) rt2) vt2
where vt1.id=vt2.id;

set mapred.reduce.tasks=3;
select * from (select * from tab_n9 where tab_n9.key = 0)a full outer join (select * from tab_part_n10 where tab_part_n10.key = 98)b on a.key = b.key;
select * from (select * from tab_n9 where tab_n9.key = 0)a right outer join (select * from tab_part_n10 where tab_part_n10.key = 98)b on a.key = b.key;

select * from
(select * from tab_n9 where tab_n9.key = 0)a
full outer join
(select * from tab_part_n10 where tab_part_n10.key = 98)b join tab_part_n10 c on a.key = b.key and b.key = c.key;

select * from
(select * from tab_n9 where tab_n9.key = 0)a
full outer join
(select * from tab_part_n10 where tab_part_n10.key = 98)b on a.key = b.key join tab_part_n10 c on b.key = c.key;

select * from
(select * from tab_n9 where tab_n9.key = 0)a
join
(select * from tab_part_n10 where tab_part_n10.key = 98)b full outer join tab_part_n10 c on a.key = b.key and b.key = c.key;

select * from
(select * from tab_n9 where tab_n9.key = 0)a
join
(select * from tab_part_n10 where tab_part_n10.key = 98)b on a.key = b.key full outer join tab_part_n10 c on b.key = c.key;

set hive.cbo.enable = false;

select * from
(select * from tab_n9 where tab_n9.key = 0)a
full outer join
(select * from tab_part_n10 where tab_part_n10.key = 98)b join tab_part_n10 c on a.key = b.key and b.key = c.key;

select * from
(select * from tab_n9 where tab_n9.key = 0)a
join
(select * from tab_part_n10 where tab_part_n10.key = 98)b full outer join tab_part_n10 c on a.key = b.key and b.key = c.key;
