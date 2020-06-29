#! /bin/bash


HDFS_SEED_DIR=/user/ailab/nutch/urls
HDFS_CRAWL_DIR=/user/ailab/nutch/crawl
BIN_DIR=$NUTCH_RUNTIME_HOME/bin
ROUND_N=2
FETCHERS_N=3


if [ -z "$NUTCH_HOME" ]; then
    echo ">> NUTCH_HOME does not exist... exit"
    exit 100
fi
echo ">> NUTCH_HOME is $NUTCH_HOME"

if [ -z "$NUTCH_RUNTIME_HOME" ]; then
    echo ">> NUTCH_RUNTIME_HOME does not exist... exit"
    exit 100
fi
echo ">> NUTCH_RUNTIME_HOME is $NUTCH_RUNTIME_HOME"


hadoop fs -rm $HDFS_SEED_DIR/seed.txt
hadoop fs -put $NUTCH_HOME/urls/seed.txt $HDFS_SEED_DIR
hadoop fs -rm -r -f $HDFS_CRAWL_DIR
hadoop fs -mkdir $HDFS_CRAWL_DIR


echo ">> nutch inject"
$BIN_DIR/nutch inject $HDFS_CRAWL_DIR/crawldb $HDFS_SEED_DIR


for i in $(seq 1 $ROUND_N); do
    echo ">> nutch generate"
    $BIN_DIR/nutch generate $HDFS_CRAWL_DIR/crawldb $HDFS_CRAWL_DIR/segments -numFetchers $FETCHERS_N
    LAST_SEG=`hadoop fs -ls -C $HDFS_CRAWL_DIR/segments/ | tail -1`
    echo ">> nutch fecth"
    $BIN_DIR/nutch fetch $LAST_SEG
    echo ">> nutch parse"
    $BIN_DIR/nutch parse $LAST_SEG
    echo ">> nutch updatedb"
    $BIN_DIR/nutch updatedb $HDFS_CRAWL_DIR/crawldb $LAST_SEG
done


LAST_SEG=`hadoop fs -ls -C $HDFS_CRAWL_DIR/segments/ | tail -1`
echo ">> nutch invertlinks"
$BIN_DIR/nutch invertlinks $HDFS_CRAWL_DIR/linkdb -dir $HDFS_CRAWL_DIR/segments
echo ">> nutch inddex"
$BIN_DIR/nutch index $HDFS_CRAWL_DIR/crawldb/ -linkdb $HDFS_CRAWL_DIR/linkdb/ $LAST_SEG -filter -normalize -deleteGone -addBinaryContent -base64
echo ">> nutch dedup"
$BIN_DIR/nutch dedup $HDFS_CRAWL_DIR/crawldb
echo ">> nutch clean"
$BIN_DIR/nutch clean $HDFS_CRAWL_DIR/crawldb
