# Boggle game with driver code to run the program. 
# visual shuffle sequence
# board will show you in color the word you are looking for if it exists.

# FIX THIS: downside it doesn't overwrite the previous boards. 


class BoggleBoard
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

    down      =  1
    right     =  1
    up        = -1
    left      = -1
    @location_offset = [ [up ,0],
                         [up, right], 
                         [0, right],
                         [down, right],
                         [down, 0],
                         [down, left], 
                         [0, left], 
                         [up, left] ]
  end
  
  def shake!
    @word_path = nil  # remove previous word path color on board during shuffle
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
      print "\e[2J\e[f"
      self.to_s
      sleep(0.1)
    end
  end

  def to_s                # print boggle board 

     print "\e[2J" # Clear the screen
     print "\e[H" # Moves cursor to the top left of the terminal
    
    strs_into_me_arr = []
    for row in 0...@size do
      row_of_blocks = ""
      for col in 0...@size do
        # print makes the letter at each location [row, col] along the path that the word was found in possible parameter color_these_locations_arr
        if @word_path != nil   # if word recently found
          row_of_blocks += (@word_path.include?([row, col]) == true ? "\033[96m" : "")  + "#{@board[row][col]} " + (@word_path.include?([row, col]) == true ? "\033[0m" : "")
        else                              # no word recently found. Don't use colored letters in locations
          row_of_blocks += "#{@board[row][col]} "  # 
        end
      end
      strs_into_me_arr << row_of_blocks
      #puts row_of_blocks     # reputs
    end

    puts strs_into_me_arr
  end

  # main search method called by user
  # input : word you are looking for
  def include?(word)
    word = word.upcase
    @word_path = nil    # reset path of found word on the board if any
    return "Word Must Be At Least 3 Letters Long" if word.length < 3

    for row in 0...@size do
      for col in 0...@size do
        if @board[row][col] == word[0]                    # if first letter of the word is found, then start search here
          if recursion_part_of_search([[row,col]], word)  # pass in row and col of starting location
            self.to_s                                     # update board with cool color showing path of word
            return true                                   # word was found
          end
        end
      end
    end
    false
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
end


# driver code for Boggle2 class
def playGame()

  g = BoggleBoard.new
  g.to_s

  input = ""

  puts "Type \"shake!\" to start game. Enter \"-1\" to quit"
  until (input == "shake!" || input == "-1")
    input = gets.chomp              # get input from user
  end

  until input == "-1"               # while user wants to keep playing
    if input == "shake!"
      g.shake!
    else
      if g.include?(input)          # try to find word on board
        puts "#{input} found"     # relay to user that word was found
      else                          
        puts "no \"#{input}\" "     # relay to user that word not found
      end
    end
    
    puts "enter any word to try to find it on boggle board. \"shake!\" to start new game \"-1\" to exit"
    input = gets.chomp              # get moreinput from user
  end

  puts "Thanks for Playing!"
end

playGame()
