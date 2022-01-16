extensions [rnd]
; The rnd extension is only needed for some network generation which is only part of the robustness checks

turtles-own [opinion alpha_i rho_i theta_i lambda_i group clique credibility initial_opinion opinion-list focus?]
globals [draw? spinup_tick cum_fragmentation cum_diversity cum_bias file_open?]

;; BUTTON PROCEDURES

to setup
  clear-all
  ask patches [set pcolor white]
  create-new-turtles N
  if social_network [setup-network]
  change_focus
  set draw? true
  set spinup_tick 50
  reset-ticks
  update-plots
end

to create-new-turtles [num]
  let len ifelse-value (count turtles = 0) [1] [max [length opinion-list] of turtles] ; This is to adjust the opinion-list when turtles are created at run-time
  create-turtles num [
    set group random 2 ;; group is either 0 or 1
    set alpha_i random-beta alpha alpha_dispersion
    set rho_i random-beta rho rho_dispersion
    set theta_i random-beta theta theta_dispersion
    set lambda_i ifelse-value (lambda_dispersion = 0) [lambda] [random-gamma (lambda ^ 2 / lambda_dispersion ^ 2) (1 / (lambda_dispersion ^ 2 / lambda))]
    set opinion new_opinion
    set credibility random-float 1
    set initial_opinion opinion
    set opinion-list n-values len [opinion]
    setxy (len - 1) confine-opinion-scale-to-max-pycor opinion M
    set color 65 + group * 60
    set focus? false
  ]
end

to go
  if (count turtles = 0) [setup]
  if (count turtles < N) [create-new-turtles (N - count turtles)]
  if (count turtles > N) [ask n-of (count turtles - N) turtles [die]]
  ask turtles [ if (length opinion-list = max-pxcor + 1) [ set opinion-list butfirst opinion-list ] ] ;; cut oldest values for "rolling" opinion list
  repeat iterations_per_tick [ask turtles [ update_opinion ]]
  ask turtles [ set opinion-list lput opinion opinion-list ] ;; update the opinion-list
  update_outcome_measures
  if (ticks mod skip_ticks_draw = 0 and draw?) [draw_trajectories] ;; see the procedure
  tick
end

to change_focus
  ask turtles [set focus? false]
  ask one-of turtles [set focus? true]
end

;; INTERNAL PROCEDURES

to update_opinion
  ifelse ((random-float 1 < (ifelse-value (heterogeneity) [theta_i] [theta])) and theta_as != "weight on initial attitude") [
    if (theta_as = "idiosyncrasy probability") [set opinion new_opinion]
    if (theta_as = "back to inital attitude") [set opinion initial_opinion]
  ][
    let other_turtle one-of ifelse-value (social_network) [out-link-neighbors] [turtles]
    if (other_turtle != nobody) [
      let source_credibility ifelse-value (group = [group] of other_turtle) [1] [intergroup_credibility]
      let weight ifelse-value (theta_as = "weight on initial attitude") [ifelse-value (heterogeneity) [theta_i] [theta]] [0]
      let message [opinion] of other_turtle
      set opinion (1 - weight) * (opinion + opinion_change opinion source_credibility message) + weight * initial_opinion
    ]
   ]
end

to update_outcome_measures
  if (ticks = spinup_tick) [
    set cum_fragmentation fragmentation
    set cum_diversity standard-deviation [opinion] of turtles / M
    set cum_bias abs mean [opinion] of turtles / M
  ]
  if (ticks > spinup_tick) [
    set cum_fragmentation ((ticks - spinup_tick) * cum_fragmentation + fragmentation) / (ticks - spinup_tick + 1)
    set cum_diversity ((ticks - spinup_tick) * cum_diversity + (standard-deviation [opinion] of turtles / M)) /  (ticks - spinup_tick + 1)
    set cum_bias ((ticks - spinup_tick) * cum_bias + (abs mean [opinion] of turtles / M)) /  (ticks - spinup_tick + 1)
  ]
end

