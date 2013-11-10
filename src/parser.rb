require_relative 'TokenQueue'

class Parser

  # Input is the Token Queue filled by the Tokenizer
  def initialize(token_queue)
    @tq = token_queue
    @tq.add({:content => '$', :type => 'EOF'})
  end

  #TODO:  Test beyond Namespace block
  #TODO:  Send names to Symbol Table AND Semantic Checks

  def start
    content = @tq.get_content
    expected = %w(namespace ' local global blank)
    if expected.include? content
      all()
    else
      raise ('Received input: '+content+', expected: '+expected.each {|e| e.to_s+'; '})
    end
    unless @tq.get_content == '$' && @tq.get_type == 'EOF'
      raise ('Excessive input when program should be finished.')
    end
    puts 'Successful Parse!'
  rescue Exception => e
    puts e.message
    puts e.backtrace
  end

  def all
    content = @tq.get_content
    expected = %w(namespace \' local global blank)
    if expected.include? content
      namespace_block
      definition
    else
      raise ('Received input: '+content+', expected: '+expected.each {|e| e.to_s+'; '})
    end
  end

  def namespace_block
    content = @tq.get_content
    follow_expected = %w(' local global blank $)
    if content == 'namespace'
      @tq.next
      get_next_check(@tq.get_type, :id)
      get_next_check(@tq.get_content, '=')
      uri
      namespace_block
    else unless follow_expected.include? content
        raise ('Received input: '+content+', expected: '+follow_expected.each {|e| e.to_s+'; '})
        end
    end
  end

  def definition
    content = @tq.get_content
    case content
    when '\''
      uri
      block
      definition
    when 'local'
      local_id
      block
      definition
    when 'global'
      global_id
      block
      definition
    when 'blank'
      block
      definition
    else unless content == '$'
      raise('Received input: '+content+', expected: \'; local; global; blank;')
      end
    end
  end

  def uri
    content = @tq.get_content
    if get_next_check(content, '\'')
      get_next_check(@tq.get_type , :literal)
      get_next_check(@tq.get_content , '\'')
    end
  end

  def local_id
    content = @tq.get_content
    get_next_check(content, 'local')
    get_next_check(@tq.get_type, :id)
  end

  def global_id
    content = @tq.get_content
    get_next_check(content, 'global')
    get_next_check(@tq.get_type, :id)
  end

  def block
    content = @tq.get_content
    get_next_check(content, '{')
    namespace_verb
    verb_content
    get_next_check(content, '}')
  end

  def namespace_verb
    type = @tq.get_type
    get_next_check(type, :id)
    get_next_check(@tq.get_content, '::')
    get_next_check(@tq.get_type, :id)
  end

  def verb_content
    content = @tq.get_content
    if content == '\''
      uri
      node_in_verb
    elsif content == '{' || content == '}'
      node_in_verb
    else
         raise('Received input: '+content+', expected: \'; {; };')
    end
  end

  def node_in_verb
    content = @tq.get_content
    if content == '{'
      get_next_check(content, '{')
      verb_block
      get_next_check(content, '}')
    else unless content == '}'
        raise('Received input: '+content+', expected: };')
         end
    end
  end

  def verb_block
    content = @tq.get_content
    if content == '~'
      get_next_check(content, '~')
      get_next_check(@tq.get_type, :literal)
    else
      definition
    end
  end

  def get_next_check(value, expected)
    if value.nil?
      raise('Input missing, should be: '+expected)
    elsif expected.class == 'Array'
      if expected.include? value
        @tq.next
        true
      else
        raise('Received input: '+value+', expected: '+expected.each {|e| e.to_s+'; '})
      end
    elsif expected.to_s == value.to_s
      @tq.next
      true
    else
      raise('Received input: '+value+', expected: '+expected)
    end
   end
end


#tq = TokenQueue.new()
#tq.add({:content => 'namespace', :type => 'keyword'})
#tq.add({:content => 'foaf', :type => 'id'})
#tq.add({:content => '=', :type => 'symbol'})
#tq.add({:content => '\'', :type => 'symbol'})
#tq.add({:content => 'uri', :type => 'literal'})
#tq.add({:content => '\'', :type => 'symbol'})
#tq.add({:content => 'namespace', :type => 'keyword'})
#tq.add({:content => 'owl', :type => 'id'})
#tq.add({:content => '=', :type => 'symbol'})
#tq.add({:content => '\'', :type => 'symbol'})
#tq.add({:content => 'different uri', :type => 'literal'})
#tq.add({:content => '\'', :type => 'symbol'})
#
#Parser.new(tq).start()
