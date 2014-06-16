# this class is getting ridiculous, with its 3 states:
# isStarted(), isOver(), isRestartable() -- at least implementation-wise.
# Waaay too much boolean Jenga
module.exports.TimedRound = class TimedRound
  constructor: (@total, @timeProvider) ->
    @timeProvider ||= new TimeProvider
    @restartDelayInSeconds = 10

  start: ->
    return if this.isStarted()
    this.throwIfNotRestartable()
    @startTime = @timeProvider.getTime()
    @endTime = undefined

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
    @timeProvider.setTimeout((-> (callback.call(callbackThis))), delayInMsecs)

  end: ->
    @endTime = this.now()
    @startTime = undefined

  isRestartable: ->
    @startTime == undefined && (@endTime == undefined || this.restartDelayExpired())

  restartDelayExpired: ->
    this.restartDelaySecondsLeft() <= 0

  restartDelaySecondsLeft: ->
    @restartDelayInSeconds - ((this.now() - @endTime) / 1000)

class TimeProvider
  getTime: ->
    new Date()

  setTimeout: (callback, delayInMsecs) ->
    setTimeout(callback, delayInMsecs)
