require 'connect_mpi/mpi'

MPIService = (!ApplicationController.dependencies_faked? ? ExternalApi::MPIService : Fakes::MPIService)
