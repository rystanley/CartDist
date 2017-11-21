#A function to convert a dataframe (as a .csv file) of coordinates to Cartesian coordinates.
#Calculates least-cost distances among sites in water. 
#Then plots a map of points, a linear model of least-cost geographic vs Cartesian distances, and adds Cartesian coordinates to your input file.
#If any sites are too close to land it will stop, as it requires depths <0 metres. 

coord_cartesian <- function(coordinates,min.depth=NA,max.depth=NA,trans=NA,gridres=2,directory=NA,outpath=NA){
  
  #coordinates - path to a csv file with the coordinates and site names. This must have three columns the first being the site name, second the longitude and third the latitude.
  #min.depth   - minimum depth that can be considered passable in the least-cost analysis. Note that depths are negative. Default is NA or 0.
  #max.depth   - maximum depth that can be considred passable in the least-cost analysis. Note that depths are negative. Default is NA or NULL meaning the analysis depths will permit movement between the min.depth and the maximum depth of the derived bathymetric layer.
  #trans       - is a transition object (marmap) that might have been calcualted in a previous analysis. Note that each run will return the transition object. This object can called from the workspace into the fuction. 
  #gridres     - resolution (mins) of the bathymetric grid used for least coast path (default = 2)
  #directory   - if specified this is where marmap will save and or look for the output for the bathy object created by marmap. 
  #outpath     - this is the filepath for the output from the function a .Rdata file. Note this must be a full file path ending in .RData. If no path is provided a 'Output' .RData file will be created in the current directory.
  
  #Libraries ----------
  #Check to make sure the packages required are there and install missing
  
  writeLines("\nChecking on package availability.\n")
  packages <- c("gdistance", "ggplot2", "marmap","vegan")
  if (length(setdiff(packages, rownames(installed.packages()))) > 0) { 
    writeLines(paste("Installing missing packages: ",paste(setdiff(packages, rownames(installed.packages())),collapse=", "),sep=" "))
    install.packages(setdiff(packages, rownames(installed.packages())))  
  } 
  
  #load each library
  require(gdistance)
  require(marmap)
  require(vegan)
  require(ggplot2)
  
  ## check the outpath
  if(!is.na(outpath) & substring(outpath,nchar(outpath)-5,nchar(outpath))!= ".RData"){
    stop("\nParamter outpath must be a full path ending in .RData. Please fix and try again.\n")
  }
  
  #Plotting settings for water bathymetry fill
  blues <- c("lightsteelblue4", "lightsteelblue3",
             "lightsteelblue2", "lightsteelblue1")
  greys <- c(grey(0.6), grey(0.93), grey(0.99))
  
  ##read in coordinates and check format
  coords<-read.csv(coordinates,header=T,stringsAsFactors = FALSE)
  
  writeLines("\nEnsure that your data is set up as three columns with the first column having the sample location name, the second with the longitude and the third with the latitude. \n")
  
  if (length(colnames(coords))<3 | !is.numeric(coords[,2]) | !is.numeric(coords[,3])){
    stop("\nCheck coordinate input, there is a problem here.\n")
  }
  
  #Clean up column names
  colnames(coords)[which(sapply(coords,is.character))[1]] <- "Code"
  colnames(coords)[which(sapply(coords,is.numeric))[1]] <- "Long"
  colnames(coords)[which(sapply(coords,is.numeric))[2]] <- "Lat"

  
  ## Set map limits------adding and subtracting 2 degrees to make the lc.dists function work better
  Lat.lim=c(min(coords$Lat)-2,max(coords$Lat)+2)
  Long.lim=c(min(coords$Long)-2,max(coords$Long)+2)
  
  #Get the bathydata and keep it
  holddir <- getwd() # grab working directory
  
  # directory is specified.
  if(!is.na(directory)){
  setwd(directory) # switch to the output directory
  writeLines("\nGetting bathymetry data from NOAA database\n")
  bathydata<-marmap::getNOAA.bathy(lon1 = Long.lim[1], lon2 = Long.lim[2], lat1 = Lat.lim[1], lat2 = Lat.lim[2],
                           resolution = gridres,keep=TRUE)
  setwd(holddir)
  } # set back to the working directory
  
  #directory is not specified.
  if(is.na(directory)){
    writeLines("\nGetting bathymetry data from NOAA database\n")
    bathydata<-marmap::getNOAA.bathy(lon1 = Long.lim[1], lon2 = Long.lim[2], lat1 = Lat.lim[1], lat2 = Lat.lim[2],
                                     resolution = gridres,keep=FALSE)
  }
  

  ### check depths to ensure they are all in water (e.g., no positive 'land' depths)
  
  #Get depths and plot. If any depths > 0 we will not proceed
  depths<-marmap::get.depth(bathydata,x=coords$Long,y=coords$Lat,locator=F)
  colnames(depths) <- c("Long","Lat","depth")
  coords <- merge(coords,depths,by=c("Long","Lat"))
  
  #colours to assign those locations which are in water "green" and on land "red". 
  coords$col <- "green"
  coords[coords$depth>=0,"col"] <- "red"
  
  if(length(which(depths$depth>0))!=0){
    
    writeLines("\nSome of your coordinates appear to have a positive depth. Refer to map and bump coordinates for those points marked as 'red' off of land. Suggest moving points farther off land for this analysis.\n")
   
    marmap::plot.bathy(bathydata,image = TRUE, land = T, lwd = 0.03,
                       bpal = list(c(0, max(bathydata), greys),
                                   c(min(bathydata), 0, blues)),deep=0,shallow=0)
    
    marmap::plot.bathy(bathydata, lwd = 1, deep = 0, shallow = 0, step = 0, add = TRUE)
    
    legend("bottomright",
           legend = c("Water","Land"), 
           col=c("green","red"),
           pch=19,
           pt.cex=1.5,
           bg="white")
    
  points(coords$Long, coords$Lat,pch=19,cex=2,col=coords$col)
    
  print(coords[coords$depth>0,c("Code","Long","Lat","depth")])
    
  stop("\nFix and re-run funciton.\n")
    
  }

  # min and maximum depth for transition object
  
  if(is.na(min.depth)){min.depth <- 0
  writeLines("\n No min.depth specified, defaulting to 0 m depth.\n")
  }
  
  if(is.na(max.depth)){max.depth <- NULL
  writeLines("\n No max.depth specified, defaulting to maximum depth of bathymetry object from marmap.\n")
  }
  
  #Make the trans mat object then do the lc dist calculation
  
  if(is.na(trans)){
  writeLines("\nCalculating transition object for least-cost analysis.\n")
  trans <- marmap::trans.mat(bathydata,min.depth = min.depth,max.depth = max.depth) 
  }
  
  sites<-coords[,c("Long","Lat")]
  rownames(sites)<-coords[,1]
  
  writeLines("\nCalculating least cost distances. This will probably can take a few minutes depending on resolution. If insufficient memory error is returned try adjusting the gridres argument (default = 2) to a higher number. gridres refers to the resolution of the bathymetric grid in minutes.\n")
  lc.dists <- marmap::lc.dist(trans, 
                      sites, 
                      res="dist")
  writeLines("\nMeta MDS scaling into Cartesian coordinates\n")
  #Now the cartesian conversion using metaMDS
  set.seed(1)
  cart.dists <- as.data.frame(vegan::metaMDS(lc.dists,k=2)$points) #K=2 because we want 2 dimensions
  set.seed(1)
  stress.values <- vegan::metaMDS(lc.dists,k=2)$stress # this will vary slightly each time.
  dist.cart.dists <- dist(cart.dists)
  
  #stress warnings
  if(stress.values>0.05){writeLines(paste0("Potentially high stress (>0.05) value detected in metaMDS reprojection: ",round(stress.values,4)))}else{writeLines(paste0("metaMDS reprojection stress is good (<0.05) : ",round(stress.values,4)))}
  
  cartfit <- cbind(matrix(lc.dists)[,1],matrix(dist.cart.dists)[,1])
  cartfit <- data.frame(cartfit)
  colnames(cartfit) <- c("Deg","Cart")
  
  p1<-ggplot2::ggplot(cartfit[cartfit$Deg>0&cartfit$Cart>0,],aes(x=Deg,y=Cart))+
    geom_point()+
    geom_abline(slope=1,intercept=0,lty=2)+
    geom_smooth(method="lm",se = FALSE)+
    scale_x_log10()+
    scale_y_log10()+
    annotation_logticks(sides="bl")+
    theme_bw()+
    coord_fixed()+
    labs(x="Least cost geographic distance (km)",y="Projected cartesian distance (km)")
  
  writeLines("\nRelationship between the least-cost and projected distances. Note that the plot and slope/intercept estimates do exclude any zero distance estimates. Dashed line is the 1-1 fit and the blue line is the linear relationship between least-cost and projected distances.\n\n")
  print(p1)
  
  #linear model between the projected and least-cost distances. This reflects the blue line in p1
  mod <- lm(log10(Deg)~log10(Cart),data=cartfit[cartfit$Deg>0&cartfit$Cart>0,])

  #objects to be saved to workspace
  Coords <- cbind(coords,cart.dists) #Geographic and Cartesian coordinates
  fitplot <- p1 #fitted plot
  stress <- stress.values
  mod <- mod #fitted model
  trans <- trans #transition object
  lc.dist <- lc.dist #least cost distance matrix
  bathydata <- bathydata #bathymetric layer
  
  rm(list=setdiff(ls(), c("Coords","fitplot","stress","mod","trans","lc.dist","bathydata","outpath")))
  
  if(!is.na(outpath)){save.image(outpath)}else{save.image(paste0("Output-", format(Sys.time(), "%Y_%m_%d_%H_%M_%S"),".RData"))}
  
}