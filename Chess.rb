# encoding: utf-8

class Chess
  attr_accessor :board


  def initialize
    @board = Board.new
    @b = HumanPlayer.new(:b)
    @w = HumanPlayer.new(:w)
  end

  def greeting
    puts "Welcome to chess!"
  end

  def end_game
    puts "Thank you for playing!"
  end

  def play
    greeting

    while true
      half_turn(@w)
      half_turn(@b)
    end

    end_game
  end

  def half_turn(player)
    @board.show
    # until legal_move_made
    color = player.color == :w ? "White" : "Black"
    puts "#{color} player's turn"
    s, f = player.attempt_move
    # check if coordinates are legal, if yes, pass them to move
    @board.move(s,f)
  end
end

class HumanPlayer
  attr_accessor :color

  def initialize(color)
    @color = color
  end

  def attempt_move
    puts "Please enter your move (e.g. e2 e4)"
    start, finish = gets.chomp.split
  end

end

class Board
  attr_accessor :grid

  def initialize
    @grid = Array.new(8) {Array.new(8, nil)}

    setup_pieces(:w)
    setup_pieces(:b)
  end

  def setup_pieces(color)
    p_row, b_row = (color == :w) ? [6,7] : [1,0]

    (0..7).each {|col| @grid[p_row][col] = Pawn.new(color, [p_row,col],self)}
    [0,7].each {|col| @grid[b_row][col] = Rook.new(color, [b_row,col],self)}
    [1,6].each {|col| @grid[b_row][col] = Knight.new(color, [b_row, col],self)}
    [2,5].each {|col| @grid[b_row][col] = Bishop.new(color, [b_row, col],self)}
    @grid[b_row][3] = Queen.new(color, [b_row,3], self)
    @grid[b_row][4] = King.new(color, [b_row,3], self)
  end

  def show
    puts display
  end

  def display
    first_row = "  a b c d e f g h"
    result = [first_row]
    @grid.size.times {|i| result << display_row(i)}
    result
  end

  def display_row(i)
    r = (8 - i).to_s
    @grid[i].each {|sq| r << (sq.nil? ? "  " : " #{sq.rep}")}
    r
  end

  def get_piece(coords)
    @grid[coords[0]][coords[1]]
  end

  def piece_at(pos)
    get_piece(Board.pos_to_coords(pos))
  end

  def move(start, finish)
    move_piece(Board.pos_to_coords(start), Board.pos_to_coords(finish))
  end

  def move_piece(start, finish)
    x, y = start
    a, b = finish
    @grid[a][b] = @grid[x][y]
    @grid[a][b].coords = [a,b]
    @grid[x][y] = nil
  end

  def self.on_board?(pos)
    pos.all? {|coord| coord.between?(0, 7)}
  end

  def self.pos_to_coords(pos)
    letter, number = pos.split("")
    y = letter.ord - 'a'.ord
    x = 8 - number.to_i
    [x, y]
  end

  def self.coords_to_pos(coords)
    x, y = coords
    letter = (y.ord + 'a'.ord).chr
    number = 8 - x
    "#{letter}#{number}"
  end

  def move_legal
    return your_piece && not_check && move_in_moveset
  end

  def your_piece?(start, player)
    return false unless piece_at(start)
    piece_at(start).color == player.color
  end

  def pieces_by_color(color)
    @grid.flatten.select {|square| square && square.color == color}
  end

  def move_in_moveset(start, finish)
    get_piece(start).move_set.include?(finish)
  end

  def complete_moveset(color)
    possible_moves = []
    pieces_by_color(color).each do |piece|
      possible_moves += piece.move_set
    end

    possible_moves.uniq
  end

  def color_in_check
    [[:w, :b], [:b, :w]].each do |color, o_color|
      o_king = pieces_by_color(o_color).select {|piece| piece.is_a?(King)}
      return o_color if complete_moveset(color).include?(o_king.coords)
    end

    nil
  end
end

class Piece
  attr_accessor :coords, :color, :rep, :board

  def initialize(color, coords, board)
    @color = color
    @coords = coords
    @board = board
  end

  def same_color?(other_piece)
    other_piece.color == @color
  end

  def move_set

  end
end

