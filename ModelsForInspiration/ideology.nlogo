; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;  IDEOLOGY, COMMUNICATION, & POLARIZATION  ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;

extensions [matrix NW]      ; this is my first time using the matrix extension, so the code can probably be cleaned up (a lot)

globals [
  ; cognition (tensor product model)
  w_i              ; learning rate (called d in the paper), larger values = slower learning in each tick, 0 < w_i < 1
  ideology_a       ; ideology a, a 5 item vector

  ; social dynamics (Friedkin)
  K                ; repeats of the Friedkin grounding process in each tick
  sigmoid_s        ; steepness of the sigmoid function
  influence_m      ; influence matrix
  outgoing_info_M  ; matrix storing the opinions that agents express in each tick
  A_M              ; the A matrix, a diagonal N × N matrix with 1 – stubborness in its element at ith row and ith column and 0 elsewhere
  I_M              ; identity matrix
  Cf_M             ; another identity matrix; C in Friedkin model is absorbed by the tensor product model above
  grounded_info_M  ; matrix storing output from Friedkin process
]

breed [agents an-agent]

agents-own[
  ; cognition
  type_agent      ; 1 = ideological filter and ideological ego-involvement - takes any input as a form of confirmation of the learned ideology
                  ; 2 = ideological filter and non-ideological ego-involvement - changes opinion depending on starting point to become staunch supporters or strong oponents
                  ; 3 = unbiased filter and ideological ego-involvement - initially retains a learned ideology, but change their opinions in line with the preponderance of the inputs
                  ; 4 = unbiased filter and non-ideological ego-involvement - changes opinions in accordance with inputs
  ideology        ; a noisy version of ideology_a (infuences interpreter for type 1 and 2 agents, influences the ego of type 1 and 3 agents; not relevant to type 4 agents)
  belief_system   ; starting beliefs about the 5 topics that comprise the focal ideology (helps to shape type 2 and type 4 agents' initial memories)
  interpreter     ; C in the paper, represents the agent's stable beliefs about associations between the n propositions which may bias the way they interpret incoming input
  memory          ; M in the paper for memory. Initialised depending on agent type, then updated over course of simulation.
  self_rep        ; self-representation - 5 item vector; memory is a conjunctive representation of this and either the agent's ideology OR their belief system after setup
  incoming_info   ; input agent recieves to their cognitive system in a tick
  outgoing_info   ; what the agent then sends out to the world
  dot_product     ; similarity of outgoing_info and ideology_a

  ; social
  stubborness     ; 'w_ii', the influence agents' have on themselves during the social influence process
  status          ; determines the relative influence that one agent has over another at t0

  ;misc.
  default_color   ; solor at t0, to assist with plotting
]

directed-link-breed [influences influence]    ; influence ties are directed ( influence of j on i can differ from influence of i on j)
                                              ; they are also stored in the influence_m matrix, but represented here so that network dynamics can be observed in the interface


influences-own [
  weight
]


; SETUP ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;


to setup
  clear-all
  reset-ticks
  setup-world
  setup-agents
  friedkin_as_matrix         ; matrices made life much easier here
end

to setup-world
  ask patches [
    set pcolor white
  ]

  ; Initialise Parameters for Tensor Product (thinky bit for opinion formation and expression)
  set w_i .5
  set K 1
  set ideology_a fill-matrix 1 5  [-> (-1 + (random-float 2 ) )]     ; draw values for ideology_a from uniform distribution (-1 1)
  set ideology_a normalise matrix:get-row ideology_a 0               ; normalise using the 'normalise' to-report (scroll down)

  ; Initialise the Friedkin et al. part
  set sigmoid_s 2
  set outgoing_info_M matrix:make-constant n-agents 5 0       ; empty n-agents * 5 matrix, ready to store

end


to setup-agents

 create-agents (n-agents) [
    setxy random-xcor random-ycor
    set shape "circle"
    set size .7
    set default_color color
    layout-circle agents 15                         ; position agents in circle (fully connected network at present

    ; tensor-product traits
    set type_agent agent_type        ; cogntive style determined by chooser on interface
                                     ; change later to include possibility for heterogeneous populations

    ; learned ideology (of ideology_a with noise);  e0
    set ideology fill-matrix 1 5 [-> random-normal 0 .1 ]                       ; first draw the noise from normal distribution with mean of 0 and sd of .1
    matrix:set-row ideology 0 matrix:get-row (ideology_a matrix:+ ideology) 0   ; then add that to ideology_a
    set ideology normalise matrix:get-row ideology 0                            ; normalise using 'normalise' to-report
    ;print  word "normalised ideology: " matrix:pretty-print-text ideology

    ; self-representation; s0
    set self_rep fill-matrix 1 5 [-> (-1 + (random-float 2 ) )]          ; each agent
    set self_rep normalise matrix:get-row self_rep 0
    ;print matrix:pretty-print-text self_rep

    ;individualised belief system; eu
    set belief_system fill-matrix 1 5 [-> (-1 + (random-float 2 ) )]     ; expected value = 0
    set belief_system normalise matrix:get-row belief_system 0           ; used for agent's with non-ideological ego-involvement


    ; interpeter and memory mechanisms, varies by type_agent (referred to as C and M in R code respectively)
    set interpreter matrix:make-constant 5 5 0
    set memory matrix:make-constant 5 5 0

    ifelse type_agent = 1 or type_agent = 2 [
      set interpreter matrix:times matrix:transpose ideology ideology    ; get an ideological filter by multiplying the transpose of the ideology vector (making it a col vec) by itself
                                          ;; LEARNING OPPORTUNITY - uncomment the following code
                                          ;print matrix:pretty-print-text ideology       ; to see the relationship between an agents initially (learnt) ideology
                                          ;print matrix:pretty-print-text interpreter    ; and their ideological filter.
                                          ;; Parsegov et al. (2017) provide a nice explanation of such 'prejudices' (p. 1)
    ] [
      set interpreter matrix:make-identity 5                            ; type 3 and 4 don't have an ideological filer (identity matrix instead)
    ]
    ifelse type_agent = 1 or type_agent = 3 [
      set memory matrix:times matrix:transpose self_rep ideology        ; have ideological ego-involvement
    ] [
      set memory matrix:times matrix:transpose self_rep belief_system   ; type 2 and 4 have non-ideological ego-involvement
    ]

    ; Friedkin traits
    set stubborness random-float .6
    set status random-normal 1 1                       ;  slightly different to the paper but serves the same purpose
    if status < 0 [ set status 0 ]                     ;  no negative statuses allowed
  ]
end


to friedkin_as_matrix

  set influence_m matrix:make-constant n-agents n-agents 0             ; initialise empty n-agents x n-agents matrix
  let list_agents n-values n-agents [i -> i]                           ; create a list of agents to loop through (order important)
  foreach list_agents [                                                ; now to get agents to allocate influence to themselves and others
    i ->
    foreach list_agents [                                              ; ! could have used sort ! (fix up sometime)
     j ->
      let stubborn_i item 0 [stubborness] of agents with [who = i]
      let  status_i item 0 [status] of agents with [who = i]
      if i != j [
        let stubborn_j item 0 [stubborness] of agents with [who = j]
        let status_j item 0 [status] of agents with [who = j]
        matrix:set influence_m i j sigmoid (status_i - status_j)       ; the social influence i feels from j depends on how much higher j's status is than i's
      ]                                                                ; Stan - I realise this is probably not the best way of doing this... Any ideas ? :)
      matrix:set influence_m i i stubborn_i                            ; add in self-influence in the i,i cell of the matrix
    ]
  ]

  standardise_influence               ; standardise each row in the influence_m matrix

  ;print matrix:pretty-print-text influence_m

  set A_M matrix:make-constant n-agents n-agents 0
  ask agents [
    matrix:set A_M who who (1 - stubborness)                     ; chuck 1 - their stubborness on the diag
  ]
  set I_M matrix:make-identity n-agents                          ; identity matrix
  set Cf_M matrix:make-identity 5                                ; smaller identity matrix
  set grounded_info_M matrix:make-constant n-agents n-agents 0   ; empty, ready to store

  nw:set-context agents influences                               ; translate weights in influence_m to 'influences' links between agents
  let list_agents2 n-values n-agents [i -> i]
  foreach list_agents [
    i ->
    let me item 0 [who] of agents with [who = i]
    foreach list_agents2 [
      j ->
      if i != j [
        let you item 0 [who] of agents with [who = j]
        let weight_ij matrix:get influence_m me you
        ask turtle me [
          create-influence-to turtle you [set weight weight_ij]
        ]
      ]
    ]
  ]
 visualise_ties_weighted


end


; SCHEDULE ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;

; note - in the future, this code will be compartmentalised (divided up and moved to sub procedures)
; prioritsed getting *something* out over best practices

to go
if ticks = 50 [stop]        ; run for 50 time steps

  ask agents [
    ifelse social_dynamics = false [
      ; In the absence of social dynamics, agents recieve random input in each time step
      set incoming_info fill-matrix 1 5 [-> (-1 + (random-float 2 ) )]
      set incoming_info normalise matrix:get-row incoming_info 0
      ;print matrix:pretty-print-text incoming_info
    ]
    [  ; when the Friedkin et al. social influence process is included
      ; still random input in first tick
      ifelse ticks = 0 [
        set incoming_info fill-matrix 1 5 [-> (-1 + (random-float 2 ) )]
        set incoming_info normalise matrix:get-row incoming_info 0
      ]
      [ ; otherwise, get incoming_info from the information agents grounded in the last time step
        set incoming_info matrix:from-row-list (list (matrix:get-row grounded_info_M who) )
        set incoming_info normalise matrix:get-row incoming_info 0    ; normalise first though
      ]
    ]

    ; Tensor Product model (thinky bit for opinion formation and expression)

    ; 1. incoming information (another agent's opinion) is interpreted
    let interpreted_info matrix:times interpreter matrix:transpose incoming_info        ; eti = Ci(input).
    ; 2. source is attributed via memory
    let sourced_info matrix:times memory interpreted_info                               ; sti = M(t−1)ieti
    ; 3. an episodic memory is formed on the basis of ^ via Hebbian learning
    let episodic_memory matrix:times sourced_info matrix:transpose interpreted_info
    ; 4. long-term memory is then updated
    set memory ( matrix:times w_i memory) matrix:+ (matrix:times (1 - w_i) episodic_memory)       ; weighted av. of the existing and episodic memories
    ; 5. finally, the agent decides how they would/will express their opinion to others
    let  self-interepreted_memory matrix:times self_rep memory                                    ; as memory is a rank 2 tensor, activating the self_rep (a rank 1 tensor) allows a representation of the opinion vector to be retrieved
    let normalised_self-interepreted_memory normalise matrix:get-row self-interepreted_memory 0
    let normalised_self-interepreted_memoryT matrix:transpose normalised_self-interepreted_memory
    set outgoing_info matrix:times interpreter normalised_self-interepreted_memoryT               ; outgoing information is also filtered by the interpreter
                                                                                                  ; stored as column vector for consistency

                              ; LEARNING OPPORTUNITY  - if you want to get a good idea of how type_agent influences this process,
                              ; reduce the number of agents to 1 on the interface, change the max ticks to 1, and uncomment the following code:
                             ; print matrix:pretty-print-text incoming_info                       ;  for type 3 and 4 the first two are the same
                             ; print matrix:pretty-print-text interpreted_info                    ;  (i.e., filtering is unbiased)
                             ; print matrix:pretty-print-text sourced_info
                             ; print matrix:pretty-print-text episodic_memory
                             ; print matrix:pretty-print-text memory
                             ; print matrix:pretty-print-text self-interepreted_memory            ; same as outgoing_info for type 3
                              ;print matrix:pretty-print-text outgoing_info                       ; and type 4 agents


    ; compare the dot product of each agent's outgoing_info and ideology_a
    set dot_product matrix:times ideology_a  outgoing_info
    set dot_product matrix:get dot_product 0 0
    set color scale-color red dot_product -2 2                          ; set agent color to reflect this

    ; update plots
    set-current-plot "similarity of expressed opinions and the taught ideology " ; main figure in the paper
    create-temporary-plot-pen (word who)
    set-plot-pen-color default_color
    plotxy ticks dot_product

    set-current-plot "similarity of incoming and expressed opinions"
    create-temporary-plot-pen (word who)
    set-plot-pen-color default_color
    let comp cosine_sim incoming_info matrix:transpose outgoing_info
    plotxy ticks comp

    ; stick all of the agents' outgoing_info into a matrix
    matrix:set-row outgoing_info_M who matrix:get-row matrix:transpose outgoing_info 0      ; to feed into...
  ]

  if mobility_when = "before" [
   network_dynamics
  ]

  ; Communication and Social Infuence via Friedkin et al.'s model (if permitted)

  if social_dynamics = true [
    foreach n-values K [i -> i] [     ; repeat process K times
      set grounded_info_M ( matrix:times A_M influence_m) matrix:* (matrix:times outgoing_info_M matrix:transpose Cf_M) matrix:+ (matrix:times ( I_M matrix:- A_M) outgoing_info_M )
    ]
  ]

  ;; Social network dynamics play out (if permitted)

  if mobility_when = "original_schedule" [
   network_dynamics
  ]

   visualise_ties                              ; translate weights in influence_m to 'influences' links between agents
   visualise_ties_weighted

  ;print count influences
  ;print matrix:pretty-print-text influence_m


tick
end


; SUB-PROCEDURES ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;


to-report fill-matrix [n m generator]
  report matrix:from-row-list n-values n [n-values m [runresult generator]]
end

to-report normalise [ vector ]                    ; normalise a vector
  let list_i range (length vector)
  let my_list []
  foreach list_i [
    x -> let val_i item x vector
    set my_list lput (val_i * val_i) my_list
  ]
  let magn sqrt sum my_list
  let almost map [ i -> (i / magn)] vector
  ; print sqrt sum map [i -> i * i ] almost        ; check that normalising worked
  report matrix:from-row-list (list almost)       ; report as matrix object
end

to network_dynamics
    if relational_mobility = true [
    let list_agents n-values n-agents [i -> i]
    foreach list_agents [
    i ->
    let me item 0 [who] of agents with [who = i]
    foreach list_agents [
      j ->
        let you item 0 [who] of agents with [who = j]
        if i != j [
          if mobility_when = "original_schedule" [
            let i_opinion matrix:from-row-list (list (matrix:get-row grounded_info_M me) )
            let j_opinion matrix:from-row-list (list (matrix:get-row grounded_info_M you) )
            let cosim_ij cosine_sim i_opinion j_opinion
            ifelse cosim_ij > 0 [
              matrix:set influence_m i j sigmoid cosim_ij            ; ties strengthened when agent's opinions align
            ] [                                                      ; else
              matrix:set influence_m i j 0                           ; ties severed if they disagree
            ]
          ]
          if mobility_when = "before" [
            let i_opinion matrix:from-row-list (list (matrix:get-row outgoing_info_M me) )
            let j_opinion matrix:from-row-list (list (matrix:get-row outgoing_info_M you) )
            let cosim_ij cosine_sim i_opinion j_opinion
            ifelse cosim_ij > 0 [
              matrix:set influence_m i j sigmoid cosim_ij            ; ties strengthened when agent's opinions align
            ] [                                                      ; else
              matrix:set influence_m i j 0                           ; ties severed if they disagree
            ]
          ]
        ]
      ]
    ]
    standardise_influence                      ; standardise each row of the influence_m matrix
  ]
end



to standardise_influence
  let rows n-values n-agents [i -> i]                      ; standardise weights in influence_m so they sum to one
  foreach rows [
    x ->
    let row matrix:get-row influence_m x                   ; done by extracting relevant row
    let total_weight sum row                               ; calculating the current total of all weights
    let temp map [i -> (i / total_weight)] row             ; *math* across call cells in row so they now sum to 1
    matrix:set-row influence_m  x temp                     ; then updating row in influence_m
  ]
end

to-report cosine_sim [vector_1 vector_2]                   ; calculate the cosine similarity (make sure that you feed in row vectors)
  let a normalise matrix:get-row vector_1 0                ; normalise the vectors
  let b normalise matrix:get-row vector_2 0
  let almost_there matrix:times a matrix:transpose b       ; calculate
  report matrix:get almost_there 0 0                       ; extract value from matrix object and report
end

to-report sigmoid [x]
  report ( 1 / (1 + exp (sigmoid_s * ( - x ))) )          ; sigmoid function
end


to visualise_ties                                       ; translate weights in influence_m to 'influences' links between agents

  nw:set-context agents influences
  let list_agents n-values n-agents [i -> i]
  foreach list_agents [
    i ->
    let me item 0 [who] of agents with [who = i]        ; returns agent i's id #
    foreach list_agents [
      j ->
      let you item 0 [who] of agents with [who = j]     ; returns agent j's id #
      if me != you [
        let weight_ij matrix:get influence_m me you                         ; influence j has on i
        ask an-agent me [
          if out-influence-neighbor? an-agent you = true [                  ; if i --> j
            ifelse weight_ij = 0 [                                          ; and j's opinion contradicted i's
              ask influence-with an-agent you [die]                         ; cut the tie off
            ] [                                                             ; (else) if agent j's opinion resonated with i
              ask influence-with an-agent you [ set weight weight_ij ]      ; increase weight of influenced tie to them
            ]
          ]
        ]
      ]
    ]
  ]
  layout-spring agents influences  .2 10 10
end

to visualise_ties_weighted
  let most_influential max-one-of influences [weight]                   ; set thickness of ties to reflect relative weight in visualisation
  let weight_most_influential [weight] of most_influential
  ask influences [
    set thickness ( weight / weight_most_influential ) * .05
    ; set color scale-color grey ( weight / weight_most_influential ) -2 2
  ]

end



@#$#@#$#@
GRAPHICS-WINDOW
218
33
658
474
-1
-1
13.1
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
23
36
195
69
n-agents
n-agents
10
500
100.0
10
1
NIL
HORIZONTAL

BUTTON
365
499
431
532
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
440
499
503
532
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

SWITCH
32
312
173
345
social_dynamics
social_dynamics
0
1
-1000

CHOOSER
58
110
150
155
agent_type
agent_type
1 2 3 4
3

TEXTBOX
6
163
314
251
1 = ideological filter and\n       ideological ego-involvement \n2 = ideological filter and\n       non-ideological ego-involvement\n3 = unbiased filter and\n      ideological ego-involvement\n4 = unbiased filter and \n      non-ideological ego-involvement
9
0.0
1

TEXTBOX
14
13
164
31
1. Select the # of agents 
11
0.0
1

TEXTBOX
6
276
215
304
3. Determine whether social dynamics should play out \n
11
0.0
1

TEXTBOX
7
353
203
375
(in first simulations reported in the paper, \nthey do not)
9
0.0
1

TEXTBOX
7
91
233
119
2. Choose the agents' *cognitive style*\n
11
0.0
1

TEXTBOX
146
15
296
33
(100 in paper)
9
0.0
1

PLOT
670
13
1203
314
similarity of expressed opinions and the taught ideology 
time
dot product
0.0
50.0
-1.0
1.0
false
false
"" ""
PENS

PLOT
671
325
1205
543
similarity of incoming and expressed opinions
time
dot product
0.0
50.0
-1.0
1.0
false
false
"" ""
PENS

TEXTBOX
1215
503
1365
536
<-- when social_dynamics is off, you should expect to see spaghetti here 
9
1.0
1

SWITCH
23
422
177
455
relational_mobility
relational_mobility
0
1
-1000

TEXTBOX
7
388
196
430
4. Decide whether the agents can change their social ties
11
0.0
1

TEXTBOX
9
463
209
485
(only allow when social_dynamics is on) 
9
0.0
1

CHOOSER
67
489
196
534
mobility_when
mobility_when
"original_schedule" "before"
1

TEXTBOX
11
490
62
553
5. Decide when ^ happens
11
0.0
1

@#$#@#$#@
## WHAT IS IT? 

Kashima et al.'s (2021) **'ideology, communication and polarization'** model, adapted from R by Elle Pattenden for the SFI complexity interaction (public opinion project group). 

*Please note, this is a working, first-pass model. I still need to clean up the code and complete the documentation.* 
 
The model examines how *systems* of beliefs, or ideologies, concerning interrelated topics evolve overtime as agents are exposed to incoming information (in the paper, neo-liberalism is used an example of an ideology that is comprised of opinions on several interdependent issues). It combines a simple model of ideological thinking (the Tensor Product model) with Friedkin et al.'s (2016, 2017) model of multidimensional opinion dynamics in social networks. In doing so, it extends their findings on consensus formation by (1) introducing additional individual differences (i.e., potential biases) in the agents' cognition, which impact the way they process incoming information, and (2) allowing agents to modify the strength of their ties to others (i.e., they interact in dynamic social networks). Further information on both elements is provided under the social-cognitive components subheading below.   

### Socio-Cognitive Components 

#### Communication and Grounding 

In the full model, agents (simultanesouly) communicate their opinions to one another, with each agent considering the weighted set of opinions they encounter when updating their own. In other words, the output of the agent's cognitive system is broadcast to the world, with each agent aggregating these ideas to form the input into their cognitive system in the next time step. 

However, some agents opinions are more influential than others. We conceptualise social influence as a finite resource that is allocated by each agent, thereby determining how much they pay attention to the opinions that others are expressing. The weight agent i places on the opinion expresses by every other agent j in the population is stored in a row vector (arranged for convienance here as a n-agent x n-agent matrix). These values are set via status comparisons - agents' pay more attention to the opinions of those with higher ranks than themselves - that take place when each run of the simulation is setup. We maintain the individual differences in susceptibility to social influene that were introduced by Friedkin et al., meaning that some agent's are more stubborn in the face of (i.e., less susceptible to) social influence than others. Each row in the infuence matrix, reflecting the influence that agents have on a focal agent, as well as the impact they have on themselves, are standardised (ensuring they sum to one). 

When social_dynamics on the interface is 'turned off', the agents receive random input in each time step. 

#### Personal Ideologies and Individual Differences in 'Cognitive Style' 

Agents hold multiple (n = 5) political opinions that together comprise their ideology. 
Their ideology is stored in long-term memory as a joint representation with their identity (or self representation), the latter being an individual difference that varies between agents but remains constant throughout each run of the simulation. Importantly, the agents also differ in terms of the lintering impact of an initally learnt ideology, as determined by their expression of two traits (each with two levels: ideologically biased or unbiased) that together define their *cognitive style* (set by agent_type on the interface):  

1. *Interpretation*  - agents with ideological interpreters filter incoming information in a way that makes it (seem) more consistent with their initial set of beliefs (i.e., they interpret information in a biased manner that is influenced by the 'prejudices' they hold at t0). The more similar an input is to their initial learned ideology, the more amplified it becomes. Conflicting inputs, in contrast, are encoded as their antithesis so that they no longer give rise to cognitive dissonance. Unbiased (non-ideological) interpreters, on the other hand, evaluate each opinion they encounter independently. This means that the incoming input makes it through their filter intact. Interpreters also filter outgoing information in the same fashion. 


2. *Ego Involvement in Memory* - agents with ideological ego-involvement start with a memory representation that associates their identity and the initally learnt ideology. This has a large impact on the way that they encode the subsequent opinions that they encounter; as they retrieve memories based in the ideology when incorperating new information, they display an initial resistance to change (that becomes an inability to change when combined with an ideological interpreter). Agents that have non-ideological ego involvement, on the other hand, start off with a memory representation featuring associations between their identity and ideas unrelated to the initially learnt ideology (see the belief_system variable).


#### Dynamic Influence Networks 

When relational mobility is incorperated in the model, agents modify the strength of their ties (and, therefore, their capacity to be influenced by) other agents on the basis of the degree to which they agree with the opinions that others are expressing. If agent j's opinion resonates with agent i (i.e., the cosine similarity between their two opinion vectors is positive), their tie strength is increased. If they are anatagonistic to each other (i.e., cosine is <= 0), the tie is severed. In other words, the network dynamics included that can be included in this model are driven by, and produce, homophily and the biased assimilation of opinions.

Note - in the original simulations, network dynamics took place *after* the social influence process. The switch on the interface allows you to compare the difference when it takes place before (which is what I would do if working with this further). 


## HOW TO USE IT

Follow the steps on the interface (more information to be included here in time)


## THINGS TO TRY

Start without social dynamics - i.e., have agents recieve random information in each time step - and explore the impact of the different cognitive styles. 

Then repeat the process with social_dynamics enable. Notice the different pattern of results with each agent_type (including variability in the end point for some). 

Finally, allow the agents to reshape their social networks by setting relational_mobility on. 

Some other suggestions for getting a better grasp on what is happening in the model are included as comments in the code tab (I am hoping to come back to this at some point). 


## EXTENDING THE MODEL

The model could easily be extended to include heterogeous populations of agents, in terms of their cognitive style and/or motivations when updating network ties. Another option would be to start with a more realistic network structure (i.e., not assume that all agents have a degee of n-agents at t0). 


## CREDITS AND REFERENCES

Kashima, Y., Perfors, A., Ferdinand, V., & Pattenden, E. (2021). Ideology, communication and polarization. Philosophical Transactions of the Royal Society B, 376(1822), 20200133.

Friedkin, N. E., Proskurnikov, A. V., Tempo, R., Parsegov, S. E. (2016). Network science on belief system dynamics under logic constraints. Science, 354(6310), 321–326. doi:10.1126/science.aag2624  

Parsegov SE, Proskurnikov AV, Tempo R, Friedkin et al. (2017). Novel multidimensional models of opinion dynamics in social networks. IEEE Trans. Autom. Control 62, 2270-2285. 
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
0
@#$#@#$#@
