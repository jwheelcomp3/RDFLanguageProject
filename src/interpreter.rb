class Interpreter

  def initialize(filename)
    tokenizer = TokenQueue.new(filename)
    Parser.new(tokenizer).start
  end

  ####Good Test Suite
  #tokenizer = TokenQueue.new('..\example\input')
  #Parser.new(tokenizer).start
  #
  #puts "\n\n-----------------------\n\n"
  #
  #tokenizer = TokenQueue.new('..\example\input2.txt')
  #Parser.new(tokenizer).start
  #
  #puts "\n\n-----------------------\n\n"
  #
  #tokenizer = TokenQueue.new('..\example\input3.txt')
  #Parser.new(tokenizer).start
  #
  #puts "\n\n-----------------------\n\n"
  #
  #tokenizer = TokenQueue.new('..\example\input4.txt')
  #Parser.new(tokenizer).start
  #
  #puts "\n\n-----------------------\n\n"
  #
  #tokenizer = TokenQueue.new('..\example\input5.txt')
  #Parser.new(tokenizer).start


  #####Bad Semantic Test Suite
  ##undeclared namespace
  #puts 'bad1 -- undeclared namespace'
  #tokenizer = TokenQueue.new('..\example\bad1.txt')
  #Parser.new(tokenizer).start
  #
  ##bad namespace URI
  #puts 'bad2 -- bad namespace URI'
  #tokenizer = TokenQueue.new('..\example\bad2.txt')
  #Parser.new(tokenizer).start
  #
  ##bad body URI
  #puts 'bad3 -- bad body URI'
  #tokenizer = TokenQueue.new('..\example\bad3.txt')
  #Parser.new(tokenizer).start
  #
  ##duplicate namespace
  #puts 'bad4 -- duplicate namespace'
  #tokenizer = TokenQueue.new('..\example\bad4.txt')
  #Parser.new(tokenizer).start
  #
  ##no base namespace using local/global
  #puts 'bad5 -- no base namespace using global'
  #tokenizer = TokenQueue.new('..\example\bad5.txt')
  #Parser.new(tokenizer).start
end