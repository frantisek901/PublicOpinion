"""
    This script has the information for the time iteration of the model.
-------------------------------------------------------------------------------
created on:
    Thu 3 Mar 2022
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
import Params
import Statistics
import numpy as np
import pandas as pd


class Record(object):
    def __init__(self):
        '''
        This function initializes the record.
        '''
        self.stats = []
        
    def get_stats(self, ind, t, agents, network):
        '''
        This function extracts the attributes from a set of agents and 
        calculates segregation indices.
        
        '''
        # Get set of opinions
        opinions = np.array([agent.opinion for agent in agents])
        # Calculate Freeman segregation index
        FSI = [Statistics.freeman_index(opinions, network.adj_matrix[l]) for l in range(Params.N_layers)]
        # Generate output array
        output = [ind,
                  t,
                  np.mean(opinions),
                  np.std(opinions)]
        output += FSI
        self.stats.append(output)
    
    def write_output(self):
        '''
        This function outputs the information stored in the record.
        '''
        df_out = pd.DataFrame(np.array(self.stats), 
                              columns=['iter', 
                                       't', 
                                       'mean_op', 
                                       'std_op',
                                       'fsi_family',
                                       'fsi_friends',
                                       'fsi_work'])
        df_out[['iter', 't']] = df_out[['iter', 't']].astype(int)
        df_out.to_parquet('../Output/Stats.parquet')