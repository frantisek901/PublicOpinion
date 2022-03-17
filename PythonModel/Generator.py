"""
    This script has the information for the initialization of the model.
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
import Params
import Agents
import Groups
import Network
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
    opinion = np.random.beta(Params.sigma, Params.sigma)
    return opinion

#------------------------------------------------------------------------------
# GENERATION
#------------------------------------------------------------------------------
class Population(object):
    def __init__(self, agents=None, network=None):
        '''
        This function initializes the population object.

        '''
        # Create agent list
        agents = []
        Na = Params.N_agents
        for i in range(Na):
            opinion = generate_attributes()
            agent = Agents.Agent(ident=i, opinion=opinion)
            agents.append(agent)
        self.agents = agents
        # Generate group information tensor
        groups = []
        Nl = Params.N_layers
        for l in range(Nl):
            Ng = int(Na/Params.avg_members[l])
            layer = []
            for g in range(Ng):
                group = Groups.Group(layer=l, ident=g)
                layer.append(group)
            groups.append(layer)
        self.groups = groups
        # Assign agents to groups
        for agent in agents:
            agent.groups = []
            for l in range(Nl):
                Ng = int(Na/Params.avg_members[l])
                g = np.random.choice(np.arange(Ng))
                agent.groups.append(groups[l][g])
                groups[l][g].members.append(agent)
        networks = []
        for l in range(Nl):
            layer_net = np.zeros([Na, Na], dtype=float)
            for group in groups[l]:
                for agent_i in group.members:
                    for agent_j in group.members:
                        if agent_i.ident < agent_j.ident:
                            # Family ties
                            if l == 0:
                                layer_net[agent_i.ident, agent_j.ident] = Params.init_weight[l]
                            # Work ties
                            elif l == 1:
                                layer_net[agent_i.ident, agent_j.ident] = \
                                   np.random.choice([0.,Params.init_weight[l]],p=[1-Params.p_link[l], Params.p_link[l]])
                            # Friend ties
                            else:
                                if np.random.rand() < Params.p_main_gang:
                                    layer_net[agent_i.ident, agent_j.ident] = \
                                       np.random.choice([0.,Params.init_weight[l]],p=[1-Params.p_link[l], Params.p_link[l]])
                                elif agent_i.ident < agent_j.ident:
                                    others = [k for k in agents if k.groups[l]!=group]
                                    new_friend = np.random.choice(others)
                                    min_ind, max_ind = np.sort([agent_i.ident, new_friend.ident])
                                    layer_net[min_ind, max_ind] = Params.init_weight[l]
            layer_net += layer_net.T
            networks.append(layer_net)
        network = Network.Network(np.array(networks))
        self.network = network

#------------------------------------------------------------------------------
# SIMULATION
#------------------------------------------------------------------------------
def run_simulation(agents, network, record):
    '''
    This function runs the simulation with the initialized agents.
    '''
    my_simulation = TimeIteration.Simulation()
    record.get_attributes(agents)
    while my_simulation.time < Params.T:
        my_simulation.iterate(agents, network, record)