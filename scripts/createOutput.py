#!/disk/regine/data2/madeleine/simulations/messer/playground/python
# written by Madeleine Murray

# COMPARING DIFFERENT PARAMATERS
# Refer to the script it is used in:
# generatingWithSlimAndInferingWithSr.sh
# Warning: filenames must have the same structure as in script
# and .param & .time should be in the same directory

# INPUT DESCRIPTION
# First argument: name of input file (with extension .param)
# Second argument: name of output file
# NB: this code will not overwrite output file,
# but will add a new row for each input file.

# OUTPUT DESCRIPTION
# First column:    selection coefficient that was generated
# Second column:   average selection coefficient that was infered
# Third column:    variance of inferred selection coefficient
# Fourth column:   lower end of confidence interval of the average selection coefficient that was inferred
# Fifth column:    higher end of confidence interval of the average selection coefficient that was inferres
# Sixth column:    maximum likelyhood that was inferred
# Seventh column:  selection coefficient corresponding to the maximum likelyhood
# Eigth column:    co-dominance coefficient
# Ninth column:    population size
# Tenth column:    sample size
# Eleventh column: replicate identification


from sys import argv #argument for input file
import re #regular expression
import pandas as pd #using data frames
import os.path #check output file exsitence


inputFile = argv[1] #set input file as first argument
outputFile = argv[2] #choose output file name as second argument


def extractInfoFromFileName(startStr, endStr):
    '''Extract anything you want from the input file name'''
    startPos = re.search(startStr, inputFile).end() #obtain the start position
    endPos = re.search(endStr, inputFile).start() #obtain the end position
    result = inputFile[startPos:endPos] #find what you are search for using the start and end positions
    return result


def extractInferredSelectionCoefficient():
    '''Extract all  information from file'''
    
    inferredFile = pd.read_csv(inputFile, sep='\t') #import data from file
    popSize = extractInfoFromFileName("_popSize", "_selecCoeff") #extract population size
    inferredFile['s'] = inferredFile['alpha2'] / float(popSize) #divide alpha2 by population size to obtain selection coefficient
    iterationsInfered = 0 #as the number of iterations that were infered
    for line in open(inputFile).xreadlines(  ): iterationsInfered += 1
    inferredFile = inferredFile.sort_values(by=['s']) #sort data frame by selection coefficient
    
    global sMean, sVar, lowCI, highCI, maxLNL, sMaxLNL, alleleAge
    sMean = inferredFile['s'].mean() #return average 's'
    sVar = inferredFile['s'].var() #return variance 's'
    lowCIindex = int(round( iterationsInfered * 2.5 / 100 )) #corresponds to the 2.5% cut-off
    highCIindex = int(round( iterationsInfered * 97.5 / 100 )) #corresponds to the 97.5% cut-off
    lowCI = inferredFile['s'].iloc[lowCIindex] #calculate the lower end of the confidence interval
    highCI = inferredFile['s'].iloc[highCIindex] #calculate the high end of the confidence interval
    maxLNL = inferredFile['lnL'].max() #return the maximum value of 'lnL'
    sMaxLNL = inferredFile.loc[inferredFile['lnL'] == maxLNL, 's'].iloc[0] #find the associated selection coefficent


def main():
    '''Main function generating the output file: adds one row to output file'''
    
    # Extract information from file name
    sampling    = extractInfoFromFileName("_sampling", "_popSize") #sampling size
    popSize     = extractInfoFromFileName("_popSize", "_selecCoeff") #population size
    selCoeff    = extractInfoFromFileName("_selecCoeff", "_coDominance") #generated selection coefficient
    coDominance = extractInfoFromFileName("_coDominance", "_rep") #co dominance
    rep         = extractInfoFromFileName("_rep", ".param") #replicate ID
    
    # Extract information from file content
    extractInferredSelectionCoefficient()

    # Create file if it doesn't exist yet
    if not os.path.exists(outputFile):
        newFile = open(outputFile, 'w') #create file
        newFile.write("s-generated\ts-infered\ts-var\tlow-CI\thigh-CI\tmaxLNL\ts-LNL\th\tNe\tsample\trep-id\n") #and add header (tab separated)
        newFile.close()

    # Writes information to output file
    row = selCoeff+'\t'+str(sMean)+'\t'+str(sVar)+'\t'+str(lowCI)+'\t'+str(highCI)+'\t'+'\t'+str(maxLNL)+'\t'+str(sMaxLNL)+'\t'+coDominance+'\t'+popSize+'\t'+sampling+'\t'+rep #create row (tab seperated)
    finalOutput = open(outputFile, 'a')
    finalOutput.write(row + '\n') #add row
    finalOutput.close()


if __name__ == "__main__":
    main()

