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

## Creation of `nl` object:

# Windows default NetLogo installation path (adjust to your needs!):
netlogopath = "c:/Program Files/NetLogo 6.2.2/"
## QUESTION to more experienced:
#  Does anyone know the way how to find the path to our own NetLogo instalations without setting it manually?
#  I am afraid that this manual setting forces many people avoid good things -- many ncluding me...

modelpath = "public_opinion_v01.nlogo"

outpath = "/OutputData"

nl = nl(nlversion = "6.2.2",
        nlpath = netlogopath,
        modelpath = modelpath,
        jvmmem = 1024)


## Attaching an experiment:
nl@experiment  = experiment(expname="firstTry",
                            outpath=outpath,
                            repetition=1,
                            tickmetrics="true",
                            idsetup="setup",
                            idgo="go",
                            runtime=50,
                            evalticks=seq(0, 50, 25),
                            metrics=c("count turtles", "count turtles with [opinion < 50]", "count links"),
                            variables = list('number-of-agents' = list(min=20, max=100, qfun="qunif"),
                                             'agent-tolerance' = list(min=10, max=90, qfun="qunif")),
                            constants = list("transparency" = 255))


## Attaching a simulation design:
nl@simdesign =  simdesign_lhs(nl=nl,
                              samples=10,
                              nseeds=3,
                              precision=0)


## Running simulations:
a = Sys.time()
results = run_nl_all(nl = nl)
Sys.time() - a
results










