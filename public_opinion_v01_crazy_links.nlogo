extensions [ palette csv nw matrix ]

; Bad news: The NW extension is not particularly useful for us. "At the moment, nw:save-matrix does not support link weights.
; Every link is represented as a "1.00" in the connection matrix. This will change in a future version of the extension."

; TODO:
; 4. Links should really be named with ties, e.g. not family but family-ties, to be clearer about what's up
; 5. Have a chooser for network display since a circle makes groups hard to visualize
; DONE. 1.1 Make bounds on the opinions so they can't go beyond 0 or 100.
; DONE. 1.2 Make bounds on the weights so they can't go beyond 0 or 1.
; DONE. 2. Make opinion chooser that allows uniform or normal distribution (say, dev at 10).
; DONE. 3. Create better network.
; make a toggle switch setting for a) the basic every family 4, every workplace 20, and every friend group 10;
; OR b) more distributional methods as best I can implement them in a first pass.

globals [
  num-agent
  num-interactions
  family-ties-m
  coworker-ties-m
  friend-ties-m
  interactions-family-m
  interactions-coworkers-m
  interactions-friends-m
]

turtles-own [
  opinion
  tolerance
  family_id
  workplace_id
  friend_group_id
  num-family-ties
  num-coworker-ties
  num-friend-ties
  my-interactions
  my-group      ;; a number representing the group this turtle is a member of, or -1 if this
  my-fam-group  ;; turtle is not in a group.
  my-work-group
  my-friend-group
  my-interactors
]

links-own [ weight ]

directed-link-breed [family family-member]     ; because we are using weights, these need to be directed
directed-link-breed [coworkers coworker]
directed-link-breed [friends friend]

;undirected-link-breed [family family-member]     ; because we are using weights, these need to be directed
;undirected-link-breed [coworkers coworker]
;undirected-link-breed [friends friend]


; SETUP ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;

; OVERVIEW. This text is repeated again below, a snippet at a time, to match it to the code.

;## setup (setup is the standard name for the setup routine)
;1. Get global variables or setup variables from interface.
;	- Default tolerance value (e.g. 20).
;	- Default opinion split (e.g. 50%).
;	- Default family size; default coworkers size; default friends size.
;2. Generate agents.
;	- Number of agents from interface control.
;	- Each agent has an opinion. Value from -50 to 50, say.
;	- Each agent has a tolerance for other opinions. Allowed distance of another agents' opinion, e.g. 20. This can be used for deciding on whether to strengthen or weaken a tie.
;	- Each agent has family ties, coworker ties, and friend ties. This may be done a number of ways: agentsets, links, different link breeds, hypergraph etc. Not sure of the best way. This could also be done outside of agent generation, in a network setup routine.
;3. Generate initial network
;	- However makes sense
;4. Report initial network of ties (ties matrix) for output. This would be an adjacency matrix where each tie has a weight from 0 to 1.


