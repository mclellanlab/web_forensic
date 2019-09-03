rm(list=ls(all=FALSE))
ls()

library(vegan)

# function - opposite of %in%
'%!in%' <- function(x,y)!('%in%'(x,y)) 




################################################################################
workingDirectory = '~/Desktop/RF/Paper66/'
region = 'v6'

UserDataset =  "ArtificialSample_user_2" #UnknownSample_user ArtificialSample_user

## Random Forest nº1
NbTree1 = 10000
Repeat1 = 100

## Random Forest nº2
NbTree2 = 1000
################################################################################




################################################################################
animal<-c("Cat", "Dog", "Pet", "Cow", "Deer", "Ruminant", "Pig", "Sewage")
BacterialGroup<-c('Clostridiales', 'Bacteroidales')

User.Filename<-paste(workingDirectory, "Classification/", UserDataset, ".txt", sep="")
pretitle<-read.table(paste(workingDirectory, "Preparation/Preparation_ReferenceSamples/SampleType.txt", sep=""), header=TRUE, sep="\t")
pred.names<-vector(length=length(animal))
################################################################################




# Test database
pre.user<-read.table(User.Filename, h=T, sep="\t")
pre.user.1<-t(pre.user)






###########################################################################################################################################################
################################### Use sequences from the test dataset that don't watch with the train dataset ###########################################
############ It means that all the sequences from the train dataset will be used, even when a sequence has not been found in the test dataset ############# 
###########################################################################################################################################################
braycurtis<-matrix(data = NA, nrow = nrow(pre.user.1),  ncol = length(animal)); row.names(braycurtis)<-row.names(pre.user.1)



for (y in 1:length(BacterialGroup)) {
  
  ##########################################################################################
  Order=BacterialGroup[y]
  OutputName = paste(dirname,'BrayCurtis_', Order, "_", UserDataset,".txt", sep="")
  workingDirectory1<-paste(workingDirectory, "Classification/", Order,"_", region, "/", sep="")
  TrainingFileName<-paste(workingDirectory1, Order, "_data_", region, '.txt', sep="")
  dirname<-paste(workingDirectory1, "Results_RF_4.1/", sep="")
  ##########################################################################################
  
  # Train database
  predata.training<-read.table(TrainingFileName, sep="\t", h=T, row.names = 1)
  
 
  


for (x in 1:length(animal)) { 
  
  ################################################################################
  Animal=animal[x]
  GiniFileName<-paste(workingDirectory1, "Gini/", BacterialGroup, "_Gini_", Repeat1, "x_", NbTree1, "trees_", Animal, ".txt", sep="")
  pre.names.seq.gini<-read.table(GiniFileName, h=F, sep="\t")
  names.seq.gini<-as.vector(pre.names.seq.gini$V1)
  ################################################################################
  
  
  # creation of the train dataset 
  pretitle1=title=data=data.training=predata.training.2=predata.training.3=predata.training.4=0
  pretitle1<-as.vector(pretitle$Animal)
  
  if(Animal=='Pet'){
    title.1.cat<-gsub("Cat","Pet",pretitle1,ignore.case=F)
    title.1.cat.dog<-gsub("Dog","Pet",title.1.cat,ignore.case=F)
    title<-replace(title.1.cat.dog, which(title.1.cat.dog!=Animal) , "Other")
  } else if(Animal=='Ruminant') {
    title.1.cow<-gsub("Cow","Ruminant",pretitle1,ignore.case=F)
    title.1.cow.deer<-gsub("Deer","Ruminant",title.1.cow,ignore.case=F)
    title<-replace(title.1.cow.deer, which(title.1.cow.deer!=Animal) , "Other")
  } else {
    title<-replace(pretitle1, which(pretitle1!=Animal) , "Other")
  } 
  
  predata.training.1<-cbind(title, predata.training)
  predata.training.2<-subset(predata.training.1, title!="Other")[,-1]
  predata.training.3<-predata.training.2[, colnames(predata.training.2) %in% names.seq.gini]
  predata.training.4<-sweep(predata.training.3, 1, rowSums(predata.training.3), '/')
  predata.training.5<-replace(predata.training.4, is.na(predata.training.4),0)
  mean.training<-as.data.frame(t(apply(predata.training.5,2, mean))); row.names(mean.training)<-Animal
  #data.training<-rbind(predata.training.5,mean.training)
  data.training<-mean.training
  
  ##### Creation of the test dataset
  predata.testing.1=colname.notintestingdataset=predata.testing.2=predata.testing.3=predata.testing.4=data.testing=0
  predata.testing.1<-pre.user.1[, colnames(pre.user.1) %in% colnames(data.training)]
  colname.notintestingdataset<-colnames(data.training[, !(colnames(data.training) %in% colnames(predata.testing.1))])
  predata.testing.2<-matrix(data = 0, nrow = nrow(pre.user.1),  ncol = length(colname.notintestingdataset))
  colnames(predata.testing.2)<-colname.notintestingdataset; row.names(predata.testing.2)<-row.names(predata.testing.1)
  predata.testing.3<-cbind(predata.testing.1, predata.testing.2)
  predata.testing.4<-sweep(predata.testing.3, 1, rowSums(predata.testing.3), '/')
  data.testing<-replace(predata.testing.4, is.na(predata.testing.4),0)
  
  
  ##### Merge both dataset
  dataset<-rbind(data.training, data.testing)
  
  
  
  
  ##### Bray-Curtis
  dist.data<-vegdist(dataset, method="bray")
  braycurtis[,x]<-as.matrix(dist.data)[-1,1]
  
  }

  
  braycurtis.final<-as.data.frame(braycurtis)
  names(braycurtis.final)<-animal
  write.table(braycurtis.final, OutputName, sep="\t", quote=FALSE, col.names = TRUE, row.names = TRUE)
  
  
}
