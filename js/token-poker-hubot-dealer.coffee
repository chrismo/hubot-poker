# Description:
#   Poker-ish fun with RSA Tokens
#
# Dependencies:
#   underscore
#
# Configuration:
#   TOKEN_POKER_ROOMS - Comma delimited room IDs
#
# Commands:
#   <any 6 digits> - Play a hand of token poker
#   bet <digits>   - Bet points in token poker
#   call           - Match highest bet to stay in game
#   fold           - Fold current hand and forfeit any points bet
#   poker diag - Diagnostic dump of current state
#   poker status|board|score - Display the current status, board or score (game dependent).
#   poker list games - Show the current list of available games.
#   poker admin [command] - Various admin commands.
#
# Authors:
#   chrismo
#   glv

Rooms = require('./token-poker/rooms')
Dealer = require('./token-poker/dealer')

rooms = the_robot = null

module.exports = (robot) ->
  the_robot = robot

  robot.brain.on 'loaded', =>
    rooms = new Rooms.Rooms(dealerFactory)
    if process.env.TOKEN_POKER_ROOMS
      rooms.restrictToRooms(process.env.TOKEN_POKER_ROOMS.split(','))

  robot.hear /^(\d| )+$/i, (msg) ->
    try
      dealer = currentDealer(msg)
      result = dealer.play(msg.message.user.name, msg.message.text)
      handleReply(msg, result)
    catch error
      msg.send error

  robot.hear /^bet (\d+)$/i, (msg) ->
    try
      amount = msg.match[1]
      dealer = currentDealer(msg)
      result = dealer.bet(msg.message.user.name, amount)
      handleReply(msg, result)
    catch error
      msg.send error

  robot.hear /^fold$/i, (msg) ->
    try
      amount = msg.match[1]
      dealer = currentDealer(msg)
      result = dealer.fold(msg.message.user.name)
      handleReply(msg, result)
    catch error
      msg.send error

  robot.hear /^call$/i, (msg) ->
    try
      amount = msg.match[1]
      dealer = currentDealer(msg)
      result = dealer.call(msg.message.user.name)
      handleReply(msg, result)
    catch error
      msg.send error

  robot.hear /^poker list games/i, (msg) ->
    try
      msg.send currentDealer(msg).listGames().join("\n")
    catch error
      msg.send error

  robot.hear /^poker (score|status|board|show)/i, (msg) ->
    try
      dealer = currentDealer(msg)
      msg.send dealer.getStatus()
    catch error
      msg.send error

  robot.hear /^poker diag/i, (msg) ->
    try
      msg.send "Room: #{currentRoom(msg)}"
      msg.send "Only: #{rooms.only}"
      msg.send currentDealer(msg).diagnostic()
    catch error
      msg.send error

  robot.hear /^poker admin (.*)/i, (msg) ->
    try
      dealer = currentDealer(msg)
      terms = msg.match[1].split(' ')
      command = terms[0]
      if /^play/.test(command)
        gameName = terms[1]
        msg.send dealer.adminChangeGame(msg.message.user.name, gameName)
      if /^fund/.test(command)
        # TODO: most player names are 'first last'
        playerName = terms[1]
        amount = parseInt(terms[2])
        msg.send "setting #{playerName} points to #{amount}"
        msg.send dealer.fundPlayer(playerName, amount)
      if /^ai/.test(command)
        action = terms[1]
        playerName = terms[2]
        switch
          when action == 'add'
            dealer.addAi(playerName)
          when action == 'kill'
            dealer.killAi(playerName)
    catch error
      msg.send error

  handleReply = (msg, result) ->
    if result
      msg.reply if result.toStatus then result.toStatus() else result

  currentRoom = (msg) ->
    '' + msg.message.user.room

  currentDealer = (msg) ->
    rooms.getDealerForRoom(currentRoom(msg))

  dealerFactory = (room) ->
    dealer = new Dealer(the_robot.brain.data, room)
    dealer.setListener(new GameListener(the_robot, room))
    dealer

class GameListener
  constructor: (@robot, @room) ->

  onStatus: (text) ->
    @robot.messageRoom @room, text
