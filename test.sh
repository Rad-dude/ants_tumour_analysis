
usage()
{
cat<<EOF
usage: $0 options

===========================================================================

hope this works

============================================================================

EOF
}

input=


while getopts "hi" OPTION
do
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    i)
        input=$OPTARG
        ;;
    ?)
        usage
        exit
        ;;
    esac
done


if [[ -z $input ]]
then
    usage
    exit 1
fi

# Fail safe to prevent script execution with non-existent files.

echo ""
echo "Checking image ..."
echo ""

if [ -f $input ];
then
    echo "image is ok"
else
    echo "Cannot locate file $input. Please ensure the $input dataset is in this directory"
    exit 1
fi


