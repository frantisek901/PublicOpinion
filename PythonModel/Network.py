"""
    This script has the information for the Agent class.
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
import Params
import numpy as np

class Network(object):
    def __init__(self, adj_matrix):
        '''
        This function initializes the group.
        '''
        self.adj_matrix = adj_matrix
    
    def update_links(self):
        '''
        This function calculates the y-union span of the group.
        '''
        endpoints = []
        for agent in self.members:
            endpoints.append([max(agent.y-Params.eps,0), 0])
            endpoints.append([min(agent.y+Params.eps,1), 1])
        endpoints = np.array(endpoints)
        endpoints = endpoints[endpoints[:,0].argsort()]
        span = 0
        prev = 0
        left = False
        for point in endpoints:
            if (not left) and point[1]==0:
                left = True
                prev = point[0]
            if left and point[1]==1:
                span += point[0]-prev
                left = False
        self.span = span
    
    def update_payoffs(self):
        '''
        This function calculates the baseline payoff of working in the group.
        '''
        self.update_span()
        x_vals = [agent.x for agent in self.members]
        z_vals = [agent.z for agent in self.members]
        self.avg_int = np.mean(x_vals) if len(self.members) > 0 else 0.5
        self.payoff = Params.f(np.mean(x_vals))*self.span*np.mean(z_vals) if len(self.members) > 0 else 0