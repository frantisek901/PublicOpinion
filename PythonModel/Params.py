"""
    This script has the parameters of the model.
-------------------------------------------------------------------------------
created on:
    Sun 16 Jan 2022
-------------------------------------------------------------------------------
last change:
    Wed 26 Jan 2022
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
N_groups = 3
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