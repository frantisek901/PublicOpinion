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
import networkx as nx

plt.rcParams.update({
    "text.usetex": True,
    "font.family": "serif",
    "font.serif": ["Garamond"],
})

N_layers = 3
layers = ['fam_adj', 'work_adj', 'friend_adj']

#------------------------------------------------------------------------------
# IMPORT AND PROCESS DATA
#------------------------------------------------------------------------------
fname = '../public_opinion_v01_crazy_links output_test_3-ties-adj-matrices-and-opinions-table.csv'
names = ['run', 'n_agents', 'tolerance', 'transparency', 'adj_or_not', 
         'step', 'fam_adj', 'work_adj', 'friend_adj', 'opinions']

df = pd.read_csv(fname, sep=',', skiprows=7, names=names)

def extract_matrix(string):
    '''
    This function obtains an adjacency matrix from the string output given by
    NetLogo.
    '''
    aux = string.replace('[','')
    aux = aux.replace(']','')
    ar1d = np.fromstring(aux, sep=' ')
    dim = int(np.sqrt(len(ar1d)))
    ar2d = np.reshape(ar1d, (dim, dim))
    return ar2d

def extract_opinions(string):
    '''
    This function obtains a vector of opinions from the string output given by
    NetLogo.
    '''
    aux = string.replace('[','')
    aux = aux.replace(']','')
    aux = aux.replace('turtle:','')
    ar1d = np.fromstring(aux, sep=' ')
    dim = len(ar1d)
    ar2d = np.reshape(ar1d, (dim//2, 2))
    return ar2d[ar2d[:,0].argsort()][:,1]

def matrix_history(df, run):
    '''
    This function obtains the matrix history for a given run from the NetLogo
    output.
    '''
    df_aux = df.loc[df['run']==run]
    hist = []
    for i in range(df_aux.shape[0]):
        layer_hist = []
        for layer in layers:
            layer_hist.append(extract_matrix(df_aux[layer].iloc[i]))
        hist.append(layer_hist)
    return np.array(hist)

def opinion_history(df, run):
    '''
    This function obtains the opinion history for a given run from the NetLogo
    output.
    '''
    df_aux = df.loc[df['run']==run]
    hist = []
    for i in range(df_aux.shape[0]):
        hist.append(extract_opinions(df_aux['opinions'].iloc[i]))
    return np.array(hist)

#------------------------------------------------------------------------------
# PLOTTING
#------------------------------------------------------------------------------
net = matrix_history(df,1)
ops = opinion_history(df, 1)

for i in range(30):
    G = nx.from_numpy_matrix(net[i,0])
    edges = G.edges()
    weights = [G[u][v]['weight'] for u,v in edges]
    pos = nx.spring_layout(G)
    nx.draw(G, pos, node_color='b', node_size=300, width=10*weights)
    plt.show()
    
for i in range(30):
    plt.hist(ops[i], density=True, color='b')
    plt.xlim([-100,100])
    plt.ylim([0,0.022])
    plt.xlabel('Opinion')
    plt.ylabel('Density')
    plt.show()