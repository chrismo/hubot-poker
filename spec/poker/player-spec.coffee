Player = require('../../js/poker/player')

describe 'Player', ->
  it 'should record total points owned', ->
    # useful for betting
    player = new Player('chrismo', 123)
    expect(player.points).toBe 123
