class TokenQueue
  def initialize(filename)
    @io = File.open(filename)
    @keywords = ['namespace', 'local', 'global', 'blank']
  end

  def get_char
    @io.getc
  end

  def peek_char
    char = get_char
    @io.pos -= 1
    char
  end

  def peek
    get(true)
  end

  def get (peek = false)
    type = nil
    token = ''

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
        type, token = get_symbol
      when '"'
        type, token = get_symbol
      when '='
        type, token = get_equality_operator
      when '{'
        type, token = get_opening_brace
      when '}'
        type, token = get_closing_brace
      else
        type, token = get_keyword_or_literal
    end
    if peek; @io.pos = start_position end
    return type, token
  end

  def get_symbol
    type = :symbol
    token = get_char

    return type, token
  end

  def get_equality_operator
    type = :equality_operator
    token = get_char

    return type, token
  end

  def get_opening_brace
    type = :opening_brace
    token = get_char

    return type, token
  end

  def get_closing_brace
    type = :closing_brace
    token = get_char

    return type, token
  end

  def get_keyword_or_literal
    token = ''

    until (char = peek_char).match /\s/
      break if char == '{' || char == '}' || char == "'" || char == '"' # Handle opening brace without whitespace
      token << get_char
    end

    if is_keyword? token.downcase
      type = :keyword
    else
      type = :literal
    end

    return type, token
  end

  def is_keyword? (word)
    @keywords.include? word
  end
end

#tokenizer = TokenQueue.new('../example/input')
#100.times do
#  type, token = tokenizer.get
#  puts "#{type.to_s.upcase}: #{token}"
#end
#
## Regex example for semantic check
#namespace_idenfitier, double_colon, trait = 'uom::weight'.match(/(\w+)(::)(\w+)/).captures