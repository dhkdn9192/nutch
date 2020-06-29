#! /bin/bash


BASE_DIR=$NUTCH_HOME
BIN_DIR=$BASE_DIR/runtime/local/bin
CRAWL_DIR=$BASE_DIR/crawl
ROUND_N=2


if [ -z "$BASE_DIR" ]; then
    echo "BASE_DIR does not exist... exit"
    exit 100
else
    echo "BASE_DIR is $BASE_DIR"
fi


echo "deleting crawl dir..."
rm -rf $CRAWL_DIR
mkdir $CRAWL_DIR


$BIN_DIR/nutch inject $CRAWL_DIR/crawldb $BASE_DIR/urls


for i in $(seq 1 $ROUND_N); do
    $BIN_DIR/nutch generate $CRAWL_DIR/crawldb $CRAWL_DIR/segments
    LAST_SEG=`ls -d $CRAWL_DIR/segments/2* | tail -1`
    $BIN_DIR/nutch fetch $LAST_SEG
    $BIN_DIR/nutch parse $LAST_SEG
    $BIN_DIR/nutch updatedb $CRAWL_DIR/crawldb $LAST_SEG
done


LAST_SEG=`ls -d $CRAWL_DIR/segments/2* | tail -1`
$BIN_DIR/nutch invertlinks $CRAWL_DIR/linkdb -dir $CRAWL_DIR/segments
$BIN_DIR/nutch index $CRAWL_DIR/crawldb/ -linkdb $CRAWL_DIR/linkdb/ $LAST_SEG -filter -normalize -deleteGone -addBinaryContent -base64
$BIN_DIR/nutch dedup $CRAWL_DIR/crawldb
$BIN_DIR/nutch clean $CRAWL_DIR/crawldb
