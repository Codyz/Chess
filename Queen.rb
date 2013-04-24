# encoding: utf-8

require_relative "SlidingMove.rb"
require_relative "Piece.rb"

class Queen < Piece
  @@MOVES = [
    [0,1],
    [1,0],
    [0,-1],
    [-1,0],
    [1,1],
    [1,-1],
    [-1,1],
    [-1,-1]
  ]

  def initialize(color, coords, board)
    super(color, coords, board)
    case color
    when :w
      @rep = "♕"
    when :b
      @rep = "♛"
    end
  end

  include SlidingMove

  def move_set
    build_move_set(@@MOVES)
  end
end