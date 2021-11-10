cd images
num=`ls -1 | wc -l`
for i in `seq 1 $num`
do
  echo "=== $i ==="
  base64=`base64 $i.png`
  prefix="data:image/png;base64,"
  params="{\"uid\":\"testuid\",\"token_data\":\"$prefix$base64\"}"
  curl -X POST -H "Content-Type: application/json" -d $params test.tap.shmn7iii.net/v2/tokens
  echo ""
done