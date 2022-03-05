"""
    This script has the parameters of the model.
-------------------------------------------------------------------------------
created on:
    Thu 4 Mar 2022
-------------------------------------------------------------------------------
last change:
    Fri 5 Mar 2022
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

# Distributional parameters
sx = 10
sy = 10

# Payoff parameters
eps = 0.025
beta = 0.1

def f(x):
    '''
    This is the fitness function.
    '''
    return 1