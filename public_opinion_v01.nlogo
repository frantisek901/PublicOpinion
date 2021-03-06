extensions [ palette csv nw matrix ]

globals [ num-agent num-interactions ]

turtles-own [
  opinion
  tolerance
  family-size
  family-ties
  coworker-ties
  friend-ties
  num-family-ties
  num-coworker-ties
  num-friend-ties
  my-interactions
]

links-own [ weight ]

undirected-link-breed [family family-member]
undirected-link-breed [coworkers coworker]
undirected-link-breed [friends friend]

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

  ;2. Generate agents.
  ;	- Number of agents from interface control.

  create-turtles number-of-agents [

    ;	- Each agent has an opinion. Value from -50 to 50, say.
    ;    set opinion -50
    ;    set opinion opinion + random 100
    set opinion random 100
    ;; !!!FrK: Now the opinion is generated from 0 to 99,
    ;; !!!FrK: if we want -50 to +50 we need code 'set opinion -50 + random 101', since 'random 101' generates integers from 0 to 100.
    ;; !!!FrK: But because of color palette we need to stay on 0--100, se then 'set opinion random 101'.
    ;; !!!FrK: I know how my comments my look like, in Czech we say these people 'hnidopich' which means 'flea hunter' :-),
    ;; !!!FrK: BUT we easily might produce an artifact by this slight asymetry, in very ballanced scenario might big clusters happen
    ;; !!!FrK: near the 0 since the symetrically oposite value taken for granted 100 would be missing.
    set color palette:scale-gradient [[ 255 0 0 ] [ 255 255 255 ] [0 0 255]] opinion 0 100

    ;	- Each agent has a tolerance for other opinions. Allowed distance of another agents' opinion, e.g. 20. This can be used for deciding on whether to strengthen or weaken a tie.

    set tolerance agent-tolerance

    ;	- Each agent has family ties, coworker ties, and friend ties. This may be done a number of ways: agentsets, links, different link breeds, hypergraph etc. Not sure of the best way. This could also be done outside of agent generation, in a network setup routine.

    set num-family-ties random 5
    set num-coworker-ties random 10
    set num-friend-ties random 10
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

    ;set color opinion

  ]

  ; put them in a circle with radius value
  layout-circle turtles 12

  ;3. Generate initial network
  ;	- However makes sense
  ; First we'll try using NetLogo's links, which are actually agents. This may end up a mess, but in THEORY it should make things easier.


  ; !!!Elle: here is a method where links are set up first, then adjacency matrix is updated  
  
  ; 1. turtles create ties randomly
  ask turtles [
    let family_list  ( [who] of n-of num-family-ties other turtles)        ; returns a list of the ids for each turtles "family" 
    foreach family_list [                                                  ; looping through a list is unneccesary now, but will allow us to 
      i -> create-family-member-with turtle i [ set weight 1 ]             ; easily generate different weights for each tie in the future
    ]
    let coworker_list ( [who] of n-of num-coworker-ties other turtles)
    foreach coworker_list [                                                ; I really should turn this into a function...
      i -> create-coworker-with turtle i [ set weight 1 ]              
    ]
    let friend_list ( [who] of n-of num-friend-ties other turtles)
    foreach friend_list [
      i -> create-friend-with turtle i [set weight 1 ] 
    ] 
  ]
  
  ;2. matrices are initialised for storage 
  set family-ties-m matrix:make-constant number-of-agents number-of-agents 0         ; empty num-agent * num-agent adjacency matrix to store family ties 
  set coworker-ties-m matrix:make-constant number-of-agents number-of-agents 0
  set friend-ties-m matrix:make-constant number-of-agents number-of-agents 0
  
  ;3. matrices are filled with information from the links 
  ; !!! Elle -  I would move this to a subprocedure (e.g., to fill_matrix) because we are going to use it again in go 
  let list_turtles n-values number-of-agents [i -> i]           ; create an ordered list of turtles to loop through 
  foreach list_turtles [
    i -> 
    let me item 0 [who] of turtles with [who = i]               ; returns agent i's id #
    foreach list_turtles [
      j -> 
      let you item 0 [who] of turtles with [who = j]            ; returns agent j's id # 
      if i != j [                                               ; avoid error when turtles try to evaluate self  
        nw:set-context turtles family
        ask turtle me [
          if family-member-neighbor? turtle you = true   [              ; if i and j are family 
            let tie_strength [weight] of (family-member me you)         ; get the weight of the tie 
            matrix:set family-ties-m me you tie_strength                ; update relevant cell in family-ties-m with weight 
          ]
         nw:set-context turtles coworkers 
          ask turtle me [
          if coworker-neighbor? turtle you = true   [                   ; if i and j are coworkers 
            let tie_strength [weight] of (coworker me you)              ; ... ... ... 
            matrix:set coworker-ties-m me you tie_strength               
            ]
          ]
          nw:set-context turtles friends 
          ask turtle me [
            if friend-neighbor? turtle you = true   [                   ; finally, if i and j are friends     
            let tie_strength [weight] of (friend me you)
            matrix:set friend-ties-m me you tie_strength   
            ]
          ] 
        ]          
      ]
    ]
  ]
  ; uncomment to confirm this ^ works 
