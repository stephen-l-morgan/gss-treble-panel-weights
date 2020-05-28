#===============================================================================================     
# IMPUTE CORE VARIABLES GSS PANEL ALL YEARS COMBINED USING -missForest- PACKAGE
# AUTHOR: JIWON LEE
#===============================================================================================

### <<SET-UP>> ---------------------------------------------------------------------------------

#clear console  
cat("\014")
rm(list = ls())

# Set your working directory here:
setwd("") 

# install and library relevant packages 
# install.packages("missForest", dependencies = TRUE)
# install.packages("foreign")
# install.packages(c( "foreach", "iterators", "parallel", "doParallel") ) 
library(missForest) # package for random foreest imputation
library(foreign) # package to save as a stata .dta file
library(doParallel) # package for parallel processing
library(dplyr)

### <<IMPUTATION AND SAVE AS A DATASET>> --------------------------------------------------------

# <<List of Variables to impute>>
# YEAR:	Survey year
# AGE:	Age of respondent
# SEX:	Sex of respondent
# RACEHISP:	Race of respondent (reconstructed)
# BORN:	Respondent's U.S-born status
# PARBORN:	Parent's U.S-born status
# MARITAL:	R's Marital Status
# RELIG:	R's religious preference
# DEGREE:	R's highest degree
# REALINC:	R's family income
# REALRINC:	R's personal income
# CLASS:	R's subjective class identification
# INCOM16:	R's family income level at age 16
# MAEDG:	Mother's highest degree
# PADEG:	Father's highest degree
# SPDEG:	Spouse's highest degree
# CODEG:	Cohabitant's highest degree
# WRKSTAT:	R's labor force status
# REGION:	R's region of interview
# FAMILY16:	Living with parents at age 16
# REG16:	R's region of residence at age 16
# EGP10_11:	R's EGP class
# PAEGP10_11:	Father's EGP class
# MAEGP10_11:	Mother's EGP class
# SPEGP10_11: Spouse's EGP class
# COEGP10_11:	Cohabitant's EGP class
# INTAGE:	Age of interviewer
# INTSEX:	Sex of interviewer
# INTETHN:	Rage of interviewer
# INTYRS:	Years of service as an intervieweR
# LNGTHINV:	How long the interview went
# COOP:	R's attitude towards interview
# DAYSINT:	Modified to days since first interview
# SPANENG:	Interview in Spanish or English
# MODE:	Interview in-person or over the phone
# FEEUSED:	R received fee for interview
# WORDSUM:	No. words correct in vocabulary test
# COMPREND: Rs understanding of questions
# DWELOWN: Does r own or rent home?
# SIZE: Size of place in 1000s
# XNORCSIZ: Expanded norc. size code


# import data
data <- read.csv("data/gss-panel-vars-to-impute.csv", header=TRUE, sep=",")

# number of cores for parallell computing
no.of.cores=4
registerDoParallel(cores = no.of.cores)

# creat flags for missing data
imputevars_m <- data 
imputevars_m[ , paste0( "m_",names(imputevars_m)[-1])] <- lapply(imputevars_m[-1], function(x) as.numeric(is.na(x)))
imputevars_m <- imputevars_m[ , grepl( "m_" , names( imputevars_m ) ) ]
imputevars_m <- cbind(data$year, data$samptype,  data$id, data$panelid, data$panelwave,  imputevars_m)

for (j in c("year", "samptype", "id", "panelid", "panelwave")) {
  names(imputevars_m)[names(imputevars_m) == paste0("data$",j)] <- j
}


### create 2 completed datasets
for (i in 6){
  
# convert columns with categorical data to factors
  for (k in c(
    "year", "samptype", "panelwave", "degree", "uscitzn", "region", "dwelown", "xnorcsiz", "marital", "relig", "class", "spdeg", 
    "madeg", "padeg", "wrkstat", "sex", "born","parborn", "family16", "reg16", "incom16", "intsex", 
    "intethn", "coop", "comprend", "spaneng", "mode", "feeused", "egp10_11", "spegp10_11", "paegp10_11", 
    "maegp10_11", "racehisp5", "evercitzn")) {
      data[[k]] <- as.factor(data[[k]])
      print(class(data[[k]]))
  }

  # ### rename variables
  # imputevars <- imputevars[,grepl(names(imputevars), "_rf") ]

  ### random forest imputation: WE'VE SET IT TO 5 ITERATIONS AND 500 TREES BUT OPEN TO MAKE MODIFICATIONS!
  imputed <- missForest(data[, -which(names(data) == "panelid")], maxiter = 5, ntree = 500, verbose = TRUE, parallelize="variables")
  ## The estimated error:
  imputed$OOBerror
  ## The true imputation error (if available):
  imputed$error
  imputed <- as.data.frame(imputed$ximp)
  
  # display warnings
  warnings()

  # convert all variables back to numerical variables
  imputed <- data.frame(lapply(imputed, function(x) as.numeric(as.character(x))))
  
  # create a indicator variable for imputation set
  imputed$flag <- rep(i,nrow(imputed))
  assign(paste("imputed_",i, sep=""), imputed)

}

### append all the datasets
imputed_appended <- as.data.frame(imputed_1, imputed_2, imputed_3, imputed_4, imputed_5, imputed_6)

### merge flags for missing
imputed_appended <- merge(imputed_appended, imputevars_m, by=c("year", "id",  "samptype"))

# sort observations 
imputed_appended <- imputed_appended[order(imputed_appended$samptype, 
                                           imputed_appended$panelwave.x, 
                                           imputed_appended$panelid, 
                                           imputed_appended$flag),]

### save as a dta file
write.dta(imputed_appended,"data/gss-panel-imputed-rf-final-1-6.dta")
