module.exports.Rooms = class Rooms
  constructor: (@dealerFactory) ->
    @dealers = {}

  restrictToRooms: (@only) ->

  getDealerForRoom: (room) ->
    if @only and room not in @only
      throw 'No poker in this room.'

    if @dealers[room]
      @dealers[room]
    else
      @dealers[room] = @dealerFactory(room)
