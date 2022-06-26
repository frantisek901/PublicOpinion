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
import networkx as nx
from numba import njit

@njit
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
    index : float
        Freeman segregation index of the network.

    '''
    # Classify individuals into groups
    low_op = np.where(opinions <= 0.5)[0]
    high_op = np.where(opinions >  0.5)[0]
    # Symmetrize and unweight matrix
    links += links.T
    links = (links!=0)+0
    # Calculate relevant quantities
    n_people = len(opinions)
    n_high = len(high_op)
    n_edges = np.sum(links)
    # Calculate E(e)
    E_e = n_edges*2*n_high*(n_people-n_high)/(n_people*(n_people-1))
    # Calculate outgroup interactions
    n_out = 0
    for i in low_op:
        for j in high_op:
            n_out += links[i,j]
    # Calculate S
    s = max(E_e-n_out, 0)
    index = s/E_e
    return index