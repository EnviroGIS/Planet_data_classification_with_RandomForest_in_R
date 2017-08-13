# Rscript for QGIS Processing
# You need copy this file in `<USER>/.qgis2/processing/rscripts/` folder.
# Image classification with RandomForests in QGIS using the R language 
# Source 1: https://youtu.be/-6Hsase6xQw & https://gist.github.com/amsantac/5183c0c71a8dcbc27a4f
# Source 2: https://github.com/EnviroGIS/Planet_data_classification_with_RandomForest_in_R
##img=raster
##trainData=vector
##responseCol=field trainData
##nsamples=number 1000
##output=output raster
library(sp)
library(raster)
library(pbkrtest)
library(caret)

names(img) <- c(paste0("B", 1:4, coll = ""))

dfAll = data.frame(matrix(vector(), 0, length(names(img)) + 1))

for (i in 1:length(unique(trainData[[responseCol]]))){
  category <- unique(trainData[[responseCol]])[i]
  categorymap <- trainData[trainData[[responseCol]] == category,]
  dataSet <- extract(img, categorymap)
  dataSet <- dataSet[!unlist(lapply(dataSet, is.null))]
  dataSet <- lapply(dataSet, function(x){cbind(x, class = as.numeric(rep(category, nrow(x))))})
  df <- do.call("rbind", dataSet)
  dfAll <- rbind(dfAll, df)
}

sdfAll <- subset(dfAll[sample(1:nrow(dfAll), nsamples), ])

modFit_rf <- train(as.factor(class) ~ B1 + B2 + B3 + B4, method = "rf", data = sdfAll)

beginCluster()
preds_rf <- clusterR(img, raster::predict, args = list(model = modFit_rf))
endCluster()

output = preds_rf

