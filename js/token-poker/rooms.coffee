module.exports.Rooms = class Rooms
  constructor: (@dealerFactory) ->
    @dealers = {}

  restrictToRooms: (@only) ->

  getDealerForRoom: (room) ->
    return if @only and room not in @only

    if @dealers[room]
      @dealers[room]
    else
      @dealers[room] = @dealerFactory(room)
