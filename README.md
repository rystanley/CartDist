# CartDist
Code to re-project marine least-cost distances into Cartesian coordinates.

[![DOI](https://zenodo.org/badge/93073704.svg)](https://zenodo.org/badge/latestdoi/93073704)


![](vignettes/CartesianWorkflow.jpg)

Example workflow 1) assemble coordinates in native geographic coordination, 2) calculate least-cost path accounting for land as barrier, 3) calculate 2 dimensional rescaling using metaMDS, 4) compare distances in 2 dimensional rescaling with least-cost distances.


***
**Requirement:**
CartDist requires the installation and availability of the following packages

* CartDist requires the installation and availability of the following packages:
* extracting meta-data:
    * gdistance
    * maps
    * mapdata
    * marmap
    * ggplot2
    * dplyr
    * data.table
    * vegan


***

## Contributions:
*imExtractor* coded by Ryan Stanley <https://github.com/rystanley> 

* If you don’t understand something, please let me know: 
(ryan.stanley _at_ dfo-mpo.gc.ca). 
* Any ideas on how to improve the functionality are very much appreciated. 
* If you spot a typo, feel free to edit and send a pull request.

Pull request how-to: 

  * Click the edit this page on the sidebar.
  * Make the changes using github’s in-page editor and save.
  * Submit a pull request and include a brief description of your changes. (e.g. "_spelling errors_" or "_indexing error_").
  
***

# **Citation** 

A Zenodo DOI is also avaiable for the most recent release of **CartDist**:

[![DOI](https://zenodo.org/badge/93073704.svg)](https://zenodo.org/badge/latestdoi/93073704)


Stanley, R.R.E and N.W. Jeffery 2017. CartDist: Re-projection tool for complex marine systems. DOI 10.5281/zenodo.802875


***
# **Installation**

*CartDist* can be sourced into the workspace by cloning this [Github directory](github.com/rystanley/CartDist) or by sourcing directly using the web url.

<a name="installation"/>

```r
library(RCurl) # if you do not have the package rcurl installed please load from CRAN.
library(EBImage) # see installation instructions for the EBImage package.

#links for the 'raw' code
Weblink <- c("https://raw.githubusercontent.com/rystanley/CartDist/master/CartDistFunction.R")

#source the 'raw' code links into the local environment
  script <- getURL(Weblink, ssl.verifypeer = FALSE)
  eval(parse(text = script),envir=.GlobalEnv)
  rm(script)  

```