"""
    This script has the information for the time iteration of the model.
-------------------------------------------------------------------------------
created on:
    Thu 3 Mar 2022
-------------------------------------------------------------------------------
last change:
    Thu 5 May 2022
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

def sigmoid(d):
    '''
    This function gives an interaction weight based on opinion difference.

    '''
    d0 = Params.d0
    tau = Params.tau
    return 1/(1+np.exp(np.pi*(d-d0)/(np.sqrt(3)*tau)))

class Simulation(object):
    def __init__(self):
        '''
        This function initializes the simulation object
        '''
        self.time = 0
    
    def iterate(self, agents, network, record):
        '''
        This function advances the simulation one time step.
        '''
        # Update statistics
        record.get_stats(agents, network)
        # Update weight matrix
        for agent in agents:
            for l in range(Params.N_layers):
                for friend in agent.groups[l].members:
                    if friend.ident != agent.ident:
                        # Get weight of interaction
                        w = network.adj_matrix[l][agent.ident, friend.ident]
                        # Get difference of opinions
                        dist = friend.opinion - agent.opinion
                        if (dist < Params.tol_high) and (dist > Params.tol_low):
                            network.adj_matrix[l][agent.ident, friend.ident] = sigmoid(dist)
                        else:
                            network.adj_matrix[l][agent.ident, friend.ident] = 0
        # Update agents' opinions
        for agent in agents:
            for l in range(Params.N_layers):
                for friend in agent.groups[l].members:
                    if friend.ident != agent.ident:
                        # Get weight of interaction
                        w = network.adj_matrix[l][agent.ident, friend.ident]
                        # Get difference of opinions and update
                        dist = friend.opinion - agent.opinion
                        agent.opinion += w*dist
            if agent.opinion < Params.op_low:
                agent.opinion = Params.op_low
            elif agent.opinion > Params.op_high:
                agent.opinion = Params.op_high
        # Update time
        self.time += 1