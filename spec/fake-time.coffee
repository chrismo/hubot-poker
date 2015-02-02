module.exports.FakeTimeProvider = class FakeTimeProvider
  constructor: (@now) ->
    @callbacks = {}

  getTime: ->
    @now

  setTimeout: (callback, delayInMsecs) ->
    callbackWhen = new Date(@now.getTime() + delayInMsecs)
    @callbacks[callbackWhen.toUTCString()] = callback

  clearTimeout: (timeout) ->
    timeout

  execCallback: ->
    callback = @callbacks[@now.toUTCString()]
    throw "none found in #{@callbacks}" if not callback
    callback() if callback

module.exports.TimeBuilder = class TimeBuilder
  constructor: ->
    now = new Date()
    @year = now.getUTCFullYear()
    @month = now.getUTCMonth()
    @day = now.getUTCDate()
    @hour = now.getUTCHours()
    @min = now.getUTCMinutes()
    @sec = now.getUTCSeconds()

  build: ->
    new Date(Date.UTC(@year, @month, @day, @hour, @min, @sec, 0))

  withDay: (day) ->
    @day = day
    this

  withHour: (hour) ->
    @hour = hour
    this

  withMinute: (minute) ->
    @min = minute
    this

  withSecond: (second) ->
    @sec = second
    this

  makeTime: (hour, min, sec) ->
    sec ||= 0
    new TimeBuilder().withHour(hour).withMinute(min).withSecond(sec).build()
