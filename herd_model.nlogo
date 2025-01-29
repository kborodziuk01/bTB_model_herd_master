extensions [
  time
  csv
  profiler] ; model uses the time extension for scheduling of the events

globals [
  current-time
  current-hour
  l_food_patches
  r_food_patches
  mid_patch
  events-list
  current-event
  _1st_feed
  _2nd_feed
  left_milk
  right_milk
  left_robots
  right_robots
  max_Ec
  total_concentration
  days_since_test
  dry_box
  not-dry-cows
  l-mov
  r-mov
  l_food_place
  r_food_place
  exposed_cows
  infectious_cows
  h_inf
  tested_count
  positive_count
  negative_count
  run-test-list
  t

  ;INFECTION Parameters
  mu
  phi
  beta_cc
  inf_patches


 ]

breed [ cows cow] ; create an agent bread for cows
breed [ robots robot] ; create an agent bread for robots

cows-own [
  side
  hunger
  milking_need
  status
  time_to_stop_milk
  dry?
  time_to_milk
  incubation
  time_since_infection
  age
  time_since_exposed
  ]

patches-own [
  food_amount
  Ec
  inf_before?]



robots-own [
  max-uses-ph
  used-this-hour
  time_since_clean]


;#####################
;###  Report setup ###
;#####################

to write_rep

  file-open "my-file-in.txt"
  file-write (word
    "dd_" duration_dry
    "_te_"  time_exposed
    "_nif_"  num_infected_init
    "_ny_" num_young
    "_HT_" hunger_treshold
    "_fph_" food_per_h
    "_mnt_" milking_need_tresh
    "_ffm_" food_from_milker
    "_hph_" hunger_per_h

    run-test-list)
  file-close
end

to write_inf_map

  file-open "map list.txt"
  file-write (word
    "dd_" duration_dry
    "_te_"  time_exposed
    "_nif_"  num_infected_init
    "_ny_" num_young
    "_HT_" hunger_treshold
    "_fph_" food_per_h
    "_mnt_" milking_need_tresh
    "_ffm_" food_from_milker
    "_hph_" hunger_per_h

    inf_patches)
  file-close

end







to setup
  no-display
  ca ;clear all


  ;#####################
  ;####  Time Setup  ###
  ;#####################

  set current-time time:create "2018-01-01 00:00:00" ; start date
  set current-hour 0
  set h_inf  time_exposed * 24

  set events-list read-event-csv "events2018-2024.csv"

  set current-event item 0 events-list

  set _1st_feed 7
  set _2nd_feed 18


  set days_since_test 0

  set t 0


  reset-ticks

  set run-test-list []
  set inf_patches []


  ;#############################
  ;####  Environment  Setup  ###
  ;#############################
  ;dry section setup
  ask patches [ set pcolor black
  set inf_before? False]

  let py_lim -31
  if Dry_box_on[

    set py_lim -26
    set dry_box patches with [pycor < -25]
    ask dry_box [

      set pcolor white
    ]
      ask patches with [pycor = -26] [set pcolor red]
  ]

  set l-mov patches with [pycor <= 30 and pycor >= -25  and pxcor >= -30 and pxcor <= -2]

  set r-mov patches with [pycor <= 30 and pycor >= -25  and pxcor <= 30 and pxcor >= 2]

  set l_food_patches patches with [pxcor = -1 and pycor > py_lim]  ; create an agent set of all patches at x coordinate range -1 - 1. a vertical line down the middle
  set r_food_patches patches with [pxcor =  1 and pycor > py_lim]  ; create an agent set of all patches at x coordinate range -1 - 1. a vertical line down the middle

  set l_food_place patches with [pxcor = -2 and pycor > py_lim]
  set r_food_place patches with [pxcor = 2 and pycor > py_lim]


  set mid_patch patches with [pxcor = 0 and pycor > py_lim]
  ask mid_patch [ set pcolor gray]
  ask l_food_patches [set pcolor red] ; color the vertical line red for visual clarity
  ask r_food_patches [set pcolor red]



  ;######################
  ;####  Robot Setup  ###
  ;######################


  ; create 4 milking robots size 4 and color yellow
  create-robots 4 [

    set size 4
    set color yellow

    set max-uses-ph 10
    set used-this-hour 0
  ]


  let pat (patch-set patch -29 -15 patch -29 15 patch 29 -15 patch 29 15) ; set and patch-set of 4 patches at predetermined locations

  set left_milk (patch-set patch -29 -15 patch -29 15)
  set right_milk (patch-set patch 29 -15 patch 29 15)




  ; move the robots each to one of the predetermined locations. robots are placed randomly in one of the locations. if there already is another robot here,
  ; the operation repeates untill each of the 4 robots ocupy an unique location.
  ask robots [

    move-to one-of pat
    while [any? other robots-here] [
      move-to one-of pat]


    ask neighbors[ set pcolor yellow]
  ]
  set left_robots robots-on left_milk
  set right_robots robots-on right_milk

  ;#####################
  ;####  Cows Setup  ###
  ;#####################




  spawn_cows num_cows - num_young false 2000
  spawn_cows num_young true 720




  set not-dry-cows cows with [dry? = false]


  init_infect


  set tested_count 0
  set positive_count 0
  set negative_count 0




  ;#######################
  ;### Infection setup ###
  ;#######################


  set mu 0.0001625

  set phi 2
  set beta_cc 4.208333333333333e-07


