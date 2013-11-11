require_relative 'TokenQueue'

class Parser

  # Input is theTokenizer
  def initialize(token_queue)
    @tq = token_queue
    next_content
    @namespaces = {'rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#"}
    @identifier = nil
  end

  #TODO:  Send names to Symbol Table AND Additional Semantic Checks
  #TODO:  Generate Proper output

  def start
    expected = %w(namespace ' local global blank)
    if expected.include? @content
      all()
    else
      raise ('Received input: '+@content.to_s+', expected: '+expected.each {|e| e.to_s+'; '})
    end
    unless @type == :EOF
      raise ('Excessive input when program should be finished.')
    end
  rescue Exception => e
    puts e.message
    #puts e.backtrace
  end

  def all
    expected = %w(namespace \' local global blank)
    if expected.include? @content
      namespace_block
      definition
    else
      raise ('Received input: '+@content.to_s+', expected: '+expected.each {|e| e.to_s+'; '})
    end
  end

  def namespace_block
    follow_expected = %w(' local global blank)
    if @content == 'namespace'
      get_next_check(@content, 'namespace')
      @identifier = @content;
      get_next_check(@type, :literal)
      get_next_check(@content, '=')
      uri
      namespace_block
    else unless (follow_expected.include? @content) || @type == :EOF
        raise ('Received input: '+@content.to_s+', expected: '+follow_expected.each {|e| e.to_s+'; '})
        end
    end
  end

  def definition
    case @content
    when "'"
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
      get_next_check(@content, 'blank')
      block
      definition
    else unless @type == :EOF || @content == '}' || @type == :literal
      raise('Received input: '+@content.to_s+', expected: \'; local; global; blank;')
      end
    end
  end

  def uri
    get_next_check(@content, "'")
    if @type == :literal
      unless @content.match %r{\Ahttp:s?//.+}i
        raise(@content.to_s+' is an invalid URI')
      end
      unless @identifier.nil?
        unless @namespaces[@identifier.to_s].nil?
          raise(@identifier.to_s+' declared twice!')
        else
          @namespaces = @namespaces.merge({@identifier.to_s => @content})
          @identifier = nil
        end
      end
    end
    get_next_check(@type , :literal)
    get_next_check(@content , "'")
  end

  def local_id
    get_next_check(@content, 'local')
    get_next_check(@type, :literal)
  end

  def global_id
    get_next_check(@content, 'global')
    get_next_check(@type, :literal)
  end

  def block
    get_next_check(@content, '{')
    inner_block
    get_next_check(@content, '}')
  end

  def inner_block
    if %w(' local global blank).include? @content
      definition
      inner_block
    elsif @type == :literal
      namespace_verb
      verb_content
      inner_block
    else unless @content == '}'
       raise('Received input: '+@content.to_s+', expected: };')
     end
    end
  end

  def namespace_verb
    type = @type
    if type == :literal
      namespace = @content.split(/#|::/).first
      if @namespaces[namespace.to_s].nil?
        raise('Invalid Namespace: '+namespace.to_s)
      end
      next_content
    else
      raise('Received input: '+@content.to_s+', expected a namespace::predicate')
    end
  end

  def verb_content
    if @content == "'"
      uri
      maybe_node_in_verb
    elsif @content == '{'
      node_in_verb
    else unless %w(' } local global blank).include? @content
         raise('Received input: '+@content.to_s+', expected: \'; };')
       end
    end
  end

  def maybe_node_in_verb
    if @content == '{'
      node_in_verb
    else unless (%w(' } local global blank).include? @content) || @type == :literal
           raise('Received input: '+@content.to_s+', expected: \'; };')
         end
    end
  end

  def node_in_verb
    if @content == '{'
      get_next_check(@content, '{')
      verb_block
      get_next_check(@content, '}')
    else unless @content == '}' || @type == :literal
        raise('Received input: '+@content.to_s+', expected: };')
       end
    end
  end

  def verb_block
    if @content == '"'
      get_next_check(@content, '"')
      continued_literal
      get_next_check(@content, '"')
    else
      definition
    end
  end

  def continued_literal
    if @type == :literal
      get_next_check(@type, :literal)
      continued_literal
    else unless @content == '"'
           raise('Received input: '+@content.to_s+', expected: ""')
         end
    end
  end

  def get_next_check(value, expected)
    if value.nil?
      raise('Input missing, should be: '+expected)
    elsif expected.class == 'Array'
      if expected.include? value
        @type, @content = @tq.get
        true
      else
        raise('Received input: '+value+', expected: '+expected.each {|e| e.to_s+'; '})
      end
    elsif expected.to_s == value.to_s
      @type, @content =  @tq.get
      true
    else
      raise('Received input: '+value+', expected: '+expected)
    end

    #puts (@type.to_s+': with value: '+@content.to_s)

  end

  def next_content
    @type, @content = @tq.get
    #puts (@type.to_s+': with value: '+@content.to_s)
  end
end

####Good Test Suite
tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input')
Parser.new(tokenizer).start

tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input2.txt')
Parser.new(tokenizer).start

tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input3.txt')
Parser.new(tokenizer).start

tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input4.txt')
Parser.new(tokenizer).start



####Bad Semantic Test Suite
#undeclared namespace
puts 'bad1 -- undeclared namespace'
tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad1.txt')
Parser.new(tokenizer).start

#bad namespace URI
puts 'bad2 -- bad namespace URI'
tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad2.txt')
Parser.new(tokenizer).start

#bad body URI
puts 'bad3 -- bad body URI'
tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad3.txt')
Parser.new(tokenizer).start

#duplicate namespace
puts 'bad4 -- duplicate namespace'
tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad4.txt')
Parser.new(tokenizer).start