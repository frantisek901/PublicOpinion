turtles-own [opinion eps opinion-list extremist?]
;; eps is the bound of confidence, opinion-list is to hold the list of the last max-pxcor opinions, extremist? checks if the turtle is in an opinion interval of extremism
globals [ current_min_eps current_max_eps current_alpha current_beta]
;; variables to display the parameters of the beta distribution from which the current eps-values are drawn
;; the slider-variables min_eps, max_eps, alpha, beta are changed to current_... when new_confidence_bounds is called

;; BUTTON PROCEDURES

to setup
  clear-all
  ask patches [set pcolor white]
  create-turtles number_of_agents
  ask turtles [
    set opinion new-opinion 
    set opinion-list (list opinion)
    setxy 0 (opinion * max-pycor) 
    ]
  new_confidence_bounds ;; see procedure
  reset-ticks
end

to go
  ask turtles [ set opinion-list lput opinion opinion-list ] ;; put opinion after opinion-list to use it as "old" value for simulatanous update in HK
  ifelse (communication_regime = "DW (select one)") and (original = true) 
    [repeat count turtles [ask one-of turtles [ update-opinion ]]] ;; in original DW we chose N random pairs each tick
    [ask turtles [ update-opinion ]] ;; in all other versions there is an update for each agent every tick
    ;; for "update-opinion" see the procedure
  ask turtles [ set opinion-list replace-item ( length opinion-list - 1) opinion-list opinion ] ;; update the opinion-list
  ask turtles [ if (length opinion-list = max-pxcor + 1) [ set opinion-list butfirst opinion-list ] ] ;; cut oldest values for "rolling" opinion list
  ask turtles [ entry-exit ] ;; see the procedure
  draw-trajectories  ;; see the procedure
  tick
end

to new_confidence_bounds
  set current_min_eps min_eps
  set current_max_eps max_eps
  set current_alpha alpha
  set current_beta beta
  ask turtles [
    let x random-gamma alpha 1
    set eps ( x / ( x + random-gamma beta 1) ) ;; set eps a random number from distribution Beta(alpha,beta) (between 0 and 1)
    set eps min_eps + (eps * (max_eps - min_eps)) ;; scale and shift eps to lie between min_eps and max_eps
    set color colorcode eps 0.5 ;; see reporter colorcode
    ] 
  update-plots
end

;; INTERNAL PROCEDURES

to update-opinion
  ;; detect if in extremism zone
  if (extremism_type = "two side") [set extremist? (0.5 - abs(opinion - 0.5) < extremism_range)]
  if (extremism_type = "one side") [set extremist? (opinion < extremism_range)]
  ;; change of opinion
  if (communication_regime = "DW (select one)") [
   ;; adjust opinion with random partner
   let partner one-of turtles
   if (abs (opinion - [opinion] of partner) < eps ) and (not extremist?) [
     set opinion (opinion + [opinion] of partner) / 2 
     if (original = true) [ ;; also partner updates opinion, this increases number of average activities of agents per time step from 1 to 2
       ask partner [
         if (extremism_type = "two side") [set extremist? (0.5 - abs(opinion - 0.5) < extremism_range)]
         if (extremism_type = "one side") [set extremist? (opinion < extremism_range)]         
         if (abs (opinion - [opinion] of myself) < eps ) and (not extremist?) [set opinion (opinion + [opinion] of myself) / 2] 
         ]
       ]
     ]
   ]
  if (communication_regime = "HK (select all)") [
   ;; adjust opinion to mean of all in agents closer than eps
   if not extremist? [
     ifelse (original = true) 
        [ set opinion aggregate ( filter [abs( ? - last opinion-list) < eps] [last opinion-list] of turtles ) ]
        [ set opinion aggregate ( filter [abs( ? - opinion) < eps] [opinion] of turtles ) ]
        ;; for aggregate see the reporter 
        ]
  ]
end

to entry-exit
  ;; randomly reset opinion with probability entry_exit_rate
  if (random-float 1 < entry_exit_rate) [set opinion new-opinion]
