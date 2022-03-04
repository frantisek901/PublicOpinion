"""
    This script has the information for the Agent class.
-------------------------------------------------------------------------------
created on:
    Sun 16 Jan 2022
-------------------------------------------------------------------------------
last change:
    Wed 26 Jan 2022
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

class Agent(object):
    def __init__(self, ident, x, y, z):
        '''
        This function initializes the agent.
        '''
        self.ident = ident
        self.x = x
        self.y = y
        self.z = z
        self.group = None
        self.payoff = 0
        self.lone_payoff = Params.f(x)*(min(y+Params.eps,1)-max(y-Params.eps,0))*z
        self.probe_prev = False
        self.probe_curr = False
        self.isolate = False
        self.prev_group = None
        self.prev_payoff = 0
    
    def update_probe(self):
        '''
        This function updates the probing status of the agent.
        '''
        self.probe_prev = self.probe_curr
        self.probe_curr = False
        self.prev_payoff = self.payoff
    
    def update_payoff(self):
        '''
        This function updates the payoff of the agent.
        '''
        if self.group == None:
            self.payoff = self.lone_payoff
        else:
            self.payoff = self.group.payoff*(1-abs(self.group.avg_int-self.x))
    
    def choose_isolate(self):
        '''
        This function decides whether the agent will choose to move out of a
        group.
        '''
        self.isolate = False
        if self.group != None and self.payoff<self.lone_payoff:
            self.isolate = True
            self.group.members.remove(self)
            self.group = None
    
    def check_probe(self):
        '''
        This function controls the probing dynamics of the agents.
        '''
        if not self.isolate:
            if np.random.rand() < Params.beta:
                self.probe_curr = True
    
    def probe_return(self):
        '''
        This function evaluates whether a previously probing agent wishes to
        return.
        '''
        if (not self.probe_curr) and self.probe_prev:
            self.probe_prev = False
            if self.prev_payoff > self.payoff:
                self.group.members.remove(self)
                self.prev_group.members.append(self)
                self.group = self.prev_group
        self.prev_group = self.group