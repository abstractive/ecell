class Ef::Pack::Capacity::Database::MySQL < Ef::Pack::Actor

  def initialize(options)
    fail ArgumentError unless options.is_a?(Hash)
    debug("Initialized MySQL database connector.")
  end

end