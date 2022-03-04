"""
    This script has the information for the initialization of the model.
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
import Agents
import Groups
import TimeIteration
import numpy as np

#------------------------------------------------------------------------------
# AUXILIARY FUNCTIONS
#------------------------------------------------------------------------------
def generate_attributes():
    '''
    This function creates agent attributes according to the specified 
    distributions.
    '''
    x = np.random.beta(Params.sx, Params.sx)
    y = np.random.beta(Params.sy, Params.sy)
    z = np.random.rand()
    return x, y, z

#------------------------------------------------------------------------------
# GENERATION
#------------------------------------------------------------------------------
class Population(object):
    def __init__(self, agents=None, groups=None):
        '''
        This function initializes the population object.

        '''
        # Create agent list
        agents = []
        Na = Params.N_agents
        for i in range(Na):
            x, y, z = generate_attributes()
            agent = Agents.Agent(ident=i, x=x, y=y, z=z)
            agents.append(agent)
        self.agents = agents
        # Generate group list
        groups = []
        Ng = Params.N_groups
        for g in range(Ng):
            group = Groups.Group(ident=g)
            groups.append(group)
        self.groups = groups
        # Assign agents to groups
        for agent in agents:
            g = np.random.choice(np.arange(Ng+1))
            if g < Ng:
                agent.group = groups[g]
                groups[g].members.append(agent)
            else:
                agent.group = None

#------------------------------------------------------------------------------
# SIMULATION
#------------------------------------------------------------------------------
def run_simulation(agents, groups, record):
    '''
    This function runs the simulation with the initialized agents.
    '''
    my_simulation = TimeIteration.Simulation()
    record.get_attributes(agents)
    while my_simulation.time < Params.T:
        my_simulation.iterate(agents, groups, record)