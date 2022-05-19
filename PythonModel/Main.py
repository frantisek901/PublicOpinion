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
import Generator
import TimeSeries

#------------------------------------------------------------------------------
# SIMULATION
#------------------------------------------------------------------------------
def simulate():
    '''
    This function initializes and runs the simulation.
    '''
    # Initialize agents
    population = Generator.Population()
    print('Initialization complete')
    # Initialize timeSeries object
    record = TimeSeries.Record()
    # Extract agents and groups
    agents = population.agents
    groups = population.groups
    network = population.network
    # Run simulation
    Generator.run_simulation(agents, network, record)
    # Write output
    record.write_output()
    print('Simulation complete')