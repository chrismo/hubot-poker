class Round
  constructor: ->
    @listeners = []

  start: ->
    return if this.isStarted()
    this.throwIfNotRestartable()

  throwIfNotRestartable: ->
    throw "Round not restartable" if this.isRestartable && !this.isRestartable()

  end: ->

  isStarted: ->
    throw "Subclass should implement"

  isOver: ->
    throw "Subclass should implement"

  isRestartable: ->
    true # deprecated

  addListener: (listener) ->
    @listeners ||= []
    @listeners.push(listener)

  cleanUp: ->
    # optional, in case a round needs to ensure things like timeouts are cleared


# this class is getting ridiculous, with its 3 states:
# isStarted(), isOver(), isRestartable() -- at least implementation-wise.
# Waaay too much boolean Jenga
module.exports.TimedRound = class TimedRound extends Round
  constructor: (@total, @timeProvider) ->
    @timeProvider ||= new TimeProvider
    # TODO: restartDelay can just be another round instance, right?
    @restartDelayInSeconds = 10
    @listeners = []
    @timeouts = []

  start: ->
    super
    @startTime = @timeProvider.getTime()
    @endTime = undefined
    this.setAlarm(0, this, this.end)

  throwIfNotRestartable: ->
    throw "Next round starts in #{Math.floor(this.restartDelaySecondsLeft())} seconds." if !this.isRestartable()

  minutesLeft: ->
    @total - this.minutesExpired()

  minutesExpired: ->
    if @startTime
      # no built-in time span in Javascript? moment.js or somesuch can do this
      # but don't want to add another dependency currently.
      dayDiff = this.now().getUTCDate() - @startTime.getUTCDate() # confusing method name
      hrsDiff = this.now().getUTCHours() - @startTime.getUTCHours()
      minDiff = this.now().getUTCMinutes() - @startTime.getUTCMinutes()
      (dayDiff * 24 * 60) + (hrsDiff * 60) + minDiff
    else
      0

  isStarted: ->
    @startTime != undefined && @endTime == undefined

  isOver: ->
    @endTime != undefined || this.minutesLeft() < 0

  now: ->
    @timeProvider.getTime()

  setAlarm: (minutesLeft, callbackThis, callback) ->
    delayInMinutes = Math.max(0, this.minutesLeft() - minutesLeft)
    delayInMsecs = delayInMinutes * 60 * 1000
    @timeouts.push(@timeProvider.setTimeout((-> (callback.call(callbackThis))), delayInMsecs))

  end: ->
    super
    @endTime = this.now()
    @startTime = undefined
    l.onRoundStateChange('over') for l in @listeners

  isRestartable: ->
    @startTime == undefined && (@endTime == undefined || this.restartDelayExpired())

  restartDelayExpired: ->
    this.restartDelaySecondsLeft() <= 0

  restartDelaySecondsLeft: ->
    @restartDelayInSeconds - ((this.now() - @endTime) / 1000)

  cleanUp: ->
    @timeProvider.clearTimeout(timeout) for timeout in @timeouts
    @timeouts = []


module.exports.TimeProvider = class TimeProvider
  getTime: ->
    new Date()

  setTimeout: (callback, delayInMsecs) ->
    setTimeout(callback, delayInMsecs)

  clearTimeout: (timeout) ->
    clearTimeout(timeout)


module.exports.WaitForPlayersRound = class WaitForPlayersRound extends Round
  constructor: (@minimumPlayers=2) ->
    super
    @playersPlayed = []
    @state = 'not_started'

  isStarted: ->
    @state == 'started'

  isOver: ->
    @state == 'over'

  onGameCommand: (playerCommand, parsedCommand, commandResult) ->
    playerName = playerCommand.playerName
    if (@playersPlayed.indexOf(playerName) == -1)
      @playersPlayed.push(playerName)
      this.updateState()

  updateState: ->
    newState = this.calculateNewState()

    if newState != @state
      @state = newState
      l.onRoundStateChange(newState) for l in @listeners

  calculateNewState: ->
    switch
      when @playersPlayed.length == 0 then 'not_started'
      when @playersPlayed.length >= @minimumPlayers then 'over'
      else 'started'
