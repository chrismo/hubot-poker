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
#   poker diag               - Diagnostic dump of current state.
#   poker help               - Help instructions on current game.
#   poker list games         - Show the current list of available games.
#   poker status|board|score - Display the current game status (game dependent).
#   poker admin play [game]            - Change game being played.
#   poker admin fund [points] [player] - Grant player points (game dependent).
#   poker admin ai add [name]          - Add AI Player (AIs are VERY dumb).
#   poker admin ai kill [name]         - You'd be doing us all a favor.
#
# Authors:
#   chrismo
#   glv

_ = require('underscore')
Rooms = require('./token-poker/rooms')
Dealer = require('./token-poker/dealer')

rooms = the_robot = null

module.exports = (robot) ->
  the_robot = robot
  foldListener = null

  robot.brain.on 'loaded', =>
    rooms = new Rooms.Rooms(dealerFactory)
    if process.env.TOKEN_POKER_ROOMS
      rooms.restrictToRooms(process.env.TOKEN_POKER_ROOMS.split(','))

  # catch-all for game commands
  robot.hear /.*/i, (msg) ->
    try
      dealer = currentDealer(msg)
      result = dealer.sendToGame(msg.message.user.name, msg.message.text)
      handleReply(msg, result)
    catch error
      msg.send error

  robot.hear /^poker help/i, (msg) ->
    try
      dealer = currentDealer(msg)
      result = dealer.help()
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

  # TODO: optionally protect admin commands by list of admins
  robot.hear /^poker admin (.*)/i, (msg) ->
    try
      dealer = currentDealer(msg)
      terms = msg.match[1].split(' ')
      command = terms.shift()
      if /^play/.test(command)
        gameName = terms.shift()
        msg.send dealer.changeGame(msg.message.user.name, gameName)
      if /^fund/.test(command)
        amount = parseInt(terms.shift())
        playerName = terms.join(' ')
        msg.send "setting #{playerName} points to #{amount}"
        msg.send dealer.fundPlayer(playerName, amount)
      if /^ai/.test(command)
        action = terms.shift()
        playerName = terms.join(' ')
        switch
          when action == 'add'
            dealer.addAi(playerName)
          when action == 'kill'
            dealer.killAi(playerName)
    catch error
      msg.send error

  handleReply = (msg, result) ->
    for result in _.flatten([result])
      if result
        msg.reply if result.toStatus then result.toStatus() else result

  currentRoom = (msg) ->
    '' + msg.message.user.room

  currentDealer = (msg) ->
    # TODO - DO NOT THROW ON THIS IF NOT ENABLED, JUST ROLL ON AND HAVE ALL COMMANDS IGNORE
    # esp. a problem with convenient command regexs that don't require addressing hubot
    rooms.getDealerForRoom(currentRoom(msg))

  dealerFactory = (room) ->
    dealer = new Dealer(the_robot.brain.data, room)
    dealer.setListener(new GameListener(the_robot, room))
    dealer

class GameListener
  constructor: (@robot, @room) ->

  onStatus: (text) ->
    @robot.messageRoom @room, text

  onFinishRound: ->