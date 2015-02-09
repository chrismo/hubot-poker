# msg.message.user.room
Rooms = require('../../js/poker/rooms')

describe 'Rooms', ->
  rooms = null

  beforeEach ->
    rooms = new Rooms.Rooms(dealerFactory)

  it 'should create or return existing dealer', ->
    dealerA = rooms.getDealerForRoom('a')
    expect(dealerA.room).toBe 'a'
    dealerA2 = rooms.getDealerForRoom('a')
    expect(dealerA).toBe dealerA2

  it 'should have a list of supported rooms', ->
    rooms.restrictToRooms(['a', 'b'])
    expect(rooms.getDealerForRoom('a').room).toBe 'a'
    expect(rooms.getDealerForRoom('c')).toBe undefined

  dealerFactory = (room) ->
    new FakeDealer(room)

class FakeDealer
  constructor: (@room) ->
