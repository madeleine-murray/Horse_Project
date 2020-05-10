filename=$1
popsize=$2
ITERATIONS=$3
PRINT=$4
run=$5

processed=0 #set the default number of line already processed at zero
expected=`echo "$ITERATIONS / 100" | bc` #the number of lines we are expeting for each inference (100 corresponds to s flag)
OMP_NUM_THREADS=1; OPENBLAS_NUM_THREADS=1; #avoid mashup during parallel runs

while [ $processed -ne $expected ]; do #while the number of processed line is different to the number of expected lines
    
    # infer with sr
    /Horse_Projects/scripts/sr -D /Horse_Projects/scripts/slimTemplates/generations/generated_$filename.txt -N $popsize -n $ITERATIONS -g 500 -F 20 -f $PRINT -s 100 -P /Horse_Projects/scripts/demography/$popsize.pop -e $RANDOM -o /Horse_Projects/scripts/results/inferences/infered${run}_$filename &>/dev/null

    # check inference has been processed fully (bugs rarely happen but best to avoid)
    gunzip -f /Horse_Projects/scripts/results/inferences/infered${run}_$filename.param.gz #unzip interesting file (overwriting previous file)
    line=`wc -l /Horse_Projects/scripts/results/inferences/infered${run}_$filename.param | cut -d" " -f1` #use the number of line in file as the number of iterations processed
    processed=`echo "$line - 1" | bc` #leave the header out to count the number of processed lines

done

rm /Horse_Projects/scripts/results/infences/infered${run}_$filename.time.gz
rm /Horse_Projects/scripts/results/inferences/infered${run}_$filename.traj.gz

# check that no output file exists                                                                                                                                                                      
if [ -f /tmp/$filename.err ]; then #if such file exists                                                                                                                                                 
    rm -f /tmp/$filename.err #then remove it
fi
