rm(list=ls(all=FALSE))
ls()
options(error=traceback)


#library(devtools)
#library(plyr)
library(dplyr)
#library(reshape2)






# if script is ran by web service using Rscript
# we are going to overwrite input and output variables
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
    print(args)
    User.Filename <- args[1]
    Output.Directory <- args[2]
    region <- args[3]
}


animal<-as.character(read.table(paste0("data/data_", region, "/animal_list.txt"))[,1])
bacterial_groups<-as.character(read.table(paste0("data/data_", region, "/bacterialgroup_list.txt"))[,1])


bubbleplot_directory <- paste0(Output.Directory, "_bubbleplot")
dir.create(bubbleplot_directory)

for (y in 1:length(bacterial_groups)) {
    BacterialGroup=bacterial_groups[y]

    # Importation
    gini<-read.table(paste0("data/MDG_", region, "/list_ASVs_", BacterialGroup, ".txt"), sep="\t", h=T)
    predata<-read.table(User.Filename, h=T, sep="\t", row.names = 1)
    
    ###############################################################################################
    # Estimation of the relative proportions for each ASV
    data.gini<-subset(predata, rownames(predata) %in% gini$SequenceID)
    data.gini.ra<-sweep(data.gini, 2, colSums(data.gini), '/')
    apply(data.gini.ra, 2, sum)
    data.gini.ra<-replace(data.gini.ra, is.na(data.gini.ra),0)
    data.gini.ra.seqID<-cbind(row.names(data.gini.ra), data.gini.ra); names(data.gini.ra.seqID)[1]<-"SequenceID"
    ## Merge gini and relative abundance of the sequences used in the classifiers
    pred.ra<-merge(gini, data.gini.ra.seqID, by=c("SequenceID","SequenceID"))
    names(pred.ra)[1:2]<-c("ASV", "Source")



    ###############################################################################################
    # Estimation of the proportions for all animal-sources classifier within the user samples. 
    pred.sum<-aggregate(. ~ Source, pred.ra[,-1], sum)
    row.names(pred.sum)<-pred.sum$Source
    pred.sum<-cbind(pred.sum$Source, (pred.sum[,-1])*100)
    names(pred.sum)[1]<-"Source"





    ###############################################################################################
    ####### Bubble plot ###########################################################################
    ###############################################################################################

for (z in 1:length(names(predata))) {
  
        Sample<-names(predata)[z]

        # Extract the data related to the selected sample 
        ASV.data<-pred.ra[,c("ASV", "Source", Sample)]
        ASV.data[,3]<-round(ASV.data[,3]*100, 2)

        Source.data<-pred.sum[,c("Source", Sample)]
        data<-as.data.frame(predata[,c(Sample)])

        names(ASV.data)<-c("ASV", "Source", "RelativeAbundance")
        names(data)<-"Count"; data$ASV<-row.names(predata)
        names(Source.data)<-c("Source", "Contribution")

        # Creation of the MATCH column - Is the ASV was found in the tested sample (yes/no)?
        ASV.data$MATCH<-ifelse(ASV.data[,3]>0, "yes", "no")

        # Add read counts 
        ASV.data$Count<-data$Count[match(ASV.data$ASV, data$ASV)]


        # Add 0.001 of all the zero values to be able to see the ASV on the plot
        ASV.data$RelativeAbundance_notzero<-ifelse(ASV.data[,3]==0, 0.001, ASV.data[,3])

        # Add SourceContribution to the database
        ASV.data$SourceContribution<-Source.data$Contribution[match(ASV.data$Source, Source.data$Source)]
              #  print(head(Source.data$Contribution))

        # Calculate frequency of detection of the ASV + Sources
        ASV.freq.count<-count(ASV.data, ASV);names(ASV.freq.count)<-c("ASV","Count")
        Source.freq.count<-count(ASV.data, Source);names(Source.freq.count)<-c("Source","Count")

        ASV.data$Freq.count.ASV<-ASV.freq.count$Count[match(ASV.data$ASV, ASV.freq.count$ASV)]
        ASV.data$Freq.count.Source<-Source.freq.count$Count[match(ASV.data$Source, Source.freq.count$Source)]
        
        # Calculation of Relative abundance of ASV + SourceContribution weighted by frequencies
        ASV.data$RelativeAbundanceWEIGHT<-(ASV.data$RelativeAbundance/ASV.data$Freq.count.ASV)+0.001
        ASV.data$CountWEIGHT<-round(ASV.data$Count/ASV.data$Freq.count.ASV, digits = 0)

        ASV.data$SourceContributionWEIGHT<-ASV.data$SourceContribution/ASV.data$Freq.count.Source

        # Calculation of Relative abundance per source
        RelativeAbundanceSource <- ASV.data %>% group_by(Source) %>% 
          mutate(per=round(RelativeAbundance/sum(RelativeAbundance)*100, 2)) %>% 
          ungroup %>% select(per)
        RelativeAbundanceSource[is.na(RelativeAbundanceSource)] <- 0

        ASV.data<-cbind(ASV.data, RelativeAbundanceSource$per)
        names(ASV.data)[13]<-c("RelativeAbundanceSource")

        ASV.data<-ASV.data[,-c(5:6,8:9)]

        write.csv(ASV.data, paste0(bubbleplot_directory, "/", BacterialGroup, "_", Sample, ".csv"), quote = FALSE, row.names = FALSE)
    }
}