to setup

  clear-all

  ;1. Get global variables or setup variables from interface.
  ;	- Default tolerance value (e.g. 20).
  ;	- Default opinion split (e.g. 50%).
  ;	- Default family size; default coworkers size; default friends size.

  set family-ties-m matrix:make-constant number-of-agents number-of-agents 0
  set coworker-ties-m matrix:make-constant number-of-agents number-of-agents 0
  set friend-ties-m matrix:make-constant number-of-agents number-of-agents 0

  ;2. Generate agents.
  ;	- Number of agents from interface control.

  create-turtles number-of-agents [

    ;	- Each agent has an opinion. Value from -50 to 50, say.
    ;    set opinion -50
    ;    set opinion opinion + random 101
    if opinion-distribution = "normal" [
      ; [mid dev mmin mmax] [50 10 0 100]
      set opinion random-normal-in-bounds 50 10 0 100
    ]

    if opinion-distribution = "uniform" [
      set opinion random 101
    ]

    set color palette:scale-gradient [[ 255 0 0 ] [ 255 255 255 ] [0 0 255]] opinion 0 100

    ;	- Each agent has a tolerance for other opinions. Allowed distance of another agents' opinion, e.g. 20. This can be used for deciding on whether to strengthen or weaken a tie.

    set tolerance agent-tolerance

  ]

  ; put them in a circle with radius value
  layout-circle turtles 12

  ;3. Generate initial network
  ; First we'll try using NetLogo's links, which are actually agents. This may end up a mess, but in THEORY it should make things easier.

  ; generate-the-network ; Stan version

  generate_clustered_networks            ; Elle version. using sub-procedure to generate somewhat clustered networks (scroll down)

  ask family [ set color yellow ]
  ask coworkers [ set color green ]
  ask friends [ set color blue ]
  ; ask links [ set weight 1 ]           ; at present, weights are set to .5 when links are created ^

  ; for testing
  ;ask family [ hide-link ]
  ;ask coworkers [ hide-link ]
  ;ask friends [ hide-link ]

  ;4. Report initial network of ties (ties matrix) for output. This would be an adjacency matrix where each tie has a weight from 0 to 1.

  ;4.1. matrices are initialised for storage
  set family-ties-m matrix:make-constant number-of-agents number-of-agents 0         ; empty num-agent * num-agent adjacency matrix to store family ties
  set coworker-ties-m matrix:make-constant number-of-agents number-of-agents 0
  set friend-ties-m matrix:make-constant number-of-agents number-of-agents 0

  ;4.2. matrices are filled with information from the links
  if make-adj-matrices?  [
    create-adj-matrices ; see function to create the adj matrices below
  ]

  ; NETWORK VISUALIZATION
  ; make links a bit transparent. Taken from Uri Wilensky's copyright-waived transparency model
  ask links [
    ;; since turtle colors might be either numbers (NetLogo colors) or lists
    ;; (RGB or RGBA colors) make sure to handle both cases when changing the
    ;; transparency
    ifelse is-list? color
    ;; list might either have 3 or 4 member since RGB and RGBA colors
    ;; are allowed, so you can't just replace or add an item at the
    ;; end of the list.  So, we take the first 3 elements of the list
    ;; and add the alpha to the end
    [ set color lput transparency sublist color 0 3 ]
    ;; to get the RGB equivalent of a NetLogo color we
    ;; use EXTRACT-RGB and then add alpha to the end
    [ set color lput transparency extract-rgb color ]
  ]

  set num-interactions 2
  reset-ticks

end

to generate_clustered_networks               ; this is a dumb first pass at generating clustered networks, not for use in final sims.

  ; families
  let n_families round (number-of-agents / 4)                  ; ~ 4 agents per family
  ask turtles [
    set family_id item (who mod n_families) range n_families   ; assign each agent to a family
  ]
 ask turtles [
    create-family-to other turtles with [family_id = [family_id] of myself]  [ set weight .5 ]   ; create ties to all family members
  ]

  ; workplaces
  let n_workplaces 1 + random (number-of-agents / 2)               ; randomly generate number of workplaces
  ask turtles [
    set workplace_id item (who mod n_workplaces) range n_workplaces   ; assign each agent to a work place
  ]
  ask turtles [
    let fellow_workers [who] of other turtles with [workplace_id = [workplace_id] of myself]   ; get list of potential workmates
    foreach fellow_workers [
      i ->
      if random-float 1.01 < .8 [            ; 80% chance of having tie to each agent in same work place
        create-coworker-to turtle i [ set weight .5 ]
      ]
    ]
  ]

  ; friends
  let n_friend_groups round (number-of-agents / 8)    ; start with assumption that friendship groups have ~ 8 people in them...
  ask turtles [
    set friend_group_id item (who mod n_friend_groups) range n_friend_groups
  ]
  ask turtles [
    let main_gang [who] of other turtles with [friend_group_id = [ friend_group_id] of myself]
    foreach main_gang [
      i ->
      ifelse random-float 1.01 < .8 [              ; .8 prob that ties is made to each member of main gang
        create-friend-to turtle i [ set weight .5 ]
      ] [
        create-friend-to one-of turtles with [friend_group_id != [friend_group_id] of myself]
        [ set weight .5 ]   ; otherwise made randomly to another agent outside of main gang
      ]
    ]
  ]