to setup-network
; follower network (directed)
  if (following > 0) [
    let who-list sort [who] of turtles
    foreach who-list [ x ->
    ask turtle  x [
      create-links-to rnd:weighted-n-of (min list following count turtles with [who < [who] of myself])
                           (turtles with [who < [who] of myself]) [1 + count in-link-neighbors]
  ]]]
  ; friends network (undirected / reciprocal)
  if friends_network = "random" [ ask turtles [
    ask turtles with [ who > [ who ] of myself ] [
      if random-float 1 < friends / N [
        create-link-to myself
        create-link-from myself
  ]]]]
  if friends_network = "ring" and friends >= 2 [ ask turtles [
    foreach (n-values (friends / 2) [i -> i + 1]) [ num ->
      create-link-to turtle ((who + num) mod count turtles)
      create-link-from turtle ((who + num) mod count turtles)
  ]]]
  if friends_network = "cliques" [
    ask turtles [ set clique random round (N / friends) ]
    ask turtles [ create-links-to other turtles with [clique = [clique] of myself] ]
  ]
  ask links [hide-link]
end

;; VISUALIZATION

to draw_trajectories
  ;; let turtles move with their opinion trajectories from left to right across the world drawing trajectories or coloring patches
  clear-drawing
  ask turtles [
    hide-turtle
    pen-up
    setxy 0 (confine-opinion-scale-to-max-pycor (item 0 opinion-list) M)
    if (visualization = "Agents' trajectories") [
      set color ifelse-value (intergroup_credibility = 1 and initial_groupspread = 0) [item (who mod length base-colors) base-colors] [65 + group * 60]
    ]
  ]
  let t-counter 0
  while [ t-counter < (length ( [opinion-list] of one-of turtles )) ] [
    ask turtles [ pen-up ]
    if (visualization = "Agents' trajectories") [ ask turtles [ pen-down ] ]
    foreach sort turtles [ [?1] -> ;; with foreach for drawing always in the same order
       ask ?1 [setxy t-counter (confine-opinion-scale-to-max-pycor (item t-counter opinion-list) M) ]
    ]
    ifelse (visualization = "Heatmap timeline")
      [ ask patches with [pxcor = t-counter ] [ set pcolor colorcode (count turtles-here / count turtles) color_axis_max ] ]
      [ ask patches [ set pcolor white ] ]
    set t-counter t-counter + 1
  ]
  if (focus) [
    ask turtles with [focus?] [
      pen-up
      setxy 0 (confine-opinion-scale-to-max-pycor (item 0 opinion-list) M)
      pen-down
      set pen-size 3
      set color white
      set t-counter 0
      while [ t-counter < (length ( [opinion-list] of one-of turtles )) ] [
        setxy t-counter (confine-opinion-scale-to-max-pycor (item t-counter opinion-list) M)
        set t-counter t-counter + 1
      ]
      pen-up
      setxy 0 (confine-opinion-scale-to-max-pycor (item 0 opinion-list) M)
      pen-down
      set pen-size 1
      set color 65 + group * 60
      set t-counter 0
      while [ t-counter < (length ( [opinion-list] of one-of turtles )) ] [
        setxy t-counter (confine-opinion-scale-to-max-pycor (item t-counter opinion-list) M)
        set t-counter t-counter + 1
      ]
    ]
  ]
end

;; REPORTERS

to-report new_opinion
  report max list (0 - M) (min list M (random-normal 0 1) - (initial_groupspread / 2) + (initial_groupspread * group))
end

to-report opinion_change [a s message]
  let core message - (ifelse-value (heterogeneity) [rho_i] [rho]) * a
  let discrepancy abs (message - a)
  let polarity_factor compute_polarity a
  let motcog ifelse-value (motivated_cognition) [motivated_cognition_factor discrepancy (ifelse-value (heterogeneity) [lambda_i] [lambda]) k] [1]
  report max list (0 - M - a) (min list (M - a) ((ifelse-value (heterogeneity) [alpha_i] [alpha]) * s * core * polarity_factor * motcog ))
end

to-report motivated_cognition_factor [d l kk]
  report (l) ^ kk / (l ^ kk + d ^ kk)
end

to-report compute_polarity [a]
  report ifelse-value (polarity) [max list (0) (M ^ 2 - (abs a) ^ 2) / M ^ 2] [1]
end

