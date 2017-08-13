# Planet Image classification with RandomForests using the R language
Author of ideas [Ali Santacruz](https://github.com/amsantac). [Video in Youtube](https://youtu.be/fal4Jj81uMA), [A descriptive post in his blog](http://amsantac.co/blog/en/2015/11/28/classification-r.html), [Source](https://gist.github.com/amsantac/5183c0c71a8dcbc27a4f)

The algorithm is adapted for classification of [PlanetScope](https://www.planet.com/) data. [PlanetScope Imagery Products specification](https://www.planet.com/docs/spec-sheets/sat-imagery/). 

## Step-by-step instruction

### Start R and load the packages
Start **R** in terminal
> R

We will need these packages: 'snow', 'sp', 'ggplot2', 'raster','rgdal', 'pbkrtest', 'stats', 'e1071', 'lme4', 'lattice', 'randomForest', 'caret'.
You need to install the necessary packages, if they are not installed.
> install.packages(c("snow", "sp", "ggplot2", "raster", "rgdal", "pbkrtest", "stats", "e1071", "lme4", "lattice", "randomForest", "caret"), dependencies = TRUE)

Load the required packages.
> library("snow")

> library("sp")

> library("ggplot2")

> library("raster")

> library("rgdal")

> library("pbkrtest")

> library("stats")

> library("e1071")

> library("lme4")

> library("lattice")

> library("randomForest")

> library("caret")

### Load the data in R
Set the working directory with the data
> setwd("~/PlanetData/")

Load the raster file
> img <- brick("TIF/SourceRaster.tif")

Write the channel names in the raster object
> names(img) <- c(paste0("B", 1:4, coll = ""))

We can visualize the raster in the RSL. Not an obligatory step.
> plotRGB(img * (img >= 0), r = 3, g = 4, b = 1)

Add training data
> trainData <- shapefile("SHP/ROI.shp")

Indicate a field with classes
> responseCol <- "Class"

### Extracting training pixels values
> dfAll = data.frame(matrix(vector(), 0, length(names(img)) + 1))

> for (i in 1:length(unique(trainData[[responseCol]]))){

>   category <- unique(trainData[[responseCol]])[i]

>   categorymap <- trainData[trainData[[responseCol]] == category,]

>   dataSet <- extract(img, categorymap)

>   dataSet <- dataSet[!unlist(lapply(dataSet, is.null))]

>   dataSet <- lapply(dataSet, function(x){cbind(x, class = as.numeric(rep(category, nrow(x))))})

>   df <- do.call("rbind", dataSet)

>   dfAll <- rbind(dfAll, df)

> }

Generate random samples for training the RandomForests models (For a start, 10000 random samples). 
> nsamples <- 10000

> sdfAll <- subset(dfAll[sample(1:nrow(dfAll), nsamples), ])

### Model fitting and image classification
Next we must define and fit the RandomForests model using the train function from the **‘caret’** package.
First, let’s specify the model as a formula with the dependent variable (i.e., the land cover types ids) encoded as factors.
For this we will use four bands as explanatory variables (Blue, Green, Red, Near infrared bands). We then define the method as ‘rf’ which stands for the random forest algorithm. (Note: try names(getModelInfo()) to see a complete list of all the classification and regression methods available in the **‘caret’** package).
This step can last a very long time
> modFit_rf <- train(as.factor(class) ~ B1 + B2 + B3 + B4, method = "rf", data = sdfAll)


### Free up computer memory and CPU
After the previous step, the computer hangs, and can not start the data classification.
To free memory and CPU, you need to close **R** with the preservation of history and workspace.
> q("yes")

Close terminal
> exit

### Load the packages and data in R again
Open the terminal and start **R** again.
> R

Load the packages.
> library("snow")

> library("sp")

> library("ggplot2")

> library("raster")

> library("rgdal")

> library("pbkrtest")

> library("stats")

> library("e1071")

> library("lme4")

> library("lattice")

> library("randomForest")

> library("caret")

Set working directory with the data.
> setwd("~/PlanetData/")

Load previously created R objects.
> load(".RData")

### Create a raster with predictions
Use the 'clusterR' function from the **raster** package, which supports multi-core computations for functions such as forecasting.
> beginCluster()

> preds_rf <- clusterR(img, raster::predict, args = list(model = modFit_rf))

> endCluster()

Display the result of the classification
> plot(preds_rf)

Save the raster to a 'GeoTiff' file
> writeRaster(preds_rf, filename="ResultClassification.tif", format = "GTiff", datatype='INT1U', overwrite=TRUE)



