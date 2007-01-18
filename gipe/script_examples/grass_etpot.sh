# Example script to process ETPOT
# Using individual modules as processing steps
# using tif.gz downloaded files
# of Landsat 7 ETM+ from GLCF website for example
# LGPL, Yann Chemin ychemin_AT_gmail.com
#!/bin/bash

# This script is supposed to simplify the process of calculating ETPOT from Landsat images downloaded from the web.

# Change This according to the file name and calculate DOY from date!
base=p127r050
date=20001104
doy=311.0

# From here and onward dont change anything!
#-------------------------------------------
fmet=_7x
ftemp=_7k
fpan=_7p
fvnir=_7t
ext=_z48_nn

tsw=0.7

inpmetF=$base$fmet$date.met
inplandsat1F=$base$date.1
inplandsat2F=$base$date.2
inplandsat3F=$base$date.3
inplandsat4F=$base$date.4
inplandsat5F=$base$date.5
inplandsat61F=$base$date.61
inplandsat62F=$base$date.62
inplandsat7F=$base$date.7
inplandsat8F=$base$date.8

#unzip the .gz
for file in *.gz; do gzip -d $file ; done

# Import files in GRASS GIS
# Warning: This is setting the processing resolution at 30x30m!
for file in *nn10.tif
do
	r.in.gdal input=$file output=$file location=landsat
done

g.mapset location=landsat mapset=PERMANENT

# Continue to import files in GRASS GIS
for file in *nn20.tif *nn30.tif *nn40.tif *nn50.tif *nn61.tif *nn62.tif *nn70.tif \
 *nn80.tif ; do r.in.gdal input=$file output=$file ; done

#calibrate DN to TOA Reflectance
r.dn2full.l7 metfile=$inpmetF output=$base$date --overwrite

#Calculate Albedo
r.albedo -l input=$inplandsat1F,$inplandsat2F,$inplandsat3F,$inplandsat4F,$inplandsat5F,$inplandsat7F output=$base$date\albedo --overwrite
r.null map=$base$date\albedo setnull=0.0

#Calculate Latitude
r.latitude input=$base$date\albedo latitude=$base$date\latitude --overwrite

#Create a doy layer
r.mapcalc $base$date\doy=$doy
r.mapcalc $base$date\tsw=$tsw

#Calculate ETPOT (and Rnetd for future ETa calculations)
r.evapo.potrad -r albedo=$base$date\albedo tempk=$base$date\.61 lat=$base$date\latitude doy=$base$date\doy tsw=$base$date\tsw etpot=$base$date\etpot rnetd=$base$date\rnetd --overwrite
r.colors map=$base$date\etpot color=grey

#Calculate NDVI 
r.vi viname=ndvi red=$inplandsat3F nir=$inplandsat4F vi=$base$date\ndvi --overwrite

#clean maps
r.null map=$base$date\ndvi setnull=-1.0
r.colors map=$base$date\ndvi rules=ndvi
