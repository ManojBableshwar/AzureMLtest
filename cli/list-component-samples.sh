
if [[ -z "$COMPONENT_SAMPLE_ROOT" ]]
then
    echo "env var COMPONENT_SAMPLE_ROOT not set"
    exit 1
fi

cd $COMPONENT_SAMPLE_ROOT

for sample in $(find . -name pipeline.yml | grep -v 1b | sed 's/\.//' | sed 's/\///' | sed 's/\/pipeline\.yml//')
do
  matrix="$matrix,\"$sample\""
done
matrix=$(echo $matrix | sed 's/,//')

echo "::set-output name=sample_matrix::[$matrix]"