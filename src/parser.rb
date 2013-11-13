require_relative 'TokenQueue'

class Parser

  # Input is theTokenizer
  def initialize(token_queue)
    @tq = token_queue
    next_content
    @namespaces = {'rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#"}
    @identifier = nil

  end

  def start
    expected = %w(namespace ' local global blank)
    if expected.include? @content
      @output = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rdf:RDF"
      all()
      @output += "\n</rdf:RDF>"
    else
      raise ('Received input: '+@content.to_s+', expected: '+expected.each {|e| e.to_s+'; '})
    end
    unless @type == :EOF
      raise ('Excessive input when program should be finished.')
    end
  puts @output
  rescue Exception => e
    puts @output
    puts e.message
    #puts e.backtrace
  end

  def all
    expected = %w(namespace \' local global blank)
    if expected.include? @content
      namespace_block
      @namespaces.each {|key, uri| @output+= "\n\t\txmlns:"+key.to_s+'="'+uri.to_s+'"'}
      @output+= '>'
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

  def definition(give_output = true)
    case @content
      when "'"  #rdf:about
        @output += "\n<rdf:Description"
        @output += "\t\trdf:about="
        uri
        @output += '>'
        block
        @output += "\n</rdf:Description>"
        definition
      when 'local'  #rdf:nodeID
        @output += "\n<rdf:Description"
        local_id
        @output += '>'
        block
        @output += "\n</rdf:Description>"
        definition
      when 'global' #rdf:ID
        if @namespaces['base'].nil?
          raise('Cannot use global identifier without a base namespace.')
        end
        @output += "\n<rdf:Description"
        global_id
        @output += '>'
        block
        @output += "\n</rdf:Description>"
        definition
      when 'blank'  #no identifier
        if give_output
          @output += "\n<rdf:Description>"
        end
        get_next_check(@content, 'blank')
        block
        definition
        if give_output
          @output += "\n</rdf:Description>"
        end
    else unless @type == :EOF || @content == '}' || @type == :literal
      raise('Received input: '+@content.to_s+', expected: \'; local; global; blank;')
      end
    end
  end

  def uri
    get_next_check(@content, "'")
    if @type == :literal
      unless @content.match %r{\Ahttp:s?//.+}i
        if @node_possible == false
          raise(@content.to_s+' is an invalid URI')
        else
          @output+= ' rdf:nodeID="'+@content.to_s+'"'
          @node_possible = false
        end
      end
      if !@identifier.nil?
        unless @namespaces[@identifier.to_s].nil?
          raise(@identifier.to_s+' declared twice!')
        else
          @namespaces = @namespaces.merge({@identifier.to_s => @content})
          @identifier = nil
        end
      elsif @node_possible == true
        @output+= ' rdf:resource="'+@content.to_s+'"'
      elsif (@node_possible == false) && (@content.match %r{\Ahttp:s?//.+}i) #Used either as rdf:about or rdf:resource target
          @output+= '"'+@content+'"'
      end
    end
    get_next_check(@type , :literal)
    get_next_check(@content , "'")
    @node_possible = false
  end

  def local_id
    get_next_check(@content, 'local')
    @output += "\n\t\trdf:nodeID=\""+@content.to_s+'"'
    @namespaces = @namespaces.merge({@content.to_s => 'local'})
    get_next_check(@type, :literal)
  end

  def global_id
    get_next_check(@content, 'global')
    @output += "\n\t\trdf:ID=\""+@content.to_s+'"'
    get_next_check(@type, :literal)
  end

  def block
    get_next_check(@content, '{')
    inner_block
    get_next_check(@content, '}')
  end

  def inner_block
    if @type == :literal
      verb_type = @content.clone
      @output += "\n\t<"
      namespace_verb
      def_or_content(verb_type)
      inner_block
    else unless @content == '}'
       raise('Received input: '+@content.to_s+', expected: };')
     end
    end
  end

  def def_or_content(verb_type)
    if @content.to_s == 'blank'
      close = true
      @output+= ' rdf:parseType="Resource">'
      definition(false)
    elsif @content.to_s == '{' || @content.to_s == "'"
      close = verb_content
    end
    if close
      @output += "\n\t</"+verb_type.sub!('::', ':').to_s+'>'
    end
  end

  def namespace_verb
    type = @type
    if type == :literal
      namespace = @content.split(/#|::/).first
      if @namespaces[namespace.to_s].nil?
        raise('Invalid Namespace: '+namespace.to_s)
      end
      @output += @content.sub!('::', ':').to_s
      next_content
    else
      raise('Received input: '+@content.to_s+', expected a namespace::predicate')
    end
  end

  def verb_content
    if @content == "'"
      @node_possible = true;
      uri
      return_val = maybe_node_in_verb
      return_val
    elsif @content == '{'
      node_in_verb
      true
    else unless %w(' } local global blank).include? @content
         raise('Received input: '+@content.to_s+', expected: \'; };')
       end
    end
  end

  def maybe_node_in_verb
    if @content == '{'
      true
      node_in_verb
    else unless (%w(' } local global blank).include? @content) || @type == :literal
           raise('Received input: '+@content.to_s+', expected: \'; };')
         else
           @output += '/>'
           false
         end
    end
  end

  def node_in_verb
    if @content == '{'
      @output+= '>'
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
      @output += @content.to_s+' '
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
  end

  def next_content
    @type, @content = @tq.get
  end
end

####Good Test Suite
#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input')
#Parser.new(tokenizer).start

#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input2.txt')
#Parser.new(tokenizer).start
#
#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input3.txt')
#Parser.new(tokenizer).start
#
tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input4.txt')
Parser.new(tokenizer).start
#
#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\input5.txt')
#Parser.new(tokenizer).start


#####Bad Semantic Test Suite
##undeclared namespace
#puts 'bad1 -- undeclared namespace'
#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad1.txt')
#Parser.new(tokenizer).start
#
##bad namespace URI
#puts 'bad2 -- bad namespace URI'
#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad2.txt')
#Parser.new(tokenizer).start
#
##bad body URI
#puts 'bad3 -- bad body URI'
#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad3.txt')
#Parser.new(tokenizer).start
#
##duplicate namespace
#puts 'bad4 -- duplicate namespace'
#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad4.txt')
#Parser.new(tokenizer).start
#
##no base namespace using local/global
#puts 'bad5 -- no base namespace using global'
#tokenizer = TokenQueue.new('D:\Programs\Ruby\RDFLanguageProject\example\bad5.txt')
#Parser.new(tokenizer).start