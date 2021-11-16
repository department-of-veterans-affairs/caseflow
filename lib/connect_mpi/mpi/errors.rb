
module MPI
  class QueryError < StandardError; end

  class NotFoundError < QueryError; end

  class QueryResultError < QueryError; end

  class ApplicationError < QueryError; end
end
