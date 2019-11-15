rm(list=ls(all=FALSE))
ls()

library(randomForest)
args <- commandArgs(trailingOnly = TRUE)

# function - opposite of %in%
'%!in%' <- function(x,y)!('%in%'(x,y)) 

################################################################################

if (length(args) > 0) {
    print(args)    
    User.Filename <- args[1]
    Output.Directory <- args[2]
    region <- args[3]
} else {
    stop("No arguments")
}


animal<-as.character(read.table(paste0("data/data_", region, "/animal_list.txt"))[,1])
bacterial_groups<-as.character(read.table(paste0("data/data_", region, "/bacterialgroup_list.txt"))[,1])


# User database
pre.user<-read.table(User.Filename, h=T, sep="\t", row.names = 1)
pre.user.1<-t(pre.user)
pred.withzero.prob<-matrix(data = NA, nrow = nrow(pre.user.1),  ncol = length(animal)); row.names(pred.withzero.prob)<-row.names(pre.user.1)
pred.withzero.response<-matrix(data = NA, nrow = nrow(pre.user.1),  ncol = length(animal)); row.names(pred.withzero.response)<-row.names(pre.user.1)
pred.names<-vector(length=length(animal))

for (y in 1:length(bacterial_groups)) {
    BacterialGroup=bacterial_groups[y]
    for (x in 1:length(animal)) { 
        Animal=animal[x]

        GiniFileName<-paste0("data/MDG_", region, "/", BacterialGroup, "_", Animal, ".txt")

        pre.names.seq.gini<-read.table(GiniFileName, h=F, sep="\t")
        names.seq.gini<-as.vector(pre.names.seq.gini$V1)

        fit_Filename<-paste0("data/RF_training_", region, "/fit_", BacterialGroup, "_", Animal, ".RData")
        load(fit_Filename)
        ################################################################################

        ##### Creation of the user dataset
        predata.user.1<-pre.user.1[, colnames(pre.user.1) %in% names.seq.gini]
        colname.notinuserdataset<-which(colnames(predata.user.1) %!in% names.seq.gini)
        predata.user.2<-matrix(data = 0, nrow = nrow(pre.user.1),  ncol = length(colname.notinuserdataset))
        colnames(predata.user.2)<-colname.notinuserdataset; row.names(predata.user.2)<-row.names(predata.user.1)
        if(ncol(pre.user)==1){
            predata.user.1.1<-as.data.frame(t(predata.user.1))
            predata.user.3<-cbind(predata.user.1.1, predata.user.2)
            row.names(predata.user.3)<-names(pre.user)
            }else{
                predata.user.3<-cbind(predata.user.1, predata.user.2)
        }
        predata.user.4<-sweep(predata.user.3, 1, rowSums(predata.user.3), '/')
        data.user<-replace(predata.user.4, is.na(predata.user.4),0)

        ##### Output results
        #prediction prob
        prediction.p<-as.data.frame(predict(fit, data.user, "prob"))
        pred.withzero.prob[, c(x)]<-prediction.p[, as.character(Animal)]*100
        pred.names[x]<-as.character(Animal)
        #prediction response
        pred.withzero.prob.dataframe<-as.data.frame(pred.withzero.prob[, c(x)])
        pred.withzero.response[,x]<-apply(pred.withzero.prob.dataframe, 2, function(y) ifelse(y > 50, paste(Animal, "(a)", sep=""), ifelse(y > 45, paste(Animal, "(b)", sep=""), ifelse(y > 40, paste(Animal, "(c)", sep=""), paste("-")))))
    }

    pred.withzero.prob.final<-rbind(pred.names, pred.withzero.prob); rownames(pred.withzero.prob.final)[1]<-" "

    write.table(pred.withzero.prob.final, paste0(Output.Directory, '_', BacterialGroup ,'_predprob.txt'), sep="\t", quote=FALSE, col.names = FALSE)

    pred.withzero.response.simple<-as.character(interaction(as.data.frame(pred.withzero.response),sep="/"))
    pred.withzero.response.simple.1<-as.data.frame(gsub("-/", "", pred.withzero.response.simple))
    pred.withzero.response.simple.final<-as.data.frame(lapply(pred.withzero.response.simple.1, gsub, pattern = "/-", replacement = "", fixed = FALSE))
    row.names(pred.withzero.response.simple.final)<-rownames(pred.withzero.prob)
    write.table(pred.withzero.response.simple.final, paste0(Output.Directory, '_', BacterialGroup , '_predresponse_simple.txt'), sep="\t", quote=FALSE, col.names = FALSE, row.names = TRUE)
}

