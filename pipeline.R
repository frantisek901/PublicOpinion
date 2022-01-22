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
## Last edit: 2022-01-22 Fran»esko
##


## Head:
# Clear all
rm(list = ls())

# Packages
library(nlrx)
library(RNetLogo)
library(dplyr)
library(tibble)
library(ggplot2)



# Controling NetLogo from R: The first tries with nlrx ------------------------------

## Creation of `nl` object:

# Windows default NetLogo installation path (adjust to your needs!):
netlogopath = "c:/Program Files/NetLogo 6.2.2/"
## QUESTION to more experienced:
#  Does anyone know the way how to find the path to our own NetLogo instalations without setting it manually?
#  I am afraid that this manual setting forces many people avoid good things -- many ncluding me...

modelpath = "public_opinion_v01.nlogo"

outpath = paste0(getwd(),"/OutputData")

nl = nl(nlversion = "6.2.2",
        nlpath = netlogopath,
        modelpath = modelpath,
        jvmmem = 2048)


## Attaching an experiment:
nl@experiment = experiment(expname="firstTry",
                            outpath=outpath,
                            repetition=1,
                            tickmetrics="true",
                            idsetup="setup",
                            idgo="go",
                            runtime=50,
                            evalticks=0:50,
                            metrics = c("count turtles", "count turtles with [opinion < 50]", "count links"),
                            metrics.turtles = list("turtles" = c("who", "opinion", "tolerance", "num-family-ties", "num-coworker-ties", "num-friend-ties")),
                            metrics.links = list(
                              "family" = c("[who] of end1", "[who] of end2", "weight"),
                              "coworkers" = c("[who] of end1", "[who] of end2", "weight"),
                              "friends" = c("[who] of end1", "[who] of end2", "weight")),
                            variables = list('number-of-agents' = list(min=20, max=100, step = 40),
                                             'agent-tolerance' = list(min=10, max=90, step = 40)),
                            constants = list("transparency" = 255))


## Attaching a simulation design:
nl@simdesign = simdesign_ff(nl=nl, nseeds=3)


## Running a single simulation:
a = Sys.time()
results = run_nl_one(nl = nl, seed = getsim(nl, "simseeds")[1], siminputrow = 3)
Sys.time() - a


## Running an experiment:
a = Sys.time()
results = run_nl_all(nl = nl)
Sys.time() - a
results


## Attaching results to `nl` object:
setsim(nl, "simoutput") = results
write_simoutput(nl)  # Writing output to the output folder.
analyze_nl(nl)  # Further analysis.
eval_simoutput(nl)  # Kinda evaluation.


## Something with network...
nl.graph = nl_to_graph(nl)

# Tick 0
nl.graph.0 = nl.graph$spatial.links[[1]]
V(nl.graph.0)
E(nl.graph.0)
plot.igraph(nl.graph.0, vertex.size=8, vertex.label=NA, edge.arrow.size=0.2)

# Tick 250
nl.graph.250 = nl.graph$spatial.links[[2]]
V(nl.graph.250)
E(nl.graph.250)
plot.igraph(nl.graph.250, vertex.size=8, vertex.label=NA, edge.arrow.size=0.2)

# Tick 500
nl.graph.500 = nl.graph$spatial.links[[3]]
V(nl.graph.500)
E(nl.graph.500)
plot.igraph(nl.graph.500, vertex.size=8, vertex.label=NA, edge.arrow.size=0.2)


## Let's draw some graph:
df = results %>% filter(`[step]` == 0) %>% select(7:9)
names(df) = c("Agents", "Negatives", "Links")

ggplot(df, aes(x = Agents, y = Negatives)) +
  geom_point() +
  theme_minimal()

ggplot(df, aes(x = Agents, y = Links)) +
  geom_point() +
  theme_minimal()