to-report confine-opinion-scale-to-max-pycor [x ma]
  ;; confines values to certain bounds, values exceeding the bound are set to the bound
  ;; x is the value to confine, ma is the absolute value of the maximal values to display
  ;; scales x such that it coincides with the bounds maxpycor and -maxpycor
  let y max list (min list x (ma - 0.0000000001)) (- ma + 0.0000000001)
  report y * max-pycor / ma ;; set to 0.999999999 instead of 1 to make these opinions visible in opinion histogram
end

to-report colorcode [x max_x]
  report ifelse-value (grayscale = true)
    [9.9 - 9.9 * min (list (x / max_x) max_x) / max_x]
    [hsb (270 - 270 * (x / max_x)) 100 100]
end

to-report random-beta [mu sigma]
  ifelse (sigma = 0 or mu = 1 or mu = 0) [report mu] [
   set sigma precision (min list sigma (sqrt (mu * (1 - mu) * 0.95))) 5
   let nu mu * (1 - mu) / sigma ^ 2 - 1
   let a max list 0.01 mu * nu
   let beta max list 0.01 (1 - mu) * nu
   let x random-gamma a 1
   report ( x / ( x + random-gamma beta 1) )
  ]
end

to-report fragmentation
  let bandwidth 0.1
  let d_x 0.1 * bandwidth
  report (d_x * sum map [xx -> abs (xx / d_x)] diff ksdensity bandwidth d_x) * standard-deviation [opinion] of turtles / M / 4
end
; The following three reporters are only needed for the computation of fragmentation
to-report ksdensity [bw d_x]
  let x n-values (2 * M / d_x + 1) [ xx -> xx * d_x - M]  ; make list -M:dx:M
  let y map [xx -> sum [(1 / count turtles) * normal-pdf xx opinion bw] of turtles] x  ; compute list with density values for x
  report y
end
to-report normal-pdf [x mu sd]
  report 1 / (sd * sqrt (2 * pi)) * exp (-0.5 * (x - mu) ^ 2 / sd ^ 2)
end
to-report diff [x]
  report (map [[xx yy] -> xx - yy] butfirst x butlast x)
end

;; DEFAULT SETTINGS, SCENARIOS, AND FIGURE EXPORTS

to set_baseline
  set N 500
  set rho 0
  set alpha 0.2
  set theta 0.01
  set M 3.5
  set motivated_cognition false
  set lambda 0.5
  set k 2
end

to visualization_default
  set visualization "Heatmap timeline"
  set skip_ticks_draw 10
  set focus false
  set color_axis_max 0.15
  set iterations_per_tick 1
  set grayscale true
end

to group_default
  set initial_groupspread 1
  set intergroup_credibility 0.5
end

to polarity_sourcecredibility_off
   set polarity false
   set intergroup_credibility 1
   set initial_groupspread 0
end

to robustness_off
  set theta_as "idiosyncrasy probability"
  set social_network false
  set heterogeneity false
end

to robustness_default
  set theta_as "idiosyncrasy probability"
  set social_network true
  set heterogeneity true
  set following 5
  set friends_network "random"
  set friends 5
  set alpha_dispersion 0.03
  set rho_dispersion 0.03
  set theta_dispersion 0.005
  set lambda_dispersion 0.1
end

to scenario [name]
  set_baseline
  if name = "1-B" [ set theta 0.17 ]
  if name = "1-C" [ set rho 1 ]
  if name = "2-A" [ set motivated_cognition true ]
  if name = "2-B" [ set rho 0.9 set motivated_cognition true set k 10 ]
  if name = "2-C" [ set rho 1 set motivated_cognition true set k 10 ]
  if name = "2-B-long" [ set rho 0.9 set motivated_cognition true set k 10 set iterations_per_tick 20]
  if name = "2-C-long" [ set rho 1 set motivated_cognition true set k 10 set iterations_per_tick 20]
  if name = "Polarity 1" [ polarity_sourcecredibility_off set polarity true set M 2 set rho 1 ]
  if name = "Polarity 2" [ polarity_sourcecredibility_off set polarity true set M 2 set alpha 0.67 set rho 1 ]
  if name = "Source Credibility 1" [ group_default set intergroup_credibility 0.25 ]
  if name = "Source Credibility 2" [ set rho 1 set theta 0.17 set intergroup_credibility 0.25 set initial_groupspread 2.5]
  setup
