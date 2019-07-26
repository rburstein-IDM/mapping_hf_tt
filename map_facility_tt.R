## ##################################################################################
## Roy Burstein
## rbrustein@idmod.org
## 26 July 2019
## Purpose: pull in open data on health facility locations and D Weiss friction surface
##          to make a contintental map of travel time to public health facilities.
## ##################################################################################

## basic setup

# choose a country (or vector of countries to map)
cntrys <- c('Ethiopia')

# load needed packages
libs <- c('raster', 'gdistance', 'data.table', 'readxl')
for(l in libs) require(l, character.only = TRUE)

# set your working directory, make sure all data are in there
setwd('C:/Users/rburstein/Dropbox (IDM)/africa_hf_tt')

## load datasets

# location of public facilities health facilities
# paper: https://www.nature.com/articles/s41597-019-0142-2
# data: https://springernature.figshare.com/ndownloader/files/14379593
hf <- as.data.table(read_excel('00 SSA MFL (130219).xlsx'))

# load in gloabl shapefile, subset it to the country youare interested in
# it could be mutliple countries, but beware the the transistion() step is RAM intensive
# https://www.naturalearthdata.com/downloads/50m-cultural-vectors/50m-admin-0-countries-2/
shp <- shapefile('ne_50m_admin_0_countries')
shp <- subset(shp, ADMIN %in% cntrys)


# friction map and subset it to africa
# info on project: https://map.ox.ac.uk/research-project/accessibility_to_cities/
fric <- raster('2015_friction_surface_v1.geotiff')
fric <- crop(fric, shp)
fric <- mask(fric, shp)

## make the travel time surface
# Code below modified from code provided at: https://map.ox.ac.uk/research-project/accessibility_to_cities/

# get coordinates
xy    <- na.omit(hf[Country %in% cntrys, c('Long', 'Lat'), with = FALSE])
if(nrow(xy)==0) stop('Oops! There dont appear to be any health facilities left!')

# Make the graph and the geocorrected version of the graph (or read in the latter).
Tr   <- transition(fric, function(x) 1/mean(x), 8) 
T.GC <- geoCorrection(Tr)                    

# Run the accumulated cost algorithm to make the final output map. This can be quite slow (potentially hours).
tt <- accCost(T.GC, xy)


# save the travel time surface
writeRaster(tt, sprintf('public_hf_tt_surface_%s.tif', paste0(cntrys, collapse = '_')))


## Make some nice plots
plot(tt,col = c('#2E1510','#3E1D1D','#4D262D','#593140','#623E54','#664D69',
                '#655E7D','#5F708F','#54829E','#4594A8','#39A6AC','#38B7AB',
                '#49C7A5','#66D79B','#8AE48E','#B1F081','#DCFA76'))
points(xy,col='yellow',cex=.01)





# Write the resulting raster
tp <- mask(tt,zmb)
writeRaster(tp, 'C:/Users/royburst/Google Drive/friction_surface/zmb_tt_masked.tif')

# plot it nicelike
