"""
    This script has the information for the time iteration of the model.
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

class Simulation(object):
    def __init__(self):
        '''
        This function initializes the simulation object
        '''
        self.time = 0
    
    def iterate(self, agents, groups, record):
        '''
        This function advances the simulation one time step.
        '''
        # Update membership record
        record.get_membership(agents)
        # Update group payoffs
        for group in groups:
            group.update_payoffs()
        # Agent's decisions
        for agent in agents:
            # Update probing status
            agent.update_probe()
            agent.update_payoff()
            # Agents decide whether to move out of a group
            agent.choose_isolate()
            # Agents go into the probing stage
            agent.check_probe()
            if agent.probe_curr:
                if agent.group != None:
                    agent.group.members.remove(agent)
                new_group = np.random.choice(groups)
                agent.group = new_group
                new_group.members.append(agent)
            # Previously probing agents decide whether to go back
            agent.probe_return()
        # Update time
        self.time += 1