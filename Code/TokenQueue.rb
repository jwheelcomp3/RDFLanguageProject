class TokenQueue
	#First In, First Out -- Queue

	def initialize
		@queue = []
		@position = 0
	end

  #input expected to be {:content => 'foaf', :type => 'id'} format
  def add(input)
		@queue = @queue.push(input)
  end

  def next
		@position += 1
  end

	def get_type
		@queue[@position][:type] unless @queue[@position] == nil
	end

	def get_follow_type
		@queue[@position + 1][:type] unless @queue[@position + 1] == nil
	end

  def get_content
	  @queue[@position][:content] unless @queue[@position] == nil
  end

	def get_follow_content
		@queue[@position + 1][:content] unless @queue[@position + 1] == nil
  end

  def is_empty
    (@queue.length - 1) == initialize
  end
end