;  print matrix:pretty-print-text family-ties-m 
;  print matrix:pretty-print-text coworker-ties-m
;  print matrix:pretty-print-text friend-ties-m 
  


; !!! elle - following code is encapsulated in ^ 
;  ask turtles [
;    ; n-of size agentset
;    create-family-with n-of num-family-ties other turtles
;    create-coworkers-with n-of num-coworker-ties other turtles
;    create-friends-with n-of num-friend-ties other turtles
;  ]

  ask n-of 10 family [ set color yellow]
  ask n-of 10 coworkers [ set color green]
  ask n-of 10 friends [ set color blue]
  ;; !!!FrK: I don't understand this. This and the following code means that
  ;; !!!FrK: some links will color twice to the same color.
  ;; !!!FrK: I am very bad in coloring, this is may be some trick, so please explain,
  ;; !!!FrK: what opportunity it gives us to color 'n-of 10' links twice.

  ask family [ set color yellow]
  ask coworkers [ set color green]
  ask friends [ set color blue]

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

  ;4. Report initial network of ties (ties matrix) for output. This would be an adjacency matrix where each tie has a weight from 0 to 1.
  ;   HOWEVER, right now I'm just trying to get an edge list, which can be made into an adj matrix.

  ; TODO: This is frustrating as hell.

  ; taken from https://stackoverflow.com/a/44568348/10405322 and modified
  ; each of these work separately, but I need them together; the link to report its breed AND the turtles at both ends
  ;print (word [breed] of links)

  ;print ("Try to get the link to report breed AND color:")
  ;print [(word breed color)] of links
  ; of can handle multiple variables or more complicated expressions. But trying to nest things breaks down.

  ; Ok now try to get the link to report its breed and its ends
  ; print (word [ [who] of both-ends breed ] of links)
  ; nope, doesn't work!
  ; now try
  ;print("now try this")

  print [(word [who] of both-ends " " breed)] of links

  print [ map [ t -> [ (word breed " " who) ] of t ] (list end1 end2) ] of links

  ; Then that can be modified to write the edge list to a csv file.
  ; This works, believe it or not, but it doesn't have the link breed:
  ; csv:to-file "test.csv" [ [ (word breed " " who) ] of both-ends ] of links

  ; This DOES NOT work.
  ; csv:to-file "test.csv" [(word [who] of both-ends " " breed)] of links

  ; TODO: create slider for this num-interactions
  set num-interactions 2

  reset-ticks
  ;; !!!FrK: Sorry for touching the code, but without this initialization I can't play with data pipeline.

end

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
  ask turtles [ rt 45 ]

  ;1. Each agent chooses (default random, build in moral circle / parochial prefs here) some agents in its network to interact with, writes those choices to a current-tick all-agents-interactions adjacency matrix (interaction matrix, for short). (Btw a tick is Netlogo term for one loop through the go routine.)

  ask turtles [
    ; I'm just using the variable from the setup right now, but turtles could have differing interaction numbers in the future

    set my-interactions n-of num-interactions my-links
    print [ [(word breed " " who)] of other-end ] of my-interactions
    print [ (word other-end) ] of my-interactions


  ]


  ;2. The interaction matrix is reported in some way to get written as an output in behaviorspace (we'll explain behaviorspace later). We can also calculate some network stat here to plot in the interface if we care to.
  ;3. Iterate through the interaction matrix so that each agent
  ;	- "interacts" with the agents in its row, using its own opinion and tolerance to upweigh or downweigh the tie with each agent. (devil is in the mechanic here, we have options)
  ;4. Output new ties matrix for writing to table/file, polarization stats.
  ;5. Check if ties matrix has changed, if not maybe we can stop.
  ;6. New tick (loop to beginning of go to do it all over again)

  tick
  ;; !!!FrK: Sorry for touching the code, but without this initialization I can't play with data pipeline.

end
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
28
34
91
67
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
20.0
1
1
NIL
HORIZONTAL

BUTTON
98
33
161
66
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
90.0
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