class Knight < Piece
  def initialize(color, coords, board)
    super(color, coords, board)
    case color
    when :w
      @rep = "♘"
    when :b
      @rep = "♞"
    end
  end

  MOVES = [
    [1,2],
    [2,1],
    [1,-2],
    [2,-1],
    [-1,2],
    [-2,1],
    [-1,-2],
    [-2,-1]
  ]

  def move_set
    possible_moves = []
    MOVES.each do |dx, dy|
      sq_to_add = [coords[0] + dx, coords[1] + dy]

      next unless Board.on_board?(sq_to_add)
      sq_content = @board.get_piece(sq_to_add)
      if sq_content.nil?
        possible_moves << sq_to_add
      else
        (possible_moves << sq_to_add) unless same_color?(sq_content)
      end
    end

    possible_moves
  end
end

module SlidingMove
  def build_move_set(moves)
    possible_moves = []
    x,y = coords

    moves.each do |dx, dy|
      (1..7).each do |i|
        sq_to_add = [x + i*dx, y + i*dy]

        next unless Board.on_board?(sq_to_add)
        sq_content = @board.get_piece(sq_to_add)

        if sq_content.nil?
          possible_moves << sq_to_add
        else
          (possible_moves << sq_to_add) unless same_color?(sq_content)
          break
        end
      end
    end

    possible_moves
  end
end

class Bishop < Piece
  def initialize(color, coords, board)
    super(color, coords, board)
    case color
    when :w
      @rep = "♗"
    when :b
      @rep = "♝"
    end
  end

  MOVES = [
    [1,1],
    [1,-1],
    [-1,1],
    [-1,-1]
  ]

  include SlidingMove

  def move_set
    build_move_set(MOVES)
  end
end

class Rook < Piece
  def initialize(color, coords, board)
    super(color, coords, board)
    case color
    when :w
      @rep = "♖"
    when :b
      @rep = "♜"
    end
  end

  MOVES = [
    [0,1],
    [1,0],
    [0,-1],
    [-1,0]
  ]

  include SlidingMove

  def move_set
    build_move_set(MOVES)
  end
end

class Queen < Piece
  def initialize(color, coords, board)
    super(color, coords, board)
    case color
    when :w
      @rep = "♕"
    when :b
      @rep = "♛"
    end
  end

  MOVES = [
    [0,1],
    [1,0],
    [0,-1],
    [-1,0],
    [1,1],
    [1,-1],
    [-1,1],
    [-1,-1]
  ]

  include SlidingMove

  def move_set
    build_move_set(MOVES)
  end
end

class King < Piece
  def initialize(color, coords, board)
    super(color, coords, board)
    case color
    when :w
      @rep = "♔"
    when :b
      @rep = "♚"
    end
  end

  MOVES = [
    [0,1],
    [1,0],
    [0,-1],
    [-1,0],
    [1,1],
    [1,-1],
    [-1,1],
    [-1,-1]
  ]

  def move_set
    possible_moves = []

    MOVES.each do |dx, dy|
      x,y = @coords
      sq_to_add = [x + dx, y + dy]

      next unless Board.on_board?(sq_to_add)
      sq_content = @board.get_piece(sq_to_add)

      if sq_content.nil?
        possible_moves << sq_to_add
      else
        (possible_moves << sq_to_add) unless same_color?(sq_content)
      end
    end

    possible_moves
  end
end

class Pawn < Piece
  def initialize(color, coords, board)
    super(color, coords, board)
    case color
    when :w
      @rep = "♙"
    when :b
      @rep = "♟"
    end
  end

  def move_set
    possible_moves = []
    cur_x, cur_y = self.coords
    m = (self.color == :b) ? 1 : -1
    moves = {
      :forw => [[m,0], [2 * m,0]],
      :diag => [[m,1], [m,-1]]
    }


    # check if one step forward moves are allowed
    sq_to_add = [cur_x + moves[:forw][0][0], cur_y + moves[:forw][0][1]]
    one_step = Board.on_board?(sq_to_add) && (@board.get_piece(sq_to_add).nil?)
    if one_step
      possible_moves << sq_to_add
    end

    # check if two step forward moves are allowed
    sq_to_add = [cur_x + moves[:forw][1][0], cur_y + moves[:forw][1][1]]
    two_step = Board.on_board?(sq_to_add) && (@board.get_piece(sq_to_add).nil?)
    if (one_step && two_step) && [1,6].include?(cur_x)
      possible_moves << sq_to_add
    end

    # check if diagonal moves are allowed
    moves[:diag].each do |dx, dy|
      sq_to_add = [cur_x + dx, cur_y + dy]
      sq_content = @board.get_piece(sq_to_add)
      if sq_content && !same_color?(sq_content)
        (possible_moves << sq_to_add) unless same_color?(sq_content)
      end
    end

    possible_moves
  end
end