end
@#$#@#$#@
GRAPHICS-WINDOW
75
415
744
624
-1
-1
3.29
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
200
-30
30
1
1
1
ticks
30.0

BUTTON
335
35
395
68
Setup
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
400
35
465
68
Go
set draw? true\ngo
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
10
40
165
73
N
N
5
5000
500.0
1
1
NIL
HORIZONTAL

TEXTBOX
170
120
238
138
Strength
12
0.0
1

CHOOSER
335
125
500
170
visualization
visualization
"Heatmap timeline" "Agents' trajectories"
1

PLOT
743
492
1009
624
Histogram Attitudes
Current Attitude
NIL
-2.0
2.0
0.0
1.0
true
false
"" "clear-plot\nset-plot-y-range 0 count turtles / 12.5\nset-plot-x-range ( - M - (M / 40)) (M + (2 * M / 40)) \nset-current-plot-pen \"both groups\"\nset-plot-pen-interval (2 * M) / 40\nset-current-plot-pen \"group 0 only\"\nset-plot-pen-interval (2 * M) / 40\n"
PENS
"both groups" 0.1818 1 -5825686 true "" "histogram [opinion] of turtles"
"group 0 only" 0.1818 1 -13840069 true "" "if (intergroup_credibility < 1 or initial_groupspread > 0) [histogram [opinion] of turtles with [group = 0]]"

SLIDER
10
180
165
213
theta
theta
0
0.3
0.01
0.002
1
NIL
HORIZONTAL

SLIDER
335
280
500
313
iterations_per_tick
iterations_per_tick
1
50
1.0
1
1
NIL
HORIZONTAL

SLIDER
335
210
500
243
skip_ticks_draw
skip_ticks_draw
1
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
20
250
165
283
lambda
lambda
0.01
3.5
0.5
0.01
1
NIL
HORIZONTAL

TEXTBOX
335
10
430
31
Controls
18
14.0
1

TEXTBOX
13
341
768
365
Trajectories of attitudes, output measures, distribution of attitudes
18
14.0
1

TEXTBOX
10
10
287
30
Main Model Parameters
18
14.0
1

TEXTBOX
505
285
618
320
Show longer trajectory
12
0.0
1

SWITCH
335
175
425
208
focus
focus
1
1
-1000

TEXTBOX
505
215
630
246
Reduce grapic updates
12
0.0
1

TEXTBOX
495
10
645
32
Scenarios
18
14.0
1

SLIDER
335
245
500
278
color_axis_max
color_axis_max
0.01
0.4
0.15
0.01
1
NIL
HORIZONTAL

BUTTON
430
175
530
208
Change focus
change_focus
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
15
579
75
624
- M
- M
17
1
11

TEXTBOX
17
509
75
537
neutral=0
11
0.0
1

SLIDER
10
110
165
143
alpha
alpha
0
1
0.2
0.01
1
NIL
HORIZONTAL

PLOT
685
215
845
335
motivated cognition
discrepancy
NIL
0.0
1.0
0.0
0.2
true
false
"" "clear-plot\nset-plot-x-range 0 2.5 * lambda\nset-plot-y-range 0 alpha * 2.5 * lambda"
PENS
"" 1.0 0 -16777216 true "" "if motivated_cognition [foreach ( n-values 200 [ [x] -> x / 200 * 2.5 * lambda ] ) [ [x] -> plotxy x (motivated_cognition_factor x lambda k) ]]"

SLIDER
20
285
165
318
k
k
0
35
2.0
1
1
NIL
HORIZONTAL

SLIDER
720
145
905
178
intergroup_credibility
intergroup_credibility
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
720
110
905
143
initial_groupspread
initial_groupspread
0
4
0.0
0.05
1
NIL
HORIZONTAL

SLIDER
10
75
165
108
M
M
0.1
7
3.5
0.1
1
NIL
HORIZONTAL

SWITCH
720
75
818
108
polarity
polarity
1
1
-1000

