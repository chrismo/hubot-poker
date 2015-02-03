Pot = require('../../js/poker/pot')


describe 'Pot with ante', ->
  pot = null

  beforeEach ->
    pot = new Pot(1)

  it 'should ante up players when added', ->
    player = new FakePlayer(2)
    pot.addPlayer(player)
    expect(player.points).toBe 1
    expect(pot.points).toBe 1

  it 'should prevent player from being added more than once', ->
    player = new FakePlayer(2)
    pot.addPlayer(player)
    pot.addPlayer(player)
    expect(player.points).toBe 1

  it 'should not allow a player to add with no points', ->
    player = new FakePlayer(0)
    expect(-> pot.addPlayer(player)).toThrow 'no dough, no show'
    expect(pot.points).toBe 0

  it 'should finish round by settling up short players automatically', ->
    a = new FakePlayer(100, 'a')
    b = new FakePlayer(100, 'b')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.bet(a, 10)
    pot.bet(b, 12)
    expect(a.points).toBe 89
    expect(a.totalBet).toBe 11
    expect(b.points).toBe 87
    expect(pot.points).toBe 24

    pot.settleUp()
    expect(a.points).toBe 87

  it 'should take all available if bet is more than what player has', ->
    a = new FakePlayer(20, 'a')
    b = new FakePlayer(10, 'b')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.bet(a, 12)
    pot.bet(b, 100000)
    expect(b.points).toBe 0
    expect(pot.points).toBe 23

  it 'should ignore a bet less than 1', ->
    a = new FakePlayer(20, 'a')
    b = new FakePlayer(10, 'b')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.bet(a, 12)
    pot.bet(b, -100000)
    expect(b.points).toBe 9

  it 'should take all available if owed is more than what player has', ->
    a = new FakePlayer(20, 'a')
    b = new FakePlayer(10, 'b')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.bet(a, 12)
    expect(a.points).toBe 7
    expect(b.points).toBe 9
    expect(pot.points).toBe 14

    pot.settleUp()
    expect(b.points).toBe 0
    expect(pot.points).toBe 23

  it 'should do nothing on settle up if no one has bet anything', ->
    # ante-only round
    a = new FakePlayer(100, 'a')
    b = new FakePlayer(100, 'b')
    pot.addPlayer(a)
    pot.addPlayer(b)
    expect(a.points).toBe 99
    expect(b.points).toBe 99
    expect(pot.points).toBe 2

    pot.settleUp()
    expect(a.points).toBe 99
    expect(b.points).toBe 99
    expect(pot.points).toBe 2

  it 'should remove players if they fold', ->
    a = new FakePlayer(100, 'a')
    b = new FakePlayer(100, 'b')
    c = new FakePlayer(100, 'c')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.addPlayer(c)
    pot.bet(a, 50)
    pot.fold(b)
    pot.settleUp()
    expect(a.points).toBe 49
    expect(b.points).toBe 99
    expect(c.points).toBe 49

  it 'should not take a bet from a player not already added', ->
    expect(-> pot.bet(new FakePlayer(1))).toThrow 'player undefined not added.'

  it 'should award pot amount to winner', ->
    a = new FakePlayer(20, 'a')
    b = new FakePlayer(10, 'b')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.bet(a, 12)

    pot.settleUp()
    pot.goesTo(b)
    expect(a.points).toBe 7
    expect(a.totalBet).toBe 0
    expect(b.points).toBe 23
    expect(b.totalBet).toBe 0
    expect(pot.points).toBe 0
    expect(pot.players.length).toBe 0

  it 'should handle bet amounts as string', ->
    a = new FakePlayer(20, 'a')
    pot.addPlayer(a)
    pot.bet(a, '12')
    expect(a.points).toBe 7

  it 'should handle call method to settle up an individual', ->
    a = new FakePlayer(21, 'a')
    b = new FakePlayer(21, 'b')
    c = new FakePlayer(21, 'c')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.addPlayer(c)
    pot.bet(a, '15')
    pot.bet(b, '10')
    pot.bet(c, '5')
    pot.call(b)
    expect(a.points).toBe 5
    expect(b.points).toBe 5
    expect(c.points).toBe 15

  it 'should say all bets settled if all bets are above ante and equal', ->
    a = new FakePlayer(21, 'a')
    b = new FakePlayer(21, 'b')
    c = new FakePlayer(21, 'c')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.addPlayer(c)
    expect(pot.allBetsSettled()).toBe false
    pot.bet(a, '3')
    expect(pot.allBetsSettled()).toBe false
    pot.call(b)
    expect(pot.allBetsSettled()).toBe false
    pot.bet(c, '3')
    expect(pot.allBetsSettled()).toBe true

  it 'should say all bets settled when a player under max but all in', ->
    a = new FakePlayer(21, 'a')
    b = new FakePlayer(11, 'b')
    c = new FakePlayer(21, 'c')
    pot.addPlayer(a)
    pot.addPlayer(b)
    pot.addPlayer(c)
    pot.bet(a, '21')
    pot.call(b)
    pot.bet(c, '21')
    expect(pot.allBetsSettled()).toBe true


class FakePlayer
  constructor: (@points, @name) ->
