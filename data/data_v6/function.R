pig<-(results.notCatDogCowDeer$pig+results.notPetRuminant$pig)/2
sewage<-(results.notCatDogCowDeer$sewage+results.notPetRuminant$sewage)/2

pre.pred.mean<-as.data.frame(cbind(
  results.notPetRuminant$cat, 
  results.notPetRuminant$dog, 
  results.notCatDogCowDeer$pet, 
  results.notPetRuminant$cow, 
  results.notPetRuminant$deer, 
  results.notCatDogCowDeer$ruminant, 
  pig, 
  sewage))

names(pre.pred.mean)<-animal
row.names(pre.pred.mean)<-row.names(results.notCatDogCowDeer)
pred.mean<-as.data.frame(t(pre.pred.mean))
pred.mean$Source<-row.names(pred.mean)

