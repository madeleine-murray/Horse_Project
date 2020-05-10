# Pre-requisites:
# the python library "pandas" should be installed
# as well as the programs slim and sr of course

# SET PARAMETERS (with examples)
CODOM=$(seq 0 0.25 1) # as the co-domiance coefficient
SELCOEFF=$(seq 0.005 0.01 0.05) # as the selection coefficient (fitness)
Ne=$(seq 5000 10000 95000) # as the number of individuals in the population
SAMPSIZE=10 # as sample size (at each sampling time point)
SAMP0=3   # as the initial sampling point (required for the inference program to avoid stalling)
SAMP1=162 # as the 1st sampling time (in number of generations)
SAMP2=262 # as the 2nd sampling time (in number of generations)
SAMP3=312 # as the 3rd sampling time (in number of generations)
SAMP4=412 # as the 4th sampling time (in number of generations)
GEN=550 # as the number of total generations
TP=6 # as the number of sampling time points
REP=$(seq 1 1 10) # as replicates
ITERATIONS=2000000 # as the number of iterations for inference
finalOutput="results.txt" # as the name of the output result file
core=60 # the number of cores to run with parallel runs
PRINT=5000 # the frequency of iterations for inference (please increase the value for high number of runs and/or iterations to avoid servers crashing)
inferenceRuns=5 # the number of inference runs for each simulation
RUN=$(seq 1 1 $inferenceRuns)

# Avoid conflict between parallel runs
echo "IMPORTANT !!!"
echo "Don't forget to run the following line in your terminal before launching the script:"
echo "OMP_NUM_THREADS=1; OPENBLAS_NUM_THREADS=1;"

# GENERATE ALLELE FREQUENCIES WITH SLIM
echo "Simulating allele frequencies"
for codominance in $CODOM; do
    for seleccoeff in $SELCOEFF; do
        for popsize in $Ne; do
            for samplesize in $SAMPSIZE; do
 	        for samp0 in $SAMP0; do
 		    for samp1 in $SAMP1; do
 			for samp2 in $SAMP2; do
 			    for samp3 in $SAMP3; do
 				for samp4 in $SAMP4; do
 				    for gen in $GEN; do
 					for rep in $REP; do

 					    # define file name to keep track of parameters
 					    filename=sampling"$samplesize"_popSize"$popsize"_selecCoeff"$seleccoeff"_coDominance"$codominance"_rep"$rep"
					    
 					    # create a unique seed for each run (to avoid errors during parallel run)
                                             uniqueCodom=`echo "$codominance * 100" | bc`
                                             uniqueSelcoeff=`echo "$seleccoeff * 100" | bc`
                                             uniqueSeed=${uniqueCodom/.*}${uniqueSelcoeff/.*}$popsize$samplesize$rep$RANDOM # convert float to int

 					    # make temporary script for corresponding parameters
 					    echo `perl -p -e "s/CODOMINANCE/$codominance/g" /Horse_Projects/scripts/slimTemplates/slimScript_${TP}timePoints.txt | perl -p -e "s/SELECCOEFF/$seleccoeff/g" | perl -p -e "s/POPSIZE/$popsize/g" | perl -p -e "s/SAMPLESIZE/$samplesize/g" | perl -p -e "s/SAMPLING0/$samp0/g" | perl -p -e "s/SAMPLING1/$samp1/g" | perl -p -e "s/SAMPLING2/$samp2/g" | perl -p -e "s/SAMPLING3/$samp3/g" | perl -p -e "s/SAMPLING4/$samp4/g" | perl -p -e "s/GENERATION/$gen/g" | perl -p -e "s/REPLICATE/$rep/g" > /Horse_Projects/scripts/slimTemplates/templates/template_$filename.txt`

 					    # run simulation with slim using the temporary script and different seed number, while also checking that mutation is not lost, and keep only the last 6 lines
 					    echo "/Horse_Projects/scripts/slim -seed $uniqueSeed /Horse_Projects/scripts/slimTemplates/templates/template_$filename.txt | tail -$TP > /Horse_Projects/scripts/slimTemplates/generations/generated_$filename.txt"

 					done
 				    done
 				done
 			    done
 			done
 		    done
 		done
 	    done
	done
    done
done | parallel -j $core
echo "Finished simulating allele frequencies"

# INFERENCE FROM ALLELE FREQUENCY WITH SR
echo "Infering selection from allele frequencies"
for run in $RUN; do
    for codominance in $CODOM; do
	for seleccoeff in $SELCOEFF; do
	    for popsize in $Ne; do
		for samplesize in $SAMPSIZE; do
		    for rep in $REP; do
			
			# define file name to keep track of parameters
			filename=sampling"$samplesize"_popSize"$popsize"_selecCoeff"$seleccoeff"_coDominance"$codominance"_rep"$rep"
			
			# inference from allele frequency
			echo "bash /Horse_Projects/scripts/inference.sh $filename $popsize $ITERATIONS $PRINT $run"

		    done
		done
	    done
	done
    done
done | parallel -j $core
echo "Finished infering selection coefficient"

# SAVING ONLY THE 2nd HALF OF EACH INFERENCE
echo "Processing results"
bestHalf=`echo "$ITERATIONS / 200" | bc` # the number of lines we are expeting (200 = s flag * 2)
for codominance in $CODOM; do
    for seleccoeff in $SELCOEFF; do
        for popsize in $Ne; do
            for samplesize in $SAMPSIZE; do
                for rep in $REP; do

                    # define file name to keep track of parameters
                    filename=sampling"$samplesize"_popSize"$popsize"_selecCoeff"$seleccoeff"_coDominance"$codominance"_rep"$rep"
		    
		    # concatenate all the inferences for one replicate, keeping one header
                    head -1 /Horse_Projects/scripts/results/inferences/infered1_$filename.param > /Horse_Projects/scripts/results/inferences/infered_$filename.param #save the header line only
                    for run in $RUN; do
                        tail -n $bestHalf /Horse_Projects/scripts/results/inferences/infered${run}_$filename.param >> /Horse_Projects/scripts/results/inferences/infered_$filename.param #save the later half of each inference
                        #rm /Horse_Projects/scripts/results/inferences/infered${run}_$filename.param #remove intermediate files
                    done

                done
            done
        done
    done
done
echo "Finished processing results"

# OUTPUTING RESULTS
echo "Outputing results"
for codominance in $CODOM; do
    for seleccoeff in $SELCOEFF; do
        for popsize in $Ne; do
            for samplesize in $SAMPSIZE; do
                for rep in $REP; do

                    # define file name to keep track of parameters
                    filename=sampling"$samplesize"_popSize"$popsize"_selecCoeff"$seleccoeff"_coDominance"$codominance"_rep"$rep"

                    # output the successful runs into a single output file
                    obsLine=`wc -l /Horse_Projects/scripts/results/inferences/infered_$filename.param | cut -d" " -f1 | bc`
                    expLine=`echo "$(($ITERATIONS / 100 * $inferenceRuns / 2)) + 1" | bc` #divied by s flag, multiply by number of inference, divide by 2 because onle 2nd half, and add header
                    if [ $obsLine -eq $expLine ]; then
                        echo "python /Horse_Projects/scripts/createOutput.py /Horse_Projects/scripts/results/inferences/infered_$filename.param /Horse_Projects/scripts/results/$finalOutput"
                    fi

                done
            done
        done
    done
done | parallel -j $core
echo "Results are ready"