PLOT
845
215
1005
335
polarity factor
attitude
NIL
0.0
0.0
0.0
1.2
true
false
"" "clear-plot"
PENS
"default" 1.0 0 -16777216 true "" "foreach ( n-values 200 [ [x] -> (x - 100) / 100 * 1.5 * M ] ) [ [x] -> plotxy x ( compute_polarity x) ]"

CHOOSER
1045
110
1230
155
theta_as
theta_as
"idiosyncrasy probability" "back to inital attitude" "weight on initial attitude"
0

MONITOR
15
415
75
460
M
M
17
1
11

SLIDER
10
145
165
178
rho
rho
0
1
0.0
0.01
1
NIL
HORIZONTAL

BUTTON
490
35
553
68
1-A
scenario \"1-A\"
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
556
35
619
68
1-B
scenario \"1-B\"
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
622
35
685
68
1-C
scenario \"1-C\"
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
490
71
553
104
2-A
scenario \"2-A\"
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
556
71
619
104
2-B
scenario \"2-B\"
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
622
71
685
104
2-C
scenario \"2-C\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
743
370
1009
492
Output measures
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" "ifelse ticks > (max-pxcor)\n  [set-plot-x-range (ticks - max-pxcor) ticks]\n  [set-plot-x-range 0 max-pxcor]"
PENS
"bias" 1.0 0 -2674135 true "" "plot abs mean [opinion] of turtles / M"
"diversity" 1.0 0 -16777216 true "" "plot standard-deviation [opinion] of turtles / M"
"initial diversity" 1.0 0 -4539718 true "" "plot 1 / M"
"uniform diversity" 1.0 0 -7500403 true "" "plot 1 / sqrt 3"
"fragmentation" 1.0 0 -14835848 true "" "plot fragmentation"

MONITOR
590
370
650
415
diversity
cum_diversity
3
1
11

MONITOR
648
370
743
415
fragmentation
cum_fragmentation
3
1
11

MONITOR
534
370
591
415
bias
cum_bias
3
1
11

TEXTBOX
385
395
442
413
time ->
11
0.0
1

TEXTBOX
18
468
69
510
positive attitudes
11
0.0
1

TEXTBOX
18
540
69
568
negative attitudes
11
0.0
1

MONITOR
94
370
144
415
NIL
alpha
17
1
11

MONITOR
143
370
193
415
NIL
rho
17
1
11

MONITOR
192
370
242
415
NIL
theta
17
1
11

TEXTBOX
18
378
108
414
Input parameters
12
0.0
1

TEXTBOX
469
379
535
407
Output measures
12
0.0
1

