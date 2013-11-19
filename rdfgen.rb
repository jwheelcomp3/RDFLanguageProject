#!/usr/bin/ruby

# The program generates RDF/XML from an alternate notation
# known as Osprey Notation.
#
# Authors::   Jared Wheeler (mailto:jwheelcomp3@gmail.com)
#             Matt Walston  (mailto:m@mlw.ac)
# Copyright:: Copywright (c) 2013
# License::   Creative Commons CC0 -- No Rights Reserved

# This class is a simple commandline driver which validates
# presence of the input file, parses input, validates and
# generates resulting RDF/XML

class Driver
  # Validates single commandline argument as valid filename,
  # otherwise prints usage or error. Input file stored as
  # instance variable on class.
  def initialize(arguments)
    usage_and_exit unless arguments.count == 1
    file_not_found_and_exit unless File.exists? arguments.first

    @input_file = arguments.first
  end

  # Parse input file and return output to OS
  def run
    tokenizer = Tokenizer.new(@input_file)
    parser = Parser.new(tokenizer)
    parser.start
    exit 0
  end

  private

  # Print usage message and exit with code 1
  def usage_and_exit
    puts "Usage: #{__FILE__} source_file"
    exit 1
  end

  # Print file not found error and exit with code 2
  def file_not_found_and_exit
    puts 'Input file not found.'
    exit 2
  end
end

# This class is a simple tokenizer providing the token's
# type and content. The next token is retrieved using the
# get method which advances the IO buffer. It provides
# lookahead via the peek method which resets the buffer.
class Tokenizer
  def initialize(filename)
    @io = File.open(filename)
    @keywords = %w(namespace local global blank)
  end

  def peek
    get(true)
  end

  def get (peek = false)
    if peek; start_position = @io.pos end

    # Consume whitespace
    if peek_char.match /\s/
      while (char = @io.getc)
        if char.nil?
          # Handle EOF
          return :EOF, nil
        elsif
          # Terminate loop with non-whitespace char and backup position one char
        char.match /\S/
          @io.pos -= 1
          break
        end
      end
    end

    case peek_char
      when nil
        return :EOF, nil
      when "'"
        type, token = :symbol, get_char
      when '"'
        type, token = :symbol, get_char
      when '='
        type, token = :equality_operator, get_char
      when '{'
        type, token = :opening_brace, get_char
      when '}'
        type, token = :closing_brace, get_char
      else
        type, token = get_keyword_or_literal
    end
    if peek; @io.pos = start_position end
    return type, token
  end

  private

  def get_char
    @io.getc
  end

  def peek_char
    char = get_char
    @io.pos -= 1
    char
  end

  def get_keyword_or_literal
    token = String.new

    until (char = peek_char).match /\s/
      break if char == '{' || char == '}' || char == "'" || char == '"' # Handle opening brace without whitespace
      token << get_char
    end

    type = @keywords.include?(token.downcase) ? :keyword : :literal

    return type, token
  end
end

# This class parses the tokenized input echoing output
# to the console.
class Parser
  def initialize(tokenizer)
    @tq = tokenizer
    next_content
    @namespaces = {'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'}
    @identifier = nil
  end

  def start
    expected = %w(namespace ' local global blank)
    if expected.include? @content
      @output = %Q(<?xml version="1.0" encoding="UTF-8"?>\n<rdf:RDF)
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
      @identifier = @content
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

# Only initialize and run driver when called direct rather than via test suite
if __FILE__ == $0
  driver = Driver.new(ARGV)
  driver.run
end