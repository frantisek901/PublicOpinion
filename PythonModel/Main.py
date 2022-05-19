"""
    This script runs the public opinion simulation with multiple networks with
    dynamic network structure and dynamic opinion.
-------------------------------------------------------------------------------
created on:
    Thu 3 Mar 2022
-------------------------------------------------------------------------------
last change:
    Wed 18 May 2022
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
import Generator
import TimeSeries

#------------------------------------------------------------------------------
# SIMULATION
#------------------------------------------------------------------------------
def sim_single(ind, record):
    '''
    This function initializes and runs an instance of the simulation.
    
    '''
    # Initialize agents
    population = Generator.Population()
    # Extract agents and groups
    agents = population.agents
    groups = population.groups
    network = population.network
    # Run simulation
    Generator.run_simulation(ind, agents, network, record)

def sim_multiple():
    '''
    This function runs multiple instances of the simulation.

    '''
    # Initialize record
    record = TimeSeries.Record()
    # Run simulations
    for i in range(Params.N_sim):
        sim_single(i, record)
        if i%100 == 0:
            print('Simulation ', i, ' done.')
    # Write output
    record.write_output()