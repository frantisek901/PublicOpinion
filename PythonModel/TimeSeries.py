"""
    This script has the information for the time iteration of the model.
-------------------------------------------------------------------------------
created on:
    Thu 3 Mar 2022
-------------------------------------------------------------------------------
last change:
    Sat 6 Mar 2022
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
        self.attributes = []
        self.membership = []
        
    def get_attributes(self, agents):
        '''
        This function extracts the attributes from a set of agents.
        '''
        for agent in agents:
            self.attributes.append([agent.x, agent.y, agent.z])
    
    def get_membership(self, agents):
        '''
        This function extracts the groups to which a set of agents belongs.
        '''
        group_list = [(agent.group.ident if agent.group!=None else -1) for agent in agents]
        self.membership.append(group_list)
        
    
    def write_output(self):
        '''
        This function outputs the information stored in the record.
        '''
        np.save('Output/Attributes', np.array(self.attributes))
        np.save('Output/Membership', np.array(self.membership))