end

to draw-trajectories
  ;; let turtles move with their opinion trajectories from left to right across the world drawing trajectories or coloring patches
  clear-drawing
  ask turtles [
    pen-up
    setxy 0 (item 0 opinion-list * max-pycor)
  ]
  ifelse (visualization = "Colored histogram over time") [ ask turtles [ pen-up ] ] [ask turtles [ pen-down ] ]
  let t-counter 1
  while [ t-counter < (length ( [opinion-list] of turtle 1 )) ] [ 
    ask turtles [setxy t-counter (item t-counter opinion-list * max-pycor)]
    ifelse (visualization = "Colored histogram over time") 
      [ ask patches with [pxcor = t-counter ] [ set pcolor colorcode ((count turtles-here) / number_of_agents) 0.2 ] ] ;; see reporter colorcode
      [ ask patches [ set pcolor white ] ]
    set t-counter t-counter + 1 
  ]
end

;; REPORTERS

to-report new-opinion
  report random-float 1
end

to-report aggregate [opinions]
   if (aggregation_in_HK = "mean") [report mean opinions]
   if (aggregation_in_HK = "median") [report median opinions]
end

to-report colorcode [x max_x]
  ;; report a color as "x=0 --> violet", "x=max_x --> red" on the color axis violet,blue,cyan,green,yellow,orange,red 
  report hsb (190 - 190 * (x / max_x)) 255 255
end

;; Copyright 2012 Jan Lorenz
;; See Info tab for full copyright and license
@#$#@#$#@
GRAPHICS-WINDOW
276
10
698
300
-1
-1
3.41
1
10
1
1
1
0
0
0
1
0
120
0
75
1
1
1
ticks
30.0

BUTTON
71
28
163
61
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
168
28
267
61
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
91
266
124
number_of_agents
number_of_agents
0
1000
200
1
1
NIL
HORIZONTAL

SWITCH
170
149
265
182
original
original
1
1
-1000

CHOOSER
15
149
167
194
communication_regime
communication_regime
"HK (select all)" "DW (select one)"
0

CHOOSER
15
196
167
241
aggregation_in_HK
aggregation_in_HK
"mean" "median"
0

PLOT
14
377
203
513
Histogram eps
eps
NIL
0.0
1.0
0.0
30.0
false
false
"" "set-plot-y-range 0 round(number_of_agents / 8)"
PENS
"default" 0.02 1 -16777216 true "" "histogram [eps] of turtles"

SLIDER
422
324
591
357
min_eps
min_eps
0
1
0
0.01
1
NIL
HORIZONTAL

SLIDER
422
360
590
393
max_eps
max_eps
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
422
396
590
429
alpha
alpha
0.01
6
2
0.01
1
NIL
HORIZONTAL

BUTTON
227
332
409
365
NIL
new_confidence_bounds
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
13
310
412
328
3. Setting Confidence Bounds: eps ~ Beta(alpha,beta,min,max)
12
0.0
1

MONITOR
16
28
66
73
N
count turtles
17
1
11

MONITOR
14
328
64
373
min
current_min_eps
17
1
11

MONITOR
67
328
117
373
max
current_max_eps
17
1
11

MONITOR
120
328
170
373
alpha
current_alpha
17
1
11

MONITOR
173
328
223
373
beta
current_beta
17
1
11

PLOT
208
377
410
513
pdf beta-distribution
eps
NIL
0.0
1.0
0.0
0.0
true
false
"" "clear-plot"
PENS
"default" 1.0 0 -5825686 true "" "if (max_eps > min_eps) [\nplotxy min_eps 0\nforeach ( n-values 99 [ (? + 1) / 100 * (max_eps - min_eps) + min_eps] ) [plotxy ? ( ((? - min_eps) ^ (alpha - 1) * (max_eps - ?) ^ (beta - 1)) / ( max_eps - min_eps ) ^ (alpha + beta - 1) )]\nplotxy max_eps 0\n]"

TEXTBOX
16
10
166
28
Setup and Go
12
0.0
1

