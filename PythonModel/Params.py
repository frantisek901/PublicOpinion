"""
    This script has the parameters of the model.
-------------------------------------------------------------------------------
created on:
    Thu 3 Mar 2022
-------------------------------------------------------------------------------
last change:
    Thu 17 Mar 2022
-------------------------------------------------------------------------------
notes:
-------------------------------------------------------------------------------
contributors:
    Jose:
        name:       Jose Betancourt
        email:      jose.betancourtvalencia@yale.edu
-------------------------------------------------------------------------------
"""
# General parameters
N_agents = 100
N_layers = 3
T = 100

# Initial network parameters
avg_members = [4, 2, 8]
init_weight = [.5, .5, .5]
p_link = [1., .8, .8]
p_main_gang = .8

# Opinion distribution parameters
sigma = 2
op_low = 0.
op_high = 1.

# Updating parameters
layer_prob = [1/3, 1/3, 1/3]
tol_low = -0.1
tol_high = 0.1