MONITOR
240
370
295
415
lambda
ifelse-value motivated_cognition [lambda] [\"\"]
2
1
11

MONITOR
293
370
350
415
k
ifelse-value motivated_cognition [k] [\"\"]
1
1
11

SWITCH
10
215
188
248
motivated_cognition
motivated_cognition
1
1
-1000

TEXTBOX
170
155
320
173
Degree of assimilation
12
0.0
1

TEXTBOX
170
50
320
68
Number of agents
12
0.0
1

TEXTBOX
170
85
320
103
Maximal Attitude
12
0.0
1

TEXTBOX
170
190
335
208
Idiosyncrasy probability
12
0.0
1

TEXTBOX
170
260
320
278
Latitude of acceptance
12
0.0
1

TEXTBOX
170
295
300
313
Latitude sharpness
12
0.0
1

TEXTBOX
720
10
980
51
Polarity / Source Credibility
18
14.0
1

TEXTBOX
700
195
1015
213
Some factors in the attitude change function
12
0.0
1

SLIDER
1060
255
1200
288
following
following
0
30
5.0
1
1
NIL
HORIZONTAL

SLIDER
1060
340
1200
373
friends
friends
0
100
5.0
1
1
NIL
HORIZONTAL

SWITCH
1050
220
1213
253
social_network
social_network
1
1
-1000

CHOOSER
1060
290
1197
335
friends_network
friends_network
"ring" "random" "cliques"
1

TEXTBOX
1050
170
1200
214
Social Network Restrictions
18
14.0
1

TEXTBOX
1050
385
1200
406
Heterogeneity
18
14.0
1

SLIDER
1055
485
1235
518
rho_dispersion
rho_dispersion
0
0.4
0.03
0.01
1
NIL
HORIZONTAL

SLIDER
1055
450
1235
483
alpha_dispersion
alpha_dispersion
0
0.25
0.03
0.01
1
NIL
HORIZONTAL

SLIDER
1055
520
1235
553
theta_dispersion
theta_dispersion
0
0.4
0.005
0.005
1
NIL
HORIZONTAL

SLIDER
1055
555
1235
588
lambda_dispersion
lambda_dispersion
0
0.6
0.1
0.01
1
NIL
HORIZONTAL

PLOT
1245
225
1405
345
rho_i
NIL
NIL
0.0
1.05
0.0
1.0
true
false
"" "if (not heterogeneity) [clear-plot]\nset-plot-y-range 0 round(count turtles / 8)"
PENS
"default" 0.05 1 -16777216 true "" "if (heterogeneity) [histogram [rho_i] of turtles]"

PLOT
1245
105
1405
225
alpha_i
NIL
NIL
0.0
1.05
0.0
1.0
true
false
"" "if (not heterogeneity) [clear-plot]\nset-plot-y-range 0 round(count turtles / 8)"
PENS
"default" 0.05 1 -16777216 true "" "if (heterogeneity) [histogram [alpha_i] of turtles]"

PLOT
1245
345
1405
465
theta_i
NIL
NIL
0.0
1.05
0.0
1.0
false
false
"" "if (not heterogeneity) [clear-plot]\nset-plot-y-range 0 round(count turtles / 8)"
PENS
"default" 0.005 1 -16777216 true "" "if (heterogeneity) [histogram [theta_i] of turtles]"

PLOT
1245
465
1405
585
lambda_i
NIL
NIL
0.0
2.5
0.0
10.0
true
false
"" "if (not heterogeneity) [clear-plot]\nset-plot-y-range 0 round(count turtles / 8)"
PENS
"default" 0.1 1 -16777216 true "" "if (heterogeneity) [histogram [lambda_i] of turtles]"

SWITCH
1045
415
1202
448
heterogeneity
heterogeneity
1
1
-1000

TEXTBOX
1045
80
1245
100
Idiosyncrasy variants
18
14.0
1

TEXTBOX
1050
10
1290
35
Robustness Checks
18
0.0
1

BUTTON
1215
35
1387
68
Robustness default
robustness_default
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
1045
35
1210
68
Robustness checks off!
robustness_off
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
720
40
930
73
Polarity / Source Credibility off!
polarity_sourcecredibility_off
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
820
75
957
108
Group default
group_default
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
335
95
485
116
Visualization
18
14.0
1

BUTTON
505
130
655
163
Visualization defaults
visualization_default
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
535
175
630
205
Focuses one agent
12
0.0
1

BUTTON
1425
55
1560
88
Polarity 1
scenario \"Polarity 1\"
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
1425
90
1560
123
Polarity 2
scenario \"Polarity 2\"
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
1425
125
1560
158
Source Credibility 1
scenario \"Source Credibility 1\"
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
1425
160
1560
193
Source Credibility 2
scenario \"Source Credibility 2\"
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
1425
10
1515
50
Appendix Scenarios
18
14.0
1

SWITCH
505
250
620
283
grayscale
grayscale
0
1
-1000

@#$#@#$#@
# Individual attitude change and societal dynamics: Computational experiments with psychological theories

## WHAT IS IT?

This is model of repeated attitude change on a one-dimensional attitude scale which is symmetric around the neutral attitude from a maximally negative to a maximally positive attitude. Many models of continuous opinion dynamics are special cases of this model or are closely related. 

Dynamics are based on the passive communication paradigm where a receiver receives a mesage from a source. The model includes the psychological theories for individual attitude change with

  * contagion and assimilation,
  * polarity effects,
  * motivated cognition including a smooth and a sharp (bounded confidence) version, and
  * source credibility based on two groups.

The model 

  * has a dyadic communication regime where an agent receives the attiude of a randomly selected other agent as the message. (Passive version of the pairwise adjustment version of [Deffuant et al 2000](http://dx.doi.org/10.1142/S0219525900000078)),
  * includes an additional model of idiosyncratic attitude formation as introduced by [Pineda et al 2009](http://dx.doi.org/10.1088/1742-5468/2009/08/P08001)),  
  * uses a standard normal distribution for intial and idiosyncratic attitudes, and
  * confines attitudes above and below the maximal attitudes (M) to the maximal values. 

For robustness tests the model also includes options to 

  * change how idiosyncratic attitudes are operationalized, including a version derived from [Friedkin and Johnson 1990](http://dx.doi.org/10.1080/0022250X.1990.9990069),
  * restrict interaction to neighbors in a static social network which has a certain average number of bidirectional friend links and a certain number of directed follower relations (with a scale-free number of followers), and
  * make four global parameters static agent variables from a Beta distribution around a mean value.

For the emerging attitude landscapes, the model focuses on the output variables of

  * bias, 
  * diversity (having bipolarization and consensus as extreme cases), and 
  * fragmentation. 

It has the following visualization options:

  * a rolling colored histogram (heatmap) of attitude density over time
  * rolling trajectories of attitudes over time
  * an additional focus on the trajectory of a randomly chosen agent
  * a bar plot histogram of current attitudes 
  * trajectories of the output measures


## EXAMPLE RUNS

Six example runs are shown in the paper this model is attached to. These runs can be reproduced by clicking on the buttons in the Section "Scenarios":

1-A, 1-B, 1-C (for Examples in Figure 6)
2-A, 2-B, 2-C (for Examples in Figure 7)

These buttons adjust the parameters and initialize the world. Then click "Go". 
The parameters in the Sections "Polarity / Source Credibility" and "Robustness Checks" are not changed through the buttons so they can be easily used to check how parameter changes in these sections modify the six base examples. The baseline parameter settings can be switched on by clicking the buttons "Polarity / Source Credibility off!" and "Robustness checks off!".

The examples in the Supplemental Material can be initialized by clicking the buttons

Polarity 1, Polarity 2 (for Figure A.3)
Source Credibility 1, Source Credibility 2 (for Figure A.4)


## SIMULATION EXPERIMENTS

In the BehaviorSpace (Tools menu) the two parameter sweep experiments used in the paper are specified to be reproduced. Computation takes time!



## CREDITS AND REFERENCES

Supplemental Material for 

**Individual attitude change and societal dynamics: Computational experiments with psychological theories**

by Jan Lorenz, Martin Neumann, Tobias Schröder

published in *Psychological Review* 2021
Preprint https://psyarxiv.com/ebfvr/

Programmed and designed by Jan Lorenz

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
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="SimulationExperiment_1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run_until_world_full</go>
    <timeLimit steps="1"/>
    <metric>cum_bias</metric>
    <metric>cum_diversity</metric>
    <metric>cum_fragmentation</metric>
    <enumeratedValueSet variable="alpha">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <steppedValueSet variable="theta" first="0" step="0.01" last="0.3"/>
    <steppedValueSet variable="rho" first="0" step="0.02" last="1"/>
    <enumeratedValueSet variable="M">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="iterations_per_tick">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spinup_tick">
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="motivated_cognition">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lambda">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="theta_as">
      <value value="&quot;idiosyncrasy probability&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_groupspread">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intergroup_credibility">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="polarity">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color_axis_max">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skip_ticks_draw">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;Agents' trajectories&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SimulationExperiment_2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run_until_world_full</go>
    <timeLimit steps="1"/>
    <metric>cum_bias</metric>
    <metric>cum_diversity</metric>
    <metric>cum_fragmentation</metric>
    <enumeratedValueSet variable="alpha">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="theta">
      <value value="0.01"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rho" first="0" step="0.02" last="1"/>
    <enumeratedValueSet variable="motivated_cognition">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="lambda" first="0.05" step="0.05" last="2"/>
    <enumeratedValueSet variable="k">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="3.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="iterations_per_tick">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spinup_tick">
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="theta_as">
      <value value="&quot;idiosyncrasy probability&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial_groupspread">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intergroup_credibility">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="polarity">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color_axis_max">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skip_ticks_draw">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;Agents' trajectories&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