end

;to generate-the-network
;  ; We'll use Uri Wilkensky's public domain Grouping Turtles Example code, modified, to help us.
;
;  if network-groups-sizes = "fam4 work20 friend10" [
;    let fam-size 4
;    let work-size 20
;    let friend-size 10
;
;    assign-by-size fam-size
;    ask turtles [
;      set my-fam-group my-group
;      create-family-with other turtles with [ my-fam-group = [my-fam-group] of self ]
;      ask my-links [ if random 100 < 5 [ die ] ] ; 5% chance of being estranged.
;      if random 100 < 10 [
;        if 0 < count ((other turtles) with [ my-fam-group != [my-fam-group] of myself ] ) [
;          create-family-member-with one-of ((other turtles) with [ my-fam-group != [my-fam-group] of myself ] )
;        ]
;      ]
;    ]
;
;    assign-by-size work-size
;    ask turtles [
;      set my-work-group my-group
;      create-coworkers-with other turtles with [ my-work-group = [my-work-group] of self ]
;      ask my-links [ if random 100 < 10 [ die ] ] ; 10% chance of being estranged or not knowing each other.
;      if random 100 < 10 [
;        if 0 < count ((other turtles) with [ my-work-group != [my-work-group] of myself ] ) [
;          create-coworkers-with one-of ((other turtles) with [ my-work-group != [my-work-group] of myself ] )
;        ]
;      ]
;    ]
;
;    assign-by-size friend-size
;    ask turtles [
;      set my-friend-group my-group
;      create-friends-with other turtles with [ my-friend-group = [my-friend-group] of self ]
;      ask my-links [ if random 100 < 5 [ die ] ] ; 5% chance of being estranged or not knowing a friend of friends.
;      if random 100 < 10 [
;          if 0 < count ((other turtles) with [ my-friend-group != [my-friend-group] of myself ] ) [
;            create-friend-with one-of ((other turtles) with [ my-friend-group != [my-friend-group] of myself ] )
;          ]
;      ]
;    ]
;
;  ]
;
;  if network-groups-sizes = "size drawn from dists" [
;    print "Sorry, the 'size drawn from dists' option has not been finished yet!"
;
;  ]
;
;  if network-groups-sizes = "random" [
;    ; n-of size agentset
;    ask turtles [
;      create-family-with n-of num-family-ties other turtles
;      create-coworkers-with n-of num-coworker-ties other turtles
;      create-friends-with n-of num-friend-ties other turtles
;    ]
;  ]
;
;end

to create-adj-matrices
  let list_turtles range number-of-agents ; create an ordered list of turtles to loop through
  foreach list_turtles [
    i ->
    foreach list_turtles [
      j ->
      if i != j [                                               ; avoid error when turtles try to evaluate self
        nw:set-context turtles family
        ask turtle i [
          if out-family-member-neighbor? turtle j = true   [          ; if i and j are family
            let tie_strength [weight] of (family-member i j)          ; get the weight of the tie
            matrix:set family-ties-m i j tie_strength                 ; update relevant cell in family-ties-m with weight
          ]
         nw:set-context turtles coworkers
          ask turtle i [
          if out-coworker-neighbor? turtle j = true   [               ; if i and j are coworkers
            let tie_strength [weight] of (coworker i j)               ; ... ... ...
            matrix:set coworker-ties-m i j tie_strength
            ]
          ]
          nw:set-context turtles friends
          ask turtle i [
            if out-friend-neighbor? turtle j = true   [               ; finally, if i and j are friends
            let tie_strength [weight] of (friend i j)
            matrix:set friend-ties-m i j tie_strength
            ]
          ]
        ]
      ]
    ]
  ]
  ; uncomment to confirm this ^ works
   ;print matrix:pretty-print-text family-ties-m
   ;print matrix:pretty-print-text coworker-ties-m
   ;print matrix:pretty-print-text friend-ties-m
   ;print family-ties-m