SLIDER
610
423
767
456
extremism_range
extremism_range
0
0.5
0
0.01
1
NIL
HORIZONTAL

CHOOSER
702
10
909
55
visualization
visualization
"Colored histogram over time" "Agents' trajectories"
0

CHOOSER
770
423
875
468
extremism_type
extremism_type
"one side" "two side"
1

PLOT
702
58
909
178
Histogram
Current Opinion
NIL
0.0
1.0
0.0
0.0
true
false
"" "set-plot-y-range 0 round(number_of_agents / 8)"
PENS
"default" 0.02 1 -13345367 true "" "histogram [opinion] of turtles"

TEXTBOX
15
131
259
149
1. Communication and Opinion Update
12
0.0
1

MONITOR
435
467
503
512
eps mean
(alpha * max_eps + beta * min_eps) / (alpha + beta)
3
1
11

MONITOR
505
467
571
512
eps mode
ifelse-value ((alpha > 1) and (beta > 1)) [((alpha - 1) * max_eps + (beta - 1) * min_eps ) / (alpha + beta - 2)]  [\"\"]
3
1
11

PLOT
702
180
909
300
Opinion
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"mean" 1.0 0 -16777216 true "" "plot mean [opinion] of turtles"
"median" 1.0 0 -2674135 true "" "plot median [opinion] of turtles"

SLIDER
423
432
590
465
beta
beta
0.01
6
4
0.01
1
NIL
HORIZONTAL

TEXTBOX
71
63
263
90
Hint: number_of_agents-Slider (without running \"Setup\") changes coloraxis.
9
0.0
1

TEXTBOX
186
186
277
213
\"Original\" has marginal effect.
9
0.0
1

TEXTBOX
170
216
239
239
Only effective in HK!
9
0.0
1

TEXTBOX
424
311
591
329
Parameters for beta-distribution
9
0.0
1

TEXTBOX
614
407
764
425
4. Introduce extremists
12
0.0
1

TEXTBOX
610
459
760
483
Every agent in extremism zone never changes opinion. 
9
0.0
1

TEXTBOX
610
485
875
509
Extremism zones: [0,extremism_range] \nand [1-extremism_range,1] under \"two sided\"
9
0.0
1

TEXTBOX
751
389
780
407
violet
9
115.0
1

TEXTBOX
753
379
778
397
blue
9
105.0
1

TEXTBOX
751
368
780
386
cyan
9
85.0
1

TEXTBOX
749
357
778
375
green
9
55.0
1

TEXTBOX
748
348
781
366
yellow
9
45.0
1

TEXTBOX
746
338
782
356
orange
9
25.0
1

TEXTBOX
752
328
769
346
red
9
15.0
1

TEXTBOX
654
316
749
334
colored histogram
9
0.0
1

TEXTBOX
616
329
739
347
>20% number_of_agents 
9
0.0
1

TEXTBOX
696
389
743
407
0 agents
9
0.0
1

TEXTBOX
662
352
742
376
Fraction of agents in patch
9
0.0
1

TEXTBOX
791
328
848
347
eps >= 0.5
9
0.0
1

TEXTBOX
791
389
829
408
eps=0
9
0.0
1

TEXTBOX
771
315
864
333
eps in trajectories
9
0.0
1

TEXTBOX
712
302
831
332
Info: Color axis
12
0.0
1

TEXTBOX
791
358
839
376
eps=0.25
9
0.0
1

SLIDER
15
263
187
296
entry_exit_rate
entry_exit_rate
0
1
0.02
0.01
1
NIL
HORIZONTAL

TEXTBOX
15
245
260
263
2. Probability of random opinion reset
12
0.0
1

@#$#@#$#@
# Continuous Opinion Dynamics under Bounded Confidence 

## WHAT IS IT?

A model of **continuous opinion dynamics under bounded confidence**, which includes 

  * its two main variants of communication regimes (as in [Deffuant et al 2000](http://dx.doi.org/10.1142/S0219525900000078) with &mu;=0.5 and as in  [Hegselmann and Krause 2002](http://jasss.soc.surrey.ac.uk/5/3/2.html))
  * alternative aggregation of opinions by the median instead of the mean
  * heterogeneous bounds of confidence coming from a four parameter [beta distribution](http://en.wikipedia.org/wiki/Beta_distribution)
  * noise via random reset of opinions (as in [Pineda et al 2009](http://dx.doi.org/10.1088/1742-5468/2009/08/P08001))
  * one-sided and two-sided extremism (similar to [Deffuant et al 2002](http://jasss.soc.surrey.ac.uk/5/4/1.html))

Visualizations:

  * a rolling colored histogram of opinion density over time
  * rolling trajectories of opinions over time colored by the bound of confidence 
  * a bar plot histogram of current opinions 
  * trajectories of the mean and the median opinion over time.  


## HOW IT WORKS

### In a nutshell

Agents adjust their opinion gradually towards the opinions of others when the distance in opinion is within their bound of confidence. Sometimes agents change their opinion to a new one at random. When agents hold extremal opinions they might get extremists which never adjust opinions. 

### Variables

Each of N agent has its **opinion** between 0.0 and 1.0 as a dynamic variable and its **bound of confidence** (eps) as a static variable. Other static variables are global and regard the type of communication and aggregation, the probability of random reset of opinion and the type and size of extremism zones. 

### Setup

Each agent is assigned its initial opinion as a random number between 0.0 and 1.0 from the uniform distribution. Each agent is assigned its bound of confidence as a random number form a [beta-distribution](http://en.wikipedia.org/wiki/Beta_distribution) between min_eps and max_eps. 

### Dynamics

Each tick agents are asked to adjust their opinions with respect to the opinions of others and their bound of confidence (eps).

**1. Communication and aggregation:**

  * "DW (select one)": Each tick each agent is asked to select a random partner and changes its opinion to the average of the two opinions but only when the opinion of the partner is closer than eps to the own opinion.
When original=On, N randomly selected agents are chosen each tick (so some agents possibly more than once) and both agents (the selected one and the randomly selected partner) both adjust opinions. (This is the version of Deffuant et al 2000, differences to original=Off are mostly minor.)
  * "HK (select all)": Each tick each agent is asked to change its opinion to the aggregated opinion of all opinions which are closer than eps to its opinion. The aggregate opinion can be the mean or the median. When original=On is checked all agents do the change simultaneously. (This is the version of Hegselmann and Krause 2002, differences are minor.)  With original=Off an agent's change of opinion can immediately takes place and the new opinion might already effect the adjustments of the next agent even in the same tick. 

**2. Probability of random opinion reset**

After the update of opinion each agent is asked to select a new opinion (in the same way as its initialization) but only with probability given by the variable entry_exit_rate. 

**3. Heterogeneous bounds of confidence**

Notice that under heterogeneous bounds of confidence it might be that one agent has confidence in another but not vice versa! 

**4. Extremists**

Extremism zones are intervals in the opinion space from 0.0 to 1.0 which are determined by the parameter extremism_range. The extremism intervals are from 0.0 to extremism_range for the selection "one side" and additionally from 1.0-extremism_range to 1.0 for the selection "two side". Agents which are located in the extermism zone never change their opinion. But still other non-extremist agents might adjust their opinion with respect to the opinions of extremists. Extremists still undergo change of opinion due to random reset of opinions. 

## HOW TO USE IT

Click "setup" to inititialize agents with opinions random and uniformly distributed between 0.0 and 1.0. Agents are located at the left border of the world with their opinions spreading over the vertical axis. Further, on confidence bounds are initialized for each agent as random draws from a beta distribution under the current choice of the four parameters. 

Click "go" to start the simulation. Agents move with ticks from left to right, displaying their opinion with the position on the vertical axis. This goes over into a "rolling" graphic in the world, where the last 120 ticks are shown (respectively the last max-pxcor ticks). Visualization can be chosen as trajectories of agents or as color-coded histograms. In colored histograms each patch's color is associated to the number of agents at this patch. 

A change of the variables communication regime, original, aggregation_in_HK, entry_exit_rate, extremism_range, and extremism_type is immediately effective in a running simulation. 

A change of the variable number_of_agents immediately changes the color axis in the "Colored histogram over time"-visualization and the vertical axis in the histogram of current opinions.

A change of the four parameters of the distribution of eps (min_eps, max_esp, alpha, beta) immediately effect only the plot of the pdf of the distribution, but not the eps in the running simulation (click "new_confidence_bounds" for this).  

Click "new_confidence_bounds" to make new random draws for eps for each agent. Draws come from the beta distribution with the current parameters. (The same procedure is called when clicking "setup".)


## THINGS TO NOTICE

Agents move towards the right-hand side of the world with one step each tick. This goes over into a "rolling" plot. 

Notice how agents form **clusters** in the opinion space. See how these clusters **evolve**, **drift** and **unite** in the "**Colored histograms over time**"-visualization. 

Look at the role of agents with different bounds of confidence in the "**Agents' trajectories**"-visualization. 

Look at the current distribution of opinions in the **bar plot histogram** on the right hand side and compare it to the colored histogram (the most recent colored vertical line in the world at the right hand side).

Look how the **mean and the median opinion** evolve over time. The mean represents the center of mass of the distribution (cf. the current histogram). The median represents an unbeatable opinion under pairwise majority decisions. (This holds when agents have single-peaked preferences with peaks at their opinion, cf. [median voter theorem](http://en.wikipedia.org/wiki/Median_voter_theorem)).

Look how the histogram of bounds of confidence matches the probability density function of the beta distribution when you click "new_confidence_bounds". 


## THINGS TO TRY

Try the **original models of homogeneous DW and HK communication without noise**: Set entry_exit_rate to zero, min_eps and max_eps to the same value, and extremism_range to zero. See how a stable configuration of clusters evolves. Check how the **number**, **sizes** and **locations** of clusters depend on the bound of confidence. Try to determine critical bounds of confidence where the evolving cluster pattern changes significantly. Use the setup button to rerun with a new initial configuration. 

Try to understand the impact of **noise** (entry_exit_rate) under homogeneous bounds of confidence: Set up a homogeneous eps (min_eps=max_eps), run the simulation and play with the entry_exit_rate slider (reasonable values are low, e.g. between 0.01 and 0.1). There are bounds of confidence, where the cluster pattern oscillates between two numbers of clusters. Under different entry_exit_rates the two patterns become differently likely. 

Play with **hetergeneous bounds of confidence** (min_eps<max_eps) without noise (entry_exit_rate=0). Try different shapes of the distribution by manipulation of alpha and beta. Try to understand the **drifting** phenomena under the two communication regimes. Try to reproduce the phenomenon of "**more chance for consensus under lower but heterogeneous bounds of confidence**" (see [Lorenz 2010](http://dx.doi.org/10.1002/cplx.20295)): Set N=500, DW communication, original=off, entry_exit_rate=extremism_range=0, alpha=beta=0.1, min_eps=0.24, max_eps=0.24. See by several runs (repeatedly click "setup") that consensus is not (or very rarely) possible. Now set min_eps=0.1 and see that the bimodal distribution (half of the population with eps=0.1 and half with eps=0.24) makes it possible that almost all agents unite in a single cluster. Beware, this does not happen all the time and might takes a lot of time (rerun and wait!). The phenomenon is better understood in the "Agents' trajectories"-visualization. 

Play with **extremism** under homogeneous bounds of confidence and no noise (entry_exit_rate=0). Observe the pattern of convergence under different bounds of confidence. Under what bounds of confidence does global extremism (at one or both extremes) occur? Use small extremism ranges (between 0.01 and 0.05) and play with one or two-sided extremism. Compare to [Deffuant et al 2002](http://jasss.soc.surrey.ac.uk/5/4/1.html).

Try to find differences between the original versions of the DW and HK models and the one implemented when original=off. 

Try to calibrate parameters which represent an evolution of the political landscape of opinions which looks to you as a realistic evolution of a party system (regarding location and size of opinion clusters in the left--right continuum). 


## RELATED MODELS AND PAPERS

**Original HK and DW models**
Hegselmann, R. & Krause, U. [Opinion Dynamics and Bounded Confidence, Models, Analysis and Simulation](http://jasss.soc.surrey.ac.uk/5/3/2.html) Journal of Artificial Societies and Social Simulation, 2002, 5, 2
Deffuant, G.; Neau, D.; Amblard, F. & Weisbuch, G. [Mixing Beliefs among Interacting Agents](http://dx.doi.org/10.1142/S0219525900000078) Advances in Complex Systems, 2000, 3, 87-98
Weisbuch, G.; Deffuant, G.; Amblard, F. & Nadal, J.-P. [Meet, discuss, and segregate!](http://dx.doi.org/10.1002/cplx.10031) Complexity, 2002, 7, 55-63

**General model including HK and DW**
Urbig, D.; Lorenz, J. & Herzberg, H. [Opinion dynamics: The effect of the number of peers met at once](http://jasss.soc.surrey.ac.uk/11/2/4.html) Journal of Artificial Societies and Social Simulation, 2008, 11, 4

**On noise:** 
Pineda, M.; Toral, R. & Hernandez-Garcia, E. [Noisy continuous-opinion dynamics](http://stacks.iop.org/1742-5468/2009/P08001) Journal of Statistical Mechanics: Theory and Experiment, 2009, 2009, P08001 (18pp)
Mäs, M.; Flache, A. & Helbing, D. [Individualization as Driving Force of Clustering Phenomena in Humans](http://dx.doi.org/10.1371/journal.pcbi.1000959) PLoS Comput Biol, Public Library of Science, 2010, 6, e1000959

**On heterogeneous bounds of confidence**
Lorenz, J. [Heterogeneous bounds of confidence: Meet, Discuss and Find Consensus!](http://dx.doi.org/10.1002/cplx.20295) Complexity, 2010, 15, 43-52

**On extremism**
Deffuant, G.; Neau, D.; Amblard, F. & Weisbuch, G. [How Can Extremism Prevail? A Study Based on the Relative Agreement Interaction Model](http://jasss.soc.surrey.ac.uk/5/5/1.html) Journal of Artificial Societies and Social Simulation, 2002, 5, 1
Deffuant, G. [Comparing Extremism Propagation Patterns in Continuous Opinion Models](http://jasss.soc.surrey.ac.uk/9/3/8.html) Journal of Artificial Societies and Social Simulation, 2006, 9, 8

**Survey, Motivation and Variation**
Lorenz, J. [Continuous Opinion Dynamics under bounded confidence: A Survey](http://dx.doi.org/10.1142/S0129183107011789) Int. Journal of Modern Physics C, 2007, 18, 1819-1838
Urbig, D. [Attitude Dynamics with Limited Verbalisation Capabilities](http://www.jasss.surrey.ac.uk/6/1/2.html) Journal of Artificial Societies and Social Simulation, 2003, 6, 2
Lorenz, J. & Urbig, D. [About the Power to Enforce and Prevent Consensus by Manipulating Communication Rules](http://dx.doi.org/10.1142/S0219525907000982) Advances in Complex Systems, 2007, 10, 251
Amblard, F. & Deffuant, G. [The role of network topology on extremism propagation with the relative agreement opinion dynamics](http://dx.doi.org/10.1016/j.physa.2004.06.102) Physica A: Statistical Mechanics and its Applications, 2004, 343, 725-738 
Groeber, P.; Schweitzer, F. & Press, K. [How Groups Can Foster Consensus: The Case of Local Cultures](http://jasss.soc.surrey.ac.uk/12/2/4.html) Journal of Artificial Societies and Social Simulation, 2009, 12, 4




## CREDITS AND REFERENCES

Copyright 2012 Jan Lorenz. http://janlo.de, post@janlo.de

![Creative Commons Attribution-ShareAlike 3.0 Unported License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png)
 
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ .
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
