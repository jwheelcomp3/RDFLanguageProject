#namespace foaf = 'http://xmlns.com/foaf/0.1/'
#namespace owl = 'http://www.w3.org/2002/07/owl#'
#namespace uom = 'http://www.measures.org/units#'
#namespace base = 'http://www.iloveTigers.com'
#
#local TigerLover{
#  foaf::name {
#    ~Joseph Catz
#  }
#  owl::SameAs 'http://www.facebook.com/Catlover500'
#  base::likes 'http://www.iloveTigers.com#Tiger'
#}
#
#global Cat{
#  blank {
#    rdf::value 'http://www.w3.org/2001/XMLSchema#decimal'{
#        ~88.8
#  }
#  uom::weight 'http://www.measures.org/units#kilograms'
#}
#}
#
#'http://www.iloveTigers.com/TigerFans#Tiger'{
#    owl::Child 'http://www.iloveTigers.com#Cat'
#owl::Parent {
#  local SiberianTiger{
#    base::color {
#      ~white
#    }
#  }
#}
#}

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
        when '~'
          type = :tilde
          until (char = @io.getc).match /\s/
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

tokenizer = TokenQueue.new('../example/input')
80.times do
  type, token = tokenizer.get
  puts "#{type.to_s.upcase}: #{token}"
end