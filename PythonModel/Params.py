"""
    This script has the parameters of the model.
-------------------------------------------------------------------------------
created on:
    Thu 3 Mar 2022
-------------------------------------------------------------------------------
last change:
    Sat 6 Mar 2022
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

# Payoff parameters
eps = 0.025
beta = 0.1

def f(x):
    '''
    This is the fitness function.
    '''
    return 1

# num-agent
# num-interactions
# family-ties-m
# coworker-ties-m
# friend-ties-m
# interactions-family-m
# interactions-coworkers-m
# interactions-friends-m