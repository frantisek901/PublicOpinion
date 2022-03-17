"""
    This script has the information for the time iteration of the model.
-------------------------------------------------------------------------------
created on:
    Thu 3 Mar 2022
-------------------------------------------------------------------------------
last change:
    Thu 17 Mar 2022
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

class Record(object):
    def __init__(self):
        '''
        This function initializes the record.
        '''
        self.mean = []
        self.std = []
        
    def get_stats(self, agents, network):
        '''
        This function extracts the attributes from a set of agents.
        '''
        opinions = [agent.opinion for agent in agents]
        self.mean.append(np.mean(opinions))
        self.std.append(np.std(opinions))
    
    def write_output(self):
        '''
        This function outputs the information stored in the record.
        '''
        np.savetxt('../Output/Mean.txt', self.mean, delimiter=',')
        np.savetxt('../Output/Std.txt', self.std, delimiter=',')