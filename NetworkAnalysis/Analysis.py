"""
    This script calculates distributional and network measures for the public
    opinion ABM.
-------------------------------------------------------------------------------
created on:
    Tue 25 Jan 2022
-------------------------------------------------------------------------------
last change:
    Tue 25 Jan 2022
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
import pandas as pd
import matplotlib.pyplot as plt

#------------------------------------------------------------------------------
# IMPORT AND PROCESS DATA
#------------------------------------------------------------------------------
fname = '../public_opinion_v01_crazy_links output_test_3-ties-adj-matrices-and-opinions-table.csv'
names = ['run', 'n_agents', 'tolerance', 'transparency', 'adj_or_not', 
         'step', 'fam_adj', 'work_adj', 'friend_adj', 'opinions']

df = pd.read_csv(fname, sep=',', skiprows=7, names=names)