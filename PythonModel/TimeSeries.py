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
        This function extracts the attributes from a set of agents.
        '''
        opinions = [agent.opinion for agent in agents]
        output = [ind,
                  t,
                  np.mean(opinions),
                  np.std(opinions)]
        self.stats.append(output)
    
    def write_output(self):
        '''
        This function outputs the information stored in the record.
        '''
        df_out = pd.DataFrame(np.array(self.stats), 
                              columns=['iter', 't', 'mean_op', 'std_op'])
        df_out[['iter', 't']] = df_out[['iter', 't']].astype(int)
        df_out.to_parquet('../Output/Stats.parquet')