end







to spawn_cows [ num_cows_create age-random? age-var]
  create-cows num_cows_create[

    set shape "cow"
    set size 3


    ; randomly assign each cow to the "left" and "right" side. color them for clarity and move to within th ebounding boxes of the left and right side of the environment.
    ifelse random-float 1 > 0.5[
      set side "right"
      move-to patch (30 - random 29) (-25 + random 55)
      set color blue

    ]
    [
      set side "left"
      move-to patch  (-30 + random 29)  (-25 + random 55)
      set color green
    ]

    set hunger 0
    set  milking_need 0
    set status "Healthy"
    set dry? false
    set time_to_stop_milk  random 300

    ifelse age-random? = true
    [set age random age-var]
    [set age age-var]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                            END OF SETUP                            ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;######################################
;### Infection supporting functions ###
;######################################


to calc_decay

  let Ic count cows-here with [status = "Infectious"]

  ifelse Ec = 0 and Ic = 0
  []
  [set Ec Ec + (phi * Ic) - (mu * Ec) ]

end

to calc_prob
  let exponent 0
  let Nc count turtles-on dry_box

  ifelse dry? = true
  [
    set exponent  ((beta_cc * (Ec / Nc))) * -1

  ]
  [
      set exponent  (beta_cc * Ec) * -1
    ]



  let exponent2 exp exponent
  let probability 1 - exponent

  ;if c > 0.001[ show c]

  if random-float 1 < probability
  [infect]

end

to infect

  set status "Exposed"
  set color yellow
  set time_since_exposed 0
  set inf_patches  lput patch-here inf_patches

end

to init_infect

  ask n-of  num_infected_init cows [

    set color yellow
    set status  "Exposed"]



end

to progress_inf

  ask exposed_cows[

    set time_since_exposed time_since_exposed + 1

   if time_since_exposed >= h_inf[
    set color red
      set status "Infectious"]]




end


to dry_infect

  let dry_turtles turtles-on dry_box


  let Ic count dry_turtles with [status = "Infectious"]

  let _Ec [Ec] of one-of dry_box




  let a phi * Ic
  let b mu * _Ec
  let c  a - b
  let d _Ec + c


  ask dry_box[ set Ec d ]

end

;###################
;###   Main Go   ###
;###################


to go


  ;########################
  ;####  Hourly Events  ###
  ;########################


  set current-time time:plus current-time 1 "hour"
  set current-hour current-hour + 1

  ask not-dry-cows[


    set hunger hunger  + hunger_per_h
    if random 100 < 33
    [cow_move]
    cow_milking
    cow_food_stuff

  ]


  ask robots[
    set max-uses-ph 10]

  if time:is-after? current-time (first current-event) [
    ; Perform the action for this event
    ;show (word "event in: " item 1 current-event " event out: " item 2 current-event)
    perform-movement-event(current-event)

    ; Remove the current event and move to the next one
    set events-list but-first events-list
    set current-event item 0 events-list

  ]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;  comented out for speed   ;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  ask patches[
;    set pcolor scale-color pink Ec 0 2000]
;  ask l_food_patches [set pcolor red] ; color the vertical line red for visual clarity
;  ask r_food_patches [set pcolor red]


  if current-hour = _1st_feed
  [feed

  ]


  if current-hour = _2nd_feed
  [feed
  ]




  ;Do last each hour before daily tasks.

  let non_dry_patch patches who-are-not dry_box

  ask non_dry_patch [ calc_decay]
  ask cows with [status = "Healthy"][ calc_prob]
  dry_infect


  set exposed_cows cows with [status = "Exposed"]
  progress_inf
  set infectious_cows cows with [status = "Infectious"]




  ;#######################
  ;####  Daily Tasks   ###
  ;#######################

  if current-hour = 24 [
    set days_since_test days_since_test + 1
    set current-hour 0

    if Dry_box_on[
      ask cows[dry]]


    set not-dry-cows cows with [dry? = false]


    ask cows [

      set age age + 1 ]

    clean_milker
      tick



    if ticks >= 2423 [ stop]


    if tested_count > 0[

      set tested_count 0
      set positive_count 0
      set negative_count 0

    ]


  ]


  ;##########################
  ;####  Every 6 months   ###
  ;##########################


  if days_since_test >= 182
  [
    skin_test
    set days_since_test 0

  ]
end


to reset_profile
    profiler:stop          ;; stop profiling
    print profiler:report  ;; view the results
    profiler:reset

end


to dry

  set time_to_stop_milk time_to_stop_milk - 1


  if time_to_stop_milk <= 0 and not dry?
  [

    move-to one-of dry_box
    set dry? true
    set time_to_milk duration_dry

  ]


  if dry? = true [

    set time_to_milk time_to_milk - 1



    if time_to_milk <= 0[

      set dry? false
      set time_to_stop_milk 300

      ifelse side = "left"
      [move-to patch  (-30 + random 29)  (-25 + random 55)]
      [move-to patch (30 - random 29) (-25 + random 55)]
      set hunger 0

  ]]

end





to clean_milker

  let choice clean_frequency



  if clean_frequency = "1 Week"
  [
    ask robots[
      set time_since_clean time_since_clean + 1

      if  time_since_clean > 7
      [

        set Ec 0
        ask neighbors [ set Ec 0]

        ;clean

       set time_since_clean 0
      ]


  ]


    ask l_food_place[
      set Ec 10
    ]

    ask r_food_place[
      set Ec 10
    ]

  ]

  if clean_frequency = "1 Month"
  [

      ask robots[
      set time_since_clean time_since_clean + 1

      if  time_since_clean > 30
      [

        set Ec 0
        ask neighbors [ set Ec 0]

        ;clean

       set time_since_clean 0
      ]


    ]

    ask l_food_place[
      set Ec 10
    ]
    ask r_food_place[
      set Ec 10
    ]




  ]

  if clean_frequency = "Daily"
  [


      ask robots[
      set time_since_clean time_since_clean + 1

      if  time_since_clean > 1
      [

        set Ec 0
        ask neighbors [ set Ec 0]

        ;clean

       set time_since_clean 0
      ]

  ]

  ]

end


to feed


  ask l_food_place [
    set food_amount food_amount + 40
    if food_amount > 100[set food_amount 100]
  ]

  ask r_food_place [
    set food_amount food_amount + 40
    if food_amount > 100[set food_amount 100]
  ]

end

to cow_milking

    set milking_need milking_need + ( 8 + random 8)

    if milking_need > milking_need_tresh
    [

      ;GET MILKED
      ifelse side = "left"
      [
        let pick_robot one-of left_robots with [max-uses-ph >  0]
        ifelse pick_robot = nobody [][
          move-to one-of [neighbors] of pick_robot
          ask pick_robot[
            set max-uses-ph max-uses-ph - 1]
          set milking_need 0
          set hunger hunger - food_from_milker
          ;move-to one-of l-mov

        ]
      ]
      [
        let pick_robot one-of right_robots with [max-uses-ph > 0]
        ifelse  pick_robot = nobody [][
          move-to one-of [neighbors] of pick_robot
          ask pick_robot[
            set max-uses-ph max-uses-ph - 1]
          set milking_need 0
          set hunger hunger - food_from_milker
          ;move-to one-of r-mov
        ]
      ]

    ]

end

to cow_move

  ifelse side = "left"
  [move-to one-of l-mov]
  [move-to one-of r-mov]


end

to cow_food_stuff



  if hunger >= hunger_treshold
  [
   let p 0

  ifelse side = "left"
    [ set p one-of l_food_place]
    [ set p one-of r_food_place]



    move-to p

    set hunger hunger - food_per_h
    ask p [ set food_amount food_amount - 40]
;    ifelse side = "left"
;    [move-to one-of l-mov]
;    [move-to one-of r-mov ]

  ]




end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; SKIN TESTING  ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to skin_test


  let total_test cows with [age >= 360]
  set tested_count count total_test

  ask total_test
  [
    if status !="Healthy" and random-float 100 < skin_test_SE  [
      set positive_count positive_count + 1
      die


    ]


  ]


  set negative_count tested_count - positive_count


  set run-test-list lput (list ticks tested_count negative_count positive_count) run-test-list

end


to perform-movement-event [event-data]

  let e_in item 1 event-data
  let e_out item 2 event-data


  if e_in > 0[


    ifelse random-float 1 < 0.95
    [spawn_cows e_in true 0]
    [spawn_cows e_in false 0]



    ]

  if e_out > 0 [kill_cows e_out]

end


to-report read-event-csv [filename]
  let csv-content csv:from-file filename
  let parsed-events []

  ;show csv-content

  foreach csv-content [
    row ->
    let event-date time:create item 0 row ; first column is the dat
    let event-data-in item 1 row ; second column is the events in
    let event-data-out item 2 row ; second column is the event-out

    set parsed-events lput (list event-date event-data-in event-data-out) parsed-events
  ]

  report parsed-events
end

to kill_cows [num_to_kill]

  ask n-of num_to_kill cows[die]

end
@#$#@#$#@
GRAPHICS-WINDOW
400
10
955
566
-1
-1
8.97
1
10
1
1
1
0
0
0
1
-30
30
-30
30
0
0
1
ticks
30.0

BUTTON
0
112
85
145
Go 1 Hour
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

BUTTON
0
10
63
43
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

SLIDER
103
12
275
45
num_cows
num_cows
200
600
544.0
1
1
NIL
HORIZONTAL

BUTTON
0
44
89
77
Go Forever
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
103
49
275
82
num_infected_init
num_infected_init
0
50
5.0
1
1
NIL
HORIZONTAL

SLIDER
1
254
99
287
food_per_h
food_per_h
1
40
31.0
1
1
NIL
HORIZONTAL

SLIDER
0
287
172
320
hunger_treshold
hunger_treshold
0
95
80.0
1
1
NIL
HORIZONTAL

SLIDER
0
320
172
353
milking_need_tresh
milking_need_tresh
0
100
89.0
1
1
NIL
HORIZONTAL

SLIDER
0
357
172
390
food_from_milker
food_from_milker
0
25
17.0
1
1
NIL
HORIZONTAL

SLIDER
0
394
172
427
hunger_per_h
hunger_per_h
0
50
9.0
1
1
NIL
HORIZONTAL

BUTTON
0
144
85
177
Go 1 Day
repeat 24 [go]
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
0
177
84
210
Go 1 Month
repeat 720 [go]
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
967
298
1095
331
skin_test_SE
skin_test_SE
50
100
83.2
0.1
1
NIL
HORIZONTAL

SLIDER
967
261
1091
294
Skin_test_SP
Skin_test_SP
99.99
99.99
99.99
0.01
1
NIL
HORIZONTAL

SWITCH
967
159
1081
192
dry_box_on
dry_box_on
0
1
-1000

BUTTON
965
524
1063
557
NIL
reset_profile
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
964
482
1079
515
profiler
setup\nprofiler:start\nrepeat 7200 [go]\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset \n
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
100
105
272
138
num_young
num_young
0
100
6.0
1
1
NIL
HORIZONTAL

SWITCH
965
72
1074
105
clean_milk
clean_milk
1
1
-1000

CHOOSER
1111
69
1249
114
clean_frequency
clean_frequency
"1 Week" "1 Month" "Daily"
1

SLIDER
0
466
172
499
duration_dry
duration_dry
0
360
60.0
10
1
NIL
HORIZONTAL

SLIDER
0
507
172
540
time_exposed
time_exposed
1
650
46.0
1
1
NIL
HORIZONTAL

BUTTON
1278
280
1360
313
NIL
write_rep
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
1277
333
1385
366
NIL
write_inf_map\n
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
1279
20
1506
305
Reporting Funtions.\n\nCan be used when the run has finished.\n\nwrite_rep - outputs a document with all skin test results from the run. each record has a label with run parameters as well as 9-10 result lists with following fields\n[total_tested, Negative,Positive] \n\nwrite_inf_map - outputs a document holiding all patches where cows got infected. each run produces a lable with run parameters as well as a list of patches. this can be imported to a inf_map testing tool to display a heatmap of the infection in the run
12
0.0
1

TEXTBOX
968
426
1118
471
Profiler - to test the execution speed of individual functions
12
0.0
1

TEXTBOX
965
224
1115
254
Sensitivity and Specificity of the skin test
12
0.0
1

TEXTBOX
966
142
1116
160
Separate the \"dry\" cows ?
12
0.0
1

TEXTBOX
967
16
1117
55
Toggle to enable periodic cleaning of the whole barn. Used for testing, off by default
10
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <postRun>write_rep
write_inf_map</postRun>
    <enumeratedValueSet variable="num_young">
      <value value="6"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Skin_test_SP">
      <value value="99.99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dry_box_on">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clean_milk">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clean_frequency">
      <value value="&quot;1 Month&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="milking_need_tresh">
      <value value="89"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration_dry">
      <value value="60"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunger_treshold">
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skin_test_SE">
      <value value="79.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food_per_h">
      <value value="30"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food_from_milker">
      <value value="10"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_infected_init">
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunger_per_h">
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time_exposed">
      <value value="20"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_cows">
      <value value="516"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment (copy)" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <postRun>write_rep
write_inf_map</postRun>
    <enumeratedValueSet variable="milking_need_tresh">
      <value value="50"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="duration_dry">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunger_treshold">
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food_per_h">
      <value value="30"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food_from_milker">
      <value value="10"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_infected_init">
      <value value="5"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunger_per_h">
      <value value="14"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time_exposed">
      <value value="20"/>
      <value value="60"/>
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
