# Boggle game with driver code to run the program.
# visual shuffle sequence
# board will show you in color the word you are looking for if it exists.

# FIX THIS: downside it doesn't overwrite the previous boards.
require 'set'
require 'pry'

class BoggleBoard
  attr_reader :words_found, :score
  DICTIONARY_PATH = '/usr/share/dict/words'

  LETTERS =   [["A", "A", "E", "E", "G", "N"],
               ["E", "L", "R", "T", "T", "Y"],
               ["A", "O", "O", "T", "T", "W"],
               ["A", "B", "B", "J", "O", "O"],
               ["E", "H", "R", "T", "V", "W"],
               ["C", "I", "M", "O", "T", "U"],
               ["D", "I", "S", "T", "T", "Y"],
               ["E", "I", "O", "S", "S", "T"],
               ["D", "E", "L", "R", "V", "Y"],
               ["A", "C", "H", "O", "P", "S"],
               ["H", "I", "M", "N", "Q", "U"],
               ["E", "E", "I", "N", "S", "U"],
               ["E", "E", "G", "H", "N", "W"],
               ["A", "F", "F", "K", "P", "S"],
               ["H", "L", "N", "N", "R", "Z"],
               ["D", "E", "I", "L", "R", "X"]]


  def initialize(size=4)
    @board = Array.new(size){Array.new(size, "-")}
    @size = size
    @word_path = nil

    reset_default_variables()

    down      =  1
    right     =  1
    up        = -1
    left      = -1
    @location_offset = [ [up,   0],
                         [up,   right],
                         [0,    right],
                         [down, right],
                         [down, 0],
                         [down, left],
                         [0,    left],
                         [up,   left] ]
  end

  def shake!
    @score = 0
    @words_found = Set.new
    @max_score = nil
    @word_path = nil  # remove previous word path color on board during shuffle
    @max_words_could_find = nil

    # show the user a visual of shaking the game by putting a new board to the screen in fast succession and keeping the last solution
    15.times do |iterations|
      die_unchosen = (0..15).to_a
      for row in 0...@size do
        for col in 0...@size do
          current_die = die_unchosen.sample(1)                #grab random die that remains in die_unchosen
          current_face = rand(6)
          @board[row][col] = LETTERS[current_die[0]][current_face[0]]    # grab random face from die
          die_unchosen.delete(current_die[0])                    # remove die from remaining possible die
        end
      end
      clear_terminal_screen
      self.to_s
      sleep(0.1)
    end
  end

  def to_s                # print boggle board
    clear_terminal_screen

    puts "max_score: #{@max_score}" unless @max_score.nil?
    puts "max_words_could_find: #{@max_words_could_find}" unless @max_words_could_find.nil?
    puts "words found: #{words_found.length}."
    puts "score: #{score}."
    strs_into_me_arr = []
    for row in 0...@size do
      row_of_blocks = ""
      for col in 0...@size do
        # print makes the letter at each location [row, col] along the path that the word was found in possible parameter color_these_locations_arr
        if @word_path != nil   # if word recently found
          row_of_blocks += (@word_path.include?([row, col]) == true ? "\033[31m" : "")  + "#{@board[row][col]} " + (@word_path.include?([row, col]) == true ? "\033[0m" : "")
        else                              # no word recently found. Don't use colored letters in locations
          row_of_blocks += "#{@board[row][col]} "  #
        end
      end
      strs_into_me_arr << row_of_blocks
      #puts row_of_blocks     # reputs
    end

    puts strs_into_me_arr
  end

  def search word
    message = ''
    if words_found.include? word.upcase
      message = "\"#{word}\" already found"     # relay to user that word was found
    else
      if find_word_on_board(word)          # try to find word on board
        if find_word_in_dictionary word
          message = "\"#{word}\" is not in the dictionary"     # relay to user that word was found
        end
      else
        message = "\"#{word}\" is not on the board"     # relay to user that word not found
      end
      message
    end
  end

  def find_max_score_for_board!
    return @max_score unless @max_score.nil?

    user_words_found = @words_found
    user_score = @score
    words_found = Set.new

    File.open DICTIONARY_PATH, 'r' do |file|
      file.readlines.each do |line|
        find_word_on_board line.chomp
      end
    end

    max_score = @score

    @score = user_score
    puts self.to_s
    @words_found = user_words_found


    return max_score
  end

  private
    def clear_terminal_screen
      print "\e[2J" # Clear the screen
      print "\e[H" # Moves cursor to the top left of the terminal
    end
    # input : [x,y] location on boggle board
    # background info : this method is called by recursion_part_of_search()
    def should_use_array_location?(new_location, path, word)

      # not real locations on the game
      if (new_location[0] < 0       ||       # off the top border
          new_location[0] >= @size  ||       # off the bottom border
          new_location[1] < 0       ||       # off the left border
          new_location[1] >= @size)          # off the right border
            return false
      end

      if(@board[new_location[0]][new_location[1]] != word[1]  ||    # if next letter in word is not what is found on board
          path.include?(new_location))                              # if path location already exists in path
        return false
      else
        return true
      end
    end

    # called by include? method after the first letter in a word is found to check in all directions for the remaining letters in word
    def recursion_part_of_search(path, word)
      if word.length <= 1           # word was found
        @word_path = path           # save the entire path to instance variable
        return true
      end

      for offset in 0...8 # test if any adjacent locations on board is contains the next letter in word and not used already
        if should_use_array_location?([path[-1][0] + @location_offset[offset][0], path[-1][1] + @location_offset[offset][1]], path, word)
           return true if recursion_part_of_search(path.clone << [path[-1][0] + @location_offset[offset][0], path[-1][1] + @location_offset[offset][1]], word.clone.split(//).drop(1).join(""))
        end
      end
      false
    end

    # main search method called by user
    # input : word you are looking for
    def find_word_on_board(word)
      word = word.upcase
      @word_path = nil    # reset path of found word on the board if any

      for row in 0...@size do
        for col in 0...@size do
          if @board[row][col] == word[0]                    # if first letter of the word is found, then start search here
            if recursion_part_of_search([[row,col]], word)  # pass in row and col of starting location
              self.to_s                                   # update board with cool color showing path of word
              @words_found << word
              @score += word.length
              return true                                 # word was found
            end
          end
        end
      end
      false
    end

    def find_word_in_dictionary word=''
      File.open DICTIONARY_PATH, 'r' do |file|
        file.readlines.each do |line|
          return true if line.chomp == word
        end
      end
      false
    end

    def reset_default_variables
      @max_score = nil
      @max_words_could_find = nil
      @score = 0
      @words_found = Set.new
      @word_path = nil  # remove previous word path color on board during shuffle
    end
end


# driver code for Boggle2 class
def playGame

  g = BoggleBoard.new
  input = ""

  g.shake!

  informational_message = "A) Enter any word to try to find it on boggle board. \nB) \"shake!\" to start new game. \nC) 'max_score' Figure out max score  of board. \nD) Enter \"-1\" to exit"
  puts informational_message

  input = gets.chomp              # get moreinput from user

  until input == "-1"               # while user wants to keep playing
    if input == "shake!"
      g.shake!
    elsif input == 'max_score'
      puts g.find_max_score_for_board!
    else
      puts g.search(input)
      g.to_s
    end

    puts informational_message
    input = gets.chomp              # get moreinput from user
  end

  puts "Thanks for Playing!"
end
