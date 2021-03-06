# encoding: utf-8

require_relative "Piece.rb"
require_relative "Pawn.rb"
require_relative "Knight.rb"
require_relative "Rook.rb"
require_relative "Bishop.rb"
require_relative "King.rb"
require_relative "Queen.rb"

class Board
  # Class methods
  def self.on_board?(coords)
    coords.all? {|coord| coord.between?(0, 7)}
  end

  def self.pos_to_coords(pos)
    letter, number = pos.split("")
    col = letter.ord - 'a'.ord
    row = 8 - number.to_i
    [row, col]
  end

  def self.coords_to_pos(coords)
    row, col = coords
    letter = (col.ord + 'a'.ord).chr
    number = 8 - row
    "#{letter}#{number}"
  end

  # Instance methods
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
    @grid[b_row][4] = King.new(color, [b_row,4], self)
  end

  def show
    puts display
  end

  def color_in_checkmate
    [:w, :b].each do |color|
      if color_in_check == color && !can_avoid_check?(color)
        return color
      end
    end

    nil
  end

  def color_in_stalemate
    return nil if color_in_check
    [:w, :b].each do |color|
      return color if !can_avoid_check?(color)
    end

    nil
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

  def move_legal?(color, start, finish)
    return false if start == finish
    start, finish = [Board.pos_to_coords(start), Board.pos_to_coords(finish)]
    return false unless your_piece?(color, start)
    return false unless move_in_moveset?(start, finish)
    return false unless move_avoids_check?(start, finish)
    true
  end

  private

  def display
    first_row = "  a b c d e f g h"
    result = [first_row]
    @grid.size.times {|i| result << display_row(i)}
    result
  end

  def display_row(i)
    row = (8 - i).to_s
    @grid[i].each {|sq| row << (sq.nil? ? "  " : " #{sq.rep}")}
    row
  end

  def move_piece(start, finish)
    s_row, s_col = start
    f_row, f_col = finish
    @grid[f_row][f_col] = @grid[s_row][s_col]
    @grid[f_row][f_col].coords = [f_row, f_col]
    @grid[s_row][s_col] = nil
  end

  def move_avoids_check?(start, finish)
    piece_to_move = get_piece(start)
    temp_square = get_piece(finish)

    move_piece(start, finish)
    if color_in_check != piece_to_move.color
      move_piece(finish, start)
      @grid[finish[0]][finish[1]] = temp_square
      true
    else
      move_piece(finish, start)
      @grid[finish[0]][finish[1]] = temp_square

      false
    end
  end

  def your_piece?(color, start)
    return false unless get_piece(start)
    get_piece(start).color == color
  end

  def pieces_by_color(color)
    @grid.flatten.select {|square| square && square.color == color}
  end

  def move_in_moveset?(start, finish)
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
      o_king = pieces_by_color(o_color).find {|piece| piece.is_a?(King)}
      return o_color if complete_moveset(color).include?(o_king.coords)
    end

    nil
  end

  def can_avoid_check?(color)
    pieces = pieces_by_color(color)
    pieces.each do |piece|
      piece.move_set.each do |finish|
        return true if move_avoids_check?(piece.coords, finish)
      end
    end

    false
  end
end