end


; SCHEDULE ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;


;## go (go is the standard name for the main action loop routine)
;One way to do this, as a place to start.
;1. Each agent chooses (default random, build in moral circle / parochial prefs here) some agents in its network to interact with, writes those choices to a current-tick all-agents-interactions adjacency matrix (interaction matrix, for short). (Btw a tick is Netlogo term for one loop through the go routine.)
;2. The interaction matrix is reported in some way to get written as an output in behaviorspace (we'll explain behaviorspace later). We can also calculate some network stat here to plot in the interface if we care to.
;3. Iterate through the interaction matrix so that each agent
;	- "interacts" with the agents in its row, using its own opinion and tolerance to upweigh or downweigh the tie with each agent. (devil is in the mechanic here, we have options)
;4. Output new ties matrix for writing to table/file, polarization stats.
;5. Check if ties matrix has changed, if not maybe we can stop.
;6. New tick (loop to beginning of go to do it all over again)

to go

  ;1. Each agent chooses (default random, build in moral circle / parochial prefs here) some agents in its network to interact with, writes those choices to a current-tick all-agents-interactions adjacency matrix (interaction matrix, for short). (Btw a tick is Netlogo term for one loop through the go routine.)
  ; Instead of using an interaction adj matrix, for now, we'll just use the links. It's simpler. The link sets are equiv to edge lists which are equiv to an adj matrix.

  ask turtles [
    ; I'm just using the num-interactions variable from the setup right now, but turtles could have differing interaction numbers in the future

    ifelse  count my-links > num-interactions [
      set my-interactions n-of num-interactions my-links      ; 2 interactions per tick, selected from all possible networks
    ] [
      set my-interactions my-links                            ; avoid run time error if agents don't have enough partners
    ]

    if verbose? [
      print [ [(word breed " " who)] of other-end ] of my-interactions
      print [ (word other-end) ] of my-interactions
    ]
  ]

  ;2. The interaction matrix is reported in some way to get written as an output in behaviorspace (we'll explain behaviorspace later). We can also calculate some network stat here to plot in the interface if we care to.
  ; Currently we won't bother with recording this matrix, since the end-of-tick network matrices are more useful.

  ;3. Iterate through the interaction matrix so that each agent
  ;	- "interacts" with the agents in its row, using its own opinion and tolerance to upweigh or downweigh the tie with each agent. (devil is in the mechanic here, we have options)
  ; We'll just be using the agent iterating through the links for now, since the link set is equiv to an adj matrix.

  ask turtles [

    ; we make a set of turtles who are at the end of the randomly chosen links
    set my-interactors turtle-set [other-end] of my-interactions

    ; we call the function that houses the decision rules
    apply-decision-rule-to-interactions

  ]

  ;4. Output new ties matrix for writing to table/file, polarization stats.

  if make-adj-matrices?  [
    create-adj-matrices ; see function to create the adj matrices below
  ]

  ;5. Check if ties matrices have changed, if not maybe we can stop.
  ; This is not necessary if we're only running the model for a limited number of ticks in behavior space.


  ; VISUALIZATION UPDATING

  ; redraw links for thickness according to weight
  ask links [ set thickness weight ]

  ; pointless turning so turtles do something visual each tick
  ask turtles [ rt 20 ]

  ; layout using other than the circle
  ; layout-spring turtles family 0.2 10 1

  ;6. New tick (loop to beginning of go to do it all over again)
  tick

end



to assign-by-size [ group-size ]

  ;; all turtles are initially ungrouped
  ask turtles [ set my-group -1 ]
  let unassigned turtles

  ;; start with group 0 and loop to build each group
  let current 0
  while [any? unassigned]
  [
    ;; place a randomly chosen set of group-size turtles into the current
    ;; group. or, if there are less than group-size turtles left, place the
    ;; rest of the turtles in the current group.
    ask n-of (min (list group-size (count unassigned))) unassigned
      [ set my-group current ]
    ;; consider the next group.
    set current current + 1
    ;; remove grouped turtles from the pool of turtles to assign
    set unassigned unassigned with [my-group = -1]
  ]
end

to apply-decision-rule-to-interactions
    ; First, they need to set the lower and upper bounds on their opinion using the tolerance.
    ; Later they will test if lower < others-opinion <= upper than the others-opinion is within their tolerance
    let lower opinion - tolerance
    let upper opinion + tolerance

    ; FYI: (and this is given as "simple" by the documentation)
    ; "self" and "myself" are very different.
    ; "self" means "me".
    ; "myself" means "the turtle, patch or link who asked me to do what I'm doing right now."


  if decision_rule = "trial_run" [
    ; THE FIRST DECISION RULE! Just some garbage to show how it's done. This decision rule makes no sense.
    ask my-interactions [
      ; Check if within tolerance range, do something depending on that.
      ; The link is "smart" enough to know the other-end is NOT the turtle asking it, it's the other!

      ifelse lower < ([opinion] of other-end) and ([opinion] of other-end) <= upper
        [ ; within tolerance
          set weight weight + .1 ; upweigh link
          keep-weight-in-bounds
          ask myself [ ; here myself is the turtle
            set opinion (opinion + [weight] of myself) ; here myself is the link. GENIUS!
            keep-opinion-in-bounds
          ]
        ]
        [ ; outside tolerance
          set weight weight - .1 ; downweigh link
          keep-weight-in-bounds
          ask myself [
            set opinion (opinion - [weight] of myself)
            keep-opinion-in-bounds
          ]
        ]
    ]
  ]

  if decision_rule = "weighdiff_sigweight" [
    ; first pass at decision rule discussed by group on 25th of Jan, by Elle
    let i [who] of self
;    print word " I am" i
;    print word "my tolerance zone is" lower
;    print word " to " upper
    ask my-interactions [                ; haha, someone make this method less shit (please)
      ask turtle i [
        let j [who] of other-end
;        print word "my partner is" j
        let weight_ij [weight] of myself
;        print word "weight of link: " weight_ij
;        print word "their opinon is " [opinion] of other-end
        if lower < ([opinion] of other-end) and ([opinion] of other-end) <= upper [    ; i updates their opinion if j's opinion falls within their tolerance envelope
;          print "in bounds!"
;          print word "my original opinion was: " opinion
          set opinion (opinion + (weight_ij * ( [opinion] of other-end - opinion)))
;          print word "and after updating, it is: " opinion
        ]
        let diff  abs ( [opinion] of other-end - opinion )
        ifelse diff < 2 * tolerance  [     ; as long as i thinks j's opinion is not too extreme (i.e., it's < 2* their tolerance level)
          ask myself [
            set weight sigmoid (diff / 100)
          ]
        ] [
          ask myself [                    ; when i thinks j is extreme,
            set weight 0                  ; they cut the i -> j tie  by setting the weight = 0
            die                           ; AND asking the link to die
          ]
          ; next step is to get agent i to make another tie here (I need to sleep, so not now)
        ]
      ]
    ]
  ]
end

to keep-opinion-in-bounds
  if opinion < 0 [ set opinion 0 ]
  if opinion > 100 [set opinion 100 ]
end

to keep-weight-in-bounds
  if weight < 0 [ set weight 0 ]
  if weight > 1 [ set weight 1 ]
end

to-report sigmoid [ x ]                          ; sigmoid function
   report (1 / (1 + exp (8 * ( x - .5))) )       ; smaller values of x (i.e., differences between agents' opinions) produce higher values (i.e., of new weights)                                                      ;
end

; from https://stackoverflow.com/questions/20230685/netlogo-how-to-make-sure-a-variable-stays-in-a-defined-range

to-report random-normal-in-bounds [mid dev mmin mmax]
  let result random-normal mid dev
  if result < mmin or result > mmax
    [ report random-normal-in-bounds mid dev mmin mmax ]
  report result
end
;observer> clear-plot set-plot-pen-interval 0.01 set-plot-x-range -0.1 1.1
;observer> histogram n-values 1000000 [ random-normal-in-bounds 0.5 0.2 0 1 ]







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Elle's suggested CODE DUMP !!!

    ;	- Each agent has family ties, coworker ties, and friend ties. This may be done a number of ways: agentsets, links, different link breeds, hypergraph etc. Not sure of the best way. This could also be done outside of agent generation, in a network setup routine.
    ; ELLE - this is now achieved by the generate_clustered_networks procedure, but with much less variability
;    set num-family-ties 1 + random 5
;    set num-coworker-ties 1 + random 10
;    set num-friend-ties 1 + random 10

;  ask turtles [
;    ; n-of size agentset
;    create-family-with n-of num-family-ties other turtles
;    create-coworkers-with n-of num-coworker-ties other turtles
;    create-friends-with n-of num-friend-ties other turtles
;  ]

;  ;4. Report initial network of ties (ties matrix) for output. This would be an adjacency matrix where each tie has a weight from 0 to 1.
;  ;   HOWEVER, right now I'm just trying to get an edge list, which can be made into an adj matrix.
;
;  ; TODO: This is frustrating as hell.
;
;  ; taken from https://stackoverflow.com/a/44568348/10405322 and modified
;  ; each of these work separately, but I need them together; the link to report its breed AND the turtles at both ends
;  ;print (word [breed] of links)
;
;  ;print ("Try to get the link to report breed AND color:")
;  ;print [(word breed color)] of links
;  ; of can handle multiple variables or more complicated expressions. But trying to nest things breaks down.
;
;  ; Ok now try to get the link to report its breed and its ends
;  ; print (word [ [who] of both-ends breed ] of links)
;  ; nope, doesn't work!
;  ; now try
;  ;print("now try this")
;
;  print [(word [who] of both-ends " " breed)] of links
;
;  print [ map [ t -> [ (word breed " " who) ] of t ] (list end1 end2) ] of links
;
;  ; Then that can be modified to write the edge list to a csv file.
;  ; This works, believe it or not, but it doesn't have the link breed:
;  ; csv:to-file "test.csv" [ [ (word breed " " who) ] of both-ends ] of links
;
;  ; This DOES NOT work.
;  ; csv:to-file "test.csv" [(word [who] of both-ends " " breed)] of links
;
;  ; TODO: create slider for this num-interactions


; show (list [(word "turtle:" who " " opinion)] of turtles )


    ;; !!!FrK: Now the opinion is generated from 0 to 99,
    ;; !!!FrK: if we want -50 to +50 we need code 'set opinion -50 + random 101', since 'random 101' generates integers from 0 to 100.
    ;; !!!FrK: But because of color palette we need to stay on 0--100, se then 'set opinion random 101'.
    ;; !!!FrK: I know how my comments my look like, in Czech we say these people 'hnidopich' which means 'flea hunter' :-),
    ;; !!!FrK: BUT we easily might produce an artifact by this slight asymetry, in very ballanced scenario might big clusters happen
    ;; !!!FrK: near the 0 since the symetrically oposite value taken for granted 100 would be missing.
    ; Stan: Ah yes, good catch on the range not including the ending integer!
    ; The opinion was set to 0 to 100 to be lazy for the first draft and show some coloring options.
    ; We can really use whatever, and modifying the color and visualization code to match shouldn't be a problem.

    ;; !!!FrK: Be aware that this code might lead with probability 0.002 to situation that some agent will have no links,
    ;; !!!FrK: now it is not the serious problem since we test model with 20 turtles/agents, but on larger experiment runtime error will happen for sure.
    ;; !!!FrK: Problem is that code 'random 5' generates integers from 0 to 4, 'random 10' from 0 to 9.
    ;; !!!FrK: Solution might be code '1 + random 5' which generates random integers from 1 to 5, or
    ;; !!!FrK: to check if every turle/agent has at least one link and in case it has no links,
    ;; !!!FrK: then randomly choose which type of link we creates for this agent and then create this link.
    ;; !!!FrK: We maight also decide that in case of 'family' we will go for '1 + random 5',
    ;; !!!FrK: since we assume that every agent has to have at least one family relative,
    ;; !!!FrK: and the rest of the code we let as it is, since we let agents have no job and no friends.
    ;; !!!FrK: Last solution that comes to my mind is to parametrize the minima:
    ;; !!!FrK: we create sliders 'min-family' 'min-coworker' 'min-frind' and the code we change to 'min-family + random 5' etc.,
    ;; !!!FrK: but this probably also would lead to demand parametrize maxima,
    ;; !!!FrK: so we will end up with something like 'min-family + random (max-family - min-family + 1)' and things would get more and more complicated...
    ;; !!!FrK: And we would like to keep it simple, right? Yes, I'm not the right person for this sentence :-)
    ; Stan: I am not sure having some very small probability of agents having no links is a problem?
    ; There are some people in the world who are very socially isolated, even without family connection, but it is rare.
    ; If a later version of the model has people meet new people once in a while (which it should, I think) it will be a feature not a bug.
    ;; !!!FrK: Right! We have to be carefully of division by zero with these lone agents, and for the future devolopement it's a promising feature, when the rules allow create new links.
    ;; !!!FrK: We have also carefully pick out interactions from existing links, since this code produces error: 'n-of 5 range 3',
    ;; !!!FrK: which means that if we ask for more interactions in 'go' than agent has links, then we receive error.
    ;; !!!FrK: No we ask constantly for 2 interactions, so turtles with 0 or 1 link only are real problem now.
    ;; !!!FrK: But you wisely changed code that each agent has at least 3 links and we ask just for 2, so we are safe now and
    ;; !!!FrK: in the future we find a way how to get around this problem/bug/feature.



@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
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
0
0
1
ticks
30.0

BUTTON
21
28
76
61
setup
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

SLIDER
21
70
193
103
number-of-agents
number-of-agents
20
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
137
28
192
61
go
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
21
105
193
138
agent-tolerance
agent-tolerance
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
657
38
830
71
transparency
transparency
0
255
255.0
1
1
NIL
HORIZONTAL

TEXTBOX
660
19
797
37
Link transparency
11
0.0
1

SWITCH
658
79
766
112
verbose?
verbose?
1
1
-1000

PLOT
657
184
857
334
Mean opinion
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [opinion] of turtles"

BUTTON
79
28
134
61
go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
658
115
821
148
make-adj-matrices?
make-adj-matrices?
1
1
-1000

CHOOSER
21
144
159
189
opinion-distribution
opinion-distribution
"uniform" "normal"
0

CHOOSER
22
193
192
238
network-groups-sizes
network-groups-sizes
"fam4 work20 friend10" "size drawn from dists" "random"
0

CHOOSER
921
28
1127
73
decision_rule
decision_rule
"trial_run" "weighdiff_sigweight"
1

TEXTBOX
923
10
1073
28
Decision rule in play
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
<experiments>
  <experiment name="output_test_3-ties-adj-matrices-and-opinions" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>matrix:to-row-list family-ties-m</metric>
    <metric>matrix:to-row-list coworker-ties-m</metric>
    <metric>matrix:to-row-list friend-ties-m</metric>
    <metric>(list [(word "turtle:" who " " opinion)] of turtles )</metric>
    <enumeratedValueSet variable="number-of-agents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-tolerance">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="transparency">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="make-adj-matrices?">
      <value value="true"/>
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
0
@#$#@#$#@
