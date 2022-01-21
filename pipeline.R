#### Script for Project Group '#public-opinion-project' from SFI-CI Winter 2022
##
##   This script handles getting data from NetLogo model,
##   now named: public_opinion_V01.nlogo
##   into R and storing them t/here for further network analyses.
##
##   NOTES:
##   A) Current idea of data structure is following:
##   Keep all needed information as the data files:
##   1) multi-layer weighted network data, where opinion distance is one layer and different types of relationships are other layers
##   2) dataframe/tibble with agents' traits and variables
##   This leads to flexible, but stil lightweight datastructure allowing us in case of need store info on every tick of simmulation.
##

## Encoding: windows-1250
## Last edit: 2022-01-21 Fran»esko
##


## Head:
# Clear all
rm(list = ls())

# Packages
library(nlrx)
library(dplyr)
library(tibble)



# Controling NetLogo from R: The first tries ------------------------------










