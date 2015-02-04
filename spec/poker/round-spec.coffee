GameCommand = require('../../js/poker/game-command')
Rounds = require('../../js/poker/round')
Games = require('../../js/token-poker/base-game')
Fakes = require('./../poker/fake-time')

describe 'TimedRound', ->
  time = builder = round = null

  beforeEach ->
    builder = new Fakes.TimeBuilder().withHour(1).withMinute(0).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    round = new Rounds.TimedRound(10, time)

  it 'should have total minutes left before start', ->
    expect(round.isOver()).toBe false
    expect(round.isStarted()).toBe false
    expect(round.minutesLeft()).toBe 10
    expect(round.minutesExpired()).toBe 0
    expect(round.isRestartable()).toBe true

  it 'should have track start time', ->
    expect(round.isStarted()).toBe false
    round.start()
    expect(round.isStarted()).toBe true
    time.now = builder.withMinute(5).build()
    expect(round.minutesLeft()).toBe 5
    expect(round.isOver()).toBe false

  it 'should end after total minutes have ended', ->
    round.start()
    time.now = builder.withMinute(10).build()
    expect(round.minutesLeft()).toBe 0
    expect(round.isOver()).toBe false

    # not over until it's really over - to help
    # prevent a game from ending/restarting before
    # any end game timeouts can kick in
    time.now = builder.withMinute(11).build()
    expect(round.minutesLeft()).toBe -1
    expect(round.isOver()).toBe true

  it 'should provide reminders', ->
    round.start()
    receiver = new FakeReceiver()
    expect(receiver.called).toBe false
    time.now = builder.withMinute(8).withSecond(0).build()
    expect(round.minutesLeft()).toBe 2
    round.setAlarm(1, receiver, receiver.ring)
    time.now = builder.withMinute(9).withSecond(0).build()
    time.execCallback()
    expect(receiver.called).toBe true

  it 'should allow ending whenever', ->
    round.start()
    time.now = builder.withMinute(7).build()
    round.end()
    expect(round.isOver()).toBe true
    expect(round.isStarted()).toBe false
    expect(round.minutesLeft()).toBe 10
    expect(round.minutesExpired()).toBe 0
    expect(round.isRestartable()).toBe false

  it 'an ended round should not be able to be restarted for a time period', ->
    expect(round.isRestartable()).toBe true
    round.start()
    round.end()
    expect(round.isRestartable()).toBe false
    expect(-> (round.start())).toThrow(new Error('Next round starts in 10 seconds.'))

  it 'an ended round should be restartable after delay', ->
    round.start()
    round.end()
    expect(round.isRestartable()).toBe false
    time.now = builder.withSecond(11).build()
    expect(round.isRestartable()).toBe true
    round.start()

  it 'starts and ends are idempotent', ->
    round.start()
    round.start()
    round.end()
    time.now = builder.withSecond(11).build()
    round.start()
    round.start()

  it 'should reliably handle time math across hours', ->
    builder = new Fakes.TimeBuilder().withHour(3).withMinute(10).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    round = new Rounds.TimedRound(120, time)
    round.start()
    expect(round.minutesLeft()).toBe 120
    time.now = builder.withMinute(50).build()
    expect(round.minutesLeft()).toBe 80
    time.now = builder.withHour(4).withMinute(1).build()
    expect(round.minutesLeft()).toBe 69
    time.now = builder.withHour(4).withMinute(15).build()
    expect(round.minutesLeft()).toBe 55

  it 'should reliably handle a round across a date change', ->
    # meh - prolly unlikely, but, let's try to think i18n-y
    builder = new Fakes.TimeBuilder().withDay(1).withHour(23).withMinute(10).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    round = new Rounds.TimedRound(120, time)
    round.start()
    expect(round.minutesLeft()).toBe 120
    time.now = builder.withMinute(50).build()
    expect(round.minutesLeft()).toBe 80
    time.now = builder.withDay(2).withHour(0).withMinute(1).build()
    expect(round.minutesLeft()).toBe 69
    time.now = builder.withHour(0).withMinute(15).build()
    expect(round.minutesLeft()).toBe 55

  it 'should not worry about midnight across a month change cuz dang', ->
    # life too short it is

  it 'should be able to clearTimeouts if round terminated', ->
    round.start()
    round.cleanUp() # not sure how to fake this yet



describe 'WaitForPlayersRound', ->
  round = game = null

  beforeEach ->
    round = new Rounds.WaitForPlayersRound
    game = new FakeGame(round)
    game.addListener(round)

  it 'should default to 2 minimum players', ->
    expect(round.minimumPlayers).toBe 2

  it 'should end when minimum players have played', ->
    expect(round.isStarted()).toBe false
    expect(round.isOver()).toBe false

    game.sendCommand('glv', 'deal')
    expect(round.playersPlayed[0]).toBe 'glv'
    expect(round.isStarted()).toBe true
    expect(round.isOver()).toBe false

    game.sendCommand('sara', 'deal')
    expect(round.playersPlayed.length).toBe 2
    expect(round.isStarted()).toBe false
    expect(round.calculateNewState()).toBe 'over'
    expect(round.state).toBe 'over'
    expect(round.isOver()).toBe true

  it 'should not count same player multiple times', ->
    game.sendCommand('glv', 'deal')
    game.sendCommand('glv', 'deal')
    expect(round.playersPlayed.length).toBe 1

  it 'should set the state before calling listeners', ->
    l = new FakeListener()
    l.onRoundStateChange = (newState) ->
      throw 'isOver should be true' if newState == 'over' && !round.isOver()

    round.addListener(l)
    round.onGameCommand({playerName: 'foo'})
    round.onGameCommand({playerName: 'bar'})


class FakeReceiver
  constructor: ->
    @called = false

  ring: ->
    @called = true


class FakeGame extends Games.BaseGame
  constructor: (@round) ->
    super

  commands: -> [(new GameCommand(/^deal$/i, this.deal))]

  deal: -> return 'dealt'

  isStarted: ->
    @round.isStarted()

class FakeListener
  onRoundStateChange: (@newState) ->

