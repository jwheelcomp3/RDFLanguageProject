#class TokenQueue
#	#First In, First Out -- Queue
#
#	def initialize
#		@queue = []
#		@position = 0
#	end
#
#  #input expected to be {:content => 'foaf', :type => 'id'} format
#  def add(input)
#		@queue = @queue.push(input)
#  end
#
#  def next
#		@position += 1
#  end
#
#	def get_type
#		@queue[@position][:type] unless @queue[@position] == nil
#	end
#
#	def get_follow_type
#		@queue[@position + 1][:type] unless @queue[@position + 1] == nil
#	end
#
#  def get_content
#	  @queue[@position][:content] unless @queue[@position] == nil
#  end
#
#	def get_follow_content
#		@queue[@position + 1][:content] unless @queue[@position + 1] == nil
#  end
#
#  def is_empty
#    (@queue.length - 1) == initialize
#  end
#end


class TokenQueue
  def initialize(filename)
    @io = File.open(filename)
    @keywords = ['namespace', 'local']
  end

  def peek
    get(true)
  end

  def get (peek = false)
    if peek; start_position = @io.pos end

    token = []
    type = nil

    while char = @io.getc
      case char
        when /['"]/
          type = :string_literal
          opening_char = char
          until (char = @io.getc) == opening_char
            token << char
          end
        when '='
          type = :equals
        when '{'
          if token.empty?
            type = :open_brace
          else
            @io.pos -= 1
            break
          end
        when '}'
          type = :closing_brace
        when "\n"
          break
        when /\s/
          if token.empty?
            next
          else
            break
          end
        else
          token << char
      end
    end

    if char.nil?
      type = :eof
    end

    if type.nil?
      is_keyword?(token.join) ? type = :keyword :type = :identifier
    end

    if peek; @io.pos = start_position end

    return type, token.join
  end

  def is_keyword? (word)
    @keywords.include? word
  end
end

#tokenizer = ModernTokenizer.new('../example/input')
#80.times do
#  type, token = tokenizer.get
#  puts "#{type.to_s.upcase}: #{token}"
#end