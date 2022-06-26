"""
    This script calculates opinion and network segregation statistics.
-------------------------------------------------------------------------------
created on:
    Sat 21 May 2022
-------------------------------------------------------------------------------
last change:
    Sat 21 May 2022
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
# import networkx as nx

def freeman_index(opinions, network):
    '''
    Computes the Freeman segregation index (Freeman, 1978) for a given network
    and set of opinions.

    '''
    # Classify individuals into groups
    low_op = np.where(opinions <= 0.5)[0]
    high_op = np.where(opinions >  0.5)[0]
    # Symmetrize and unweight matrix
    network += network.T
    network = (network!=0)+0
    # Calculate relevant quantities
    n_people = len(opinions)
    n_high = len(high_op)
    n_edges = np.sum(network)
    # Calculate E(e)
    E_e = n_edges*2*n_high*(n_people-n_high)/(n_people*(n_people-1))
    # Calculate outgroup interactions
    n_out = 0
    for i in low_op:
        for j in high_op:
            n_out += network[i,j]
    # Calculate S
    s = max(E_e-n_out, 0)
    return s/E_e

def spectral_index(opinions, network):
    '''
    Calculates the spectral segregation index (Echenique and Fryer, 2007) for 
    a given network and set of opinions.

    '''
    return 0

def avg_degree(network):
    '''
    Calculates the average number of connections individuals have in the 
    network.

    Parameters
    ----------
    network : array[float, float]
        Tie strength of individuals in the network.

    Returns
    -------
    avg_deg : float
        Average degree of hte network.

    '''
    # Obtain the unweighted network
    network = (network!=0)+0
    # Calculate average degree
    avg_deg = np.mean(np.sum(network, axis=1))
    return avg_deg


def avg_srength(network):
    '''
    Calculates the average tie strength of active ties in the network.

    Parameters
    ----------
    network : array[float, float]
        Tie strength of individuals in the network.

    Returns
    -------
    avg_strength : float
        Average degree of hte network.

    '''
    # Obtain the unweighted network and total active links
    uwt_network = (network!=0)+0
    n_links = np.sum(uwt_network)
    # Calculate average tie strength
    avg_strength = np.sum(network)/n_links
    return avg_strength

# LINK AGE



















