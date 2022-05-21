"""
    This script analyzes the output from the knoledge commons ABM
-------------------------------------------------------------------------------
created on:
    Thu 17 Mar 2022
-------------------------------------------------------------------------------
last change:
    Thu 19 May 2022
-------------------------------------------------------------------------------
notes:
-------------------------------------------------------------------------------
contributors:
    Jose:
        name:       Jose Betancourt
        email:      jose.betancourtvalencia@yale.edu
-------------------------------------------------------------------------------
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

plt.rcParams.update({
    "text.usetex": True,
    "font.family": "serif",
    "font.serif": ["Garamond"],
    "font.size": 15,
})

# Load statistics
data = pd.read_parquet('Stats.parquet')

# Get simulation duration
T = data['t'].max()
t_vals = np.arange(T+1)

def plot_opinion_stats():
    '''
    Generates plots of the opinion statistics of agents.

    '''
    # Get average statistics
    mu_avg = data.groupby('t').mean_op.mean()
    std_avg = data.groupby('t').std_op.mean()
    # Plot mean
    plt.plot(t_vals, mu_avg, lw=2, c='b')
    plt.ylim([0,1])
    plt.xlabel('$t$')
    plt.ylabel('$\langle \mu \\rangle$')
    plt.savefig('../Figures/Mean.png', dpi=600, bbox_inches='tight')
    plt.show()
    # Plot std
    plt.plot(t_vals, std_avg, lw=2, c='b')
    plt.ylim([0,1])
    plt.xlabel('$t$')
    plt.ylabel('$\langle \sigma \\rangle$')
    plt.savefig('../Figures/Std.png', dpi=600, bbox_inches='tight')
    plt.show()
    
def plot_network_stats():
    '''
    Generates plots of the network segregation measures of agents' different
    interactions.

    '''
    # Get average statistics
    fsi_family = data.groupby('t').fsi_family.mean()
    fsi_friends = data.groupby('t').fsi_friends.mean()
    fsi_work = data.groupby('t').fsi_work.mean()
    # Plot FSI
    plt.plot(t_vals, fsi_family)
    plt.plot(t_vals, fsi_friends)
    plt.plot(t_vals, fsi_work)
    plt.ylim([0,1])
    plt.xlabel('$t$')
    plt.ylabel('FSI')
    plt.savefig('../Figures/FSI.png', dpi=600, bbox_inches='tight')
    plt.show()