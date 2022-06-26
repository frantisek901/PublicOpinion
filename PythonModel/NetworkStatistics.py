"""
    This script calculates various network metrics for a directed weighted
    network.
-------------------------------------------------------------------------------
created on:
    Thu 23 Jun 2022
-------------------------------------------------------------------------------
last change:
    Sun 26 Jun 2022
-------------------------------------------------------------------------------
notes:
-------------------------------------------------------------------------------
contributors:
    Jose:
        name:       Jose Betancourt
        email:      jose.betancourtvalencia@yale.edu
-------------------------------------------------------------------------------
"""
import numpy as np

def freeman_index(links, weights, opinions):
    '''
    Calculates the Freeman segregation index (Feeman, 1978) for a given 
    network and set of opinions.

    Parameters
    ----------
    links : array[int, int]
        Unweighted adjacency matrix.
    weights : array[float, float]
        Weights of network links.
    opinions : array[float]
        Opinions of the agents.

    Returns
    -------
    None.

    '''