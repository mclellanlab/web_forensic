rm(list=ls(all=FALSE))
ls()

library(vegan)

# function - opposite of %in%
'%!in%' <- function(x,y)!('%in%'(x,y)) 



# if script is ran by web service using Rscript
# we are going to overwrite input and output variables
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  print(args)
  User.Filename <- args[1]
  output_directory <- args[2]
  region <- args[3]
}



if (region == 'V6') {
  animal<-c( "Cat", "Dog", "Pet", "Cow", "Deer", "Ruminant", "Pig", "Sewage")
} else {
  animal<-c("Cat", "Dog", "Pet", "Cow", "Deer", "Ruminant", "Pig", "Sewage")
}



pred.names<-vector(length=length(animal))
bacterial_groups<-c("Bacteroidales", "Clostridiales")


for (y in 1:length(bacterial_groups)) {
  BacterialGroup=bacterial_groups[y]



# Import
pre.training<-read.table(paste0("data/", BacterialGroup, "_data_", region, ".txt"), sep="\t", h=T, row.names = 1)
pre.data.user<-read.table(User.Filename, h=T, sep="\t", row.names = 1)

training<-pre.training[,-1]
pretitle<-as.vector(pre.training[,1])
data.user<-t(pre.data.user)




braycurtis<-matrix(data = NA, nrow = nrow(data.user),  ncol = length(animal))
row.names(braycurtis)<-row.names(data.user)




for (x in 1:length(animal)) { 
  
  ################################################################################
  Animal=animal[x]
  Gini<-read.table(paste0("data/Gini_", BacterialGroup, "_", region, "/", Animal, ".txt"), h=F, sep='\t')
  names.seq.gini<-as.vector(Gini$V1)
  ################################################################################
  
  
  # creation of the train dataset 
  title=data=data.training=training.2=training.3=training.4=0
  
  if(Animal=='Pet'){
    title.1.cat<-gsub("Cat","Pet",pretitle,ignore.case=F)
    title.1.cat.dog<-gsub("Dog","Pet",title.1.cat,ignore.case=F)
    title<-replace(title.1.cat.dog, which(title.1.cat.dog!=Animal) , "Other")
  } else if(Animal=='Ruminant') {
    title.1.cow<-gsub("Cow","Ruminant",pretitle,ignore.case=F)
    title.1.cow.deer<-gsub("Deer","Ruminant",title.1.cow,ignore.case=F)
    title<-replace(title.1.cow.deer, which(title.1.cow.deer!=Animal) , "Other")
  } else {
    title<-replace(pretitle, which(pretitle!=Animal) , "Other")
  } 
  
  training.1<-cbind(title, training)
  training.2<-subset(training.1, title!="Other")[,-1]
  training.3<-training.2[, colnames(training.2) %in% names.seq.gini]
  training.4<-sweep(training.3, 1, rowSums(training.3), '/')
  training.5<-replace(training.4, is.na(training.4),0)
  mean.training<-as.data.frame(t(apply(training.5,2, mean))); row.names(mean.training)<-Animal
  data.training<-mean.training
  
  
  ##### Creation of the test dataset
  predata.testing.1=colname.notintestingdataset=predata.testing.2=predata.testing.3=predata.testing.4=data.testing=0
  predata.testing.1<-data.user[, colnames(data.user) %in% colnames(data.training)]
  colname.notintestingdataset<-colnames(data.training[, !(colnames(data.training) %in% colnames(predata.testing.1))])
  predata.testing.2<-matrix(data = 0, nrow = nrow(data.user),  ncol = length(colname.notintestingdataset))
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
write.table(braycurtis.final, paste0(output_directory, '_BrayCurtis_', BacterialGroup , '.txt'), sep="\t", quote=FALSE, col.names = TRUE, row.names = TRUE)

}
