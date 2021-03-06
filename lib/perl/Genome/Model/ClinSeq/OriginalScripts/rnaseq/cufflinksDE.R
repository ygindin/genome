#!/usr/bin/env Rscript
#Written by Malachi Griffith
library(preprocessCore)

args = (commandArgs(TRUE))
matrix_file = args[1];              #Expression matrix file of cufflinks expression values generated by buildCufflinksFpkmMatrix.pl
group1_string = args[2];            #List of columns comprising group 1
group2_string = args[3];            #List of columns comprising group 2
outfile = args[4];

#matrix_file = "genes_fpkm.tsv"
#group1_string = "HG1_FPKM"
#group2_string = "BRC4_FPKM,BRC5_FPKM,BRC18_FPKM,BRC31_FPKM"

if (length(args) < 4){
  message_text2 = "cufflinksDE.R genes_fpkm.tsv 'HG1_FPKM' 'BRC4_FPKM,BRC5_FPKM,BRC18_FPKM,BRC31_FPKM' genes_fpkm_DE.tsv"
  print (message_text2, quote=FALSE)
  message_text1 = "Required arguments missing for cufflinksDE.R"
  stop(message_text1)
  message(message_text1)
  message(message_text2)
}

#Add an arbitrarily small value before calculating difference to stabilize variance
stab_var = 0.1

#Split the group strings
group1 = strsplit(group1_string, ",")[[1]]
group2 = strsplit(group2_string, ",")[[1]]

#Print out comparison to be conducted
print (paste(group1_string, " vs ", group2_string, sep= ""), quote=FALSE)
  
#Load input file
data = read.table(matrix_file, header=TRUE, as.is=c(1:4), sep="\t")
feature_count = length(data[,1])

print (paste("Imported feature count = ", feature_count, sep=""), quote=FALSE)

#Quantiles Normalize the data 
fpkm = data[,5:length(data[1,])]
x = as.matrix(fpkm)
fpkm_norm = normalize.quantiles(x)
fpkm_norm = as.data.frame(fpkm_norm)

#Replace the original FPKM data with the quantiles normalized values
data[,5:length(data[1,])] = fpkm_norm


#Calculate the mean of both groups
if (length(group1) == 1){
  data[,"Mean1"] = data[,group1]
  data[,"Median1"] = data[,group1]
}else{
  data[,"Mean1"] = apply(data[,group1], 1, mean)
  data[,"Median1"] = apply(data[,group1], 1, median)
}

if (length(group2) == 1){
  data[,"Mean2"] = data[,group2]
  data[,"Median2"] = data[,group2]
}else{
  data[,"Mean2"] = apply(data[,group2], 1, mean)
  data[,"Median2"] = apply(data[,group2], 1, median)
}

data[,"Log2Diff_Means"] = log2(data[,"Mean1"]+stab_var) - log2(data[,"Mean2"]+stab_var)
data[,"Log2Diff_Medians"] = log2(data[,"Median1"]+stab_var) - log2(data[,"Median2"]+stab_var)
o = order(abs(data[,"Log2Diff_Medians"]), decreasing=TRUE)

#Write the DE values out
write.table(data[o,], outfile, sep="\t", quote=FALSE, col.names=TRUE, row.names=FALSE)





