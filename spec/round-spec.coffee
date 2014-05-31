TokenPoker = require('../js/token-poker/round')
Fakes = require('./fake-time')

describe 'TimedRound', ->
  time = builder = round = null

  beforeEach ->
    builder = new Fakes.TimeBuilder().withHour(1).withMinute(0).withSecond(0)
    time = new Fakes.FakeTimeProvider(builder.build())
    round = new TokenPoker.TimedRound(10, time)

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
    round = new TokenPoker.TimedRound(120, time)
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
    round = new TokenPoker.TimedRound(120, time)
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


class FakeReceiver
  constructor: ->
    @called = false

  ring: ->
    @called = true
