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
Rooms = require('./poker/rooms')
Dealer = require('./poker/dealer')

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
      return if !dealer
      result = dealer.sendToGame(msg.message.user.name, msg.message.text)
      handleReply(msg, result)
    catch error
      msg.send error

  robot.hear /^poker help/i, (msg) ->
    try
      dealer = currentDealer(msg)
      return if !dealer
      result = dealer.help()
      handleReply(msg, result)
    catch error
      msg.send error

  robot.hear /^poker list games/i, (msg) ->
    try
      dealer = currentDealer(msg)
      return if !dealer
      msg.send formatResponse(dealer.listGames().join("\n"))
    catch error
      msg.send error

  robot.hear /^poker (score|status|board|show)/i, (msg) ->
    try
      dealer = currentDealer(msg)
      return if !dealer
      msg.send formatResponse(dealer.getStatus())
    catch error
      msg.send error

  robot.hear /^poker diag/i, (msg) ->
    try
      response = "Room: #{currentRoom(msg)}\nOnly: #{rooms.only}\n"
      dealer = currentDealer(msg)
      if dealer
        response = response + dealer.diagnostic()
      msg.send formatResponse(response)
    catch error
      msg.send error

  robot.hear /^poker admin (.*)/i, (msg) ->
    # OMG - It's like I'm trying to kill Uncle Bob with this code.
    try
      dealer = currentDealer(msg)
      return if !dealer
      terms = msg.match[1].split(' ')
      command = terms.shift()
      if /^play/.test(command)
        gameName = terms.shift()
        msg.send dealer.changeGame(msg.message.user.name, gameName)
      if /^fund/.test(command)
        amount = parseInt(terms.shift())
        playerName = terms.join(' ')
        msg.send formatResponse("setting #{playerName} points to #{amount}")
        msg.send formatResponse(dealer.fundPlayer(playerName, amount))
      if /^ai/.test(command)
        action = terms.shift()
        playerName = terms.join(' ')
        switch
          when action == 'add'
            added = []
            if playerName == 'horde'
              for name in ['Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot', 'Golf', 'Hotel']
                ai = dealer.addAi(name)
                ai.queueSomething((Math.random() * 10))
                added.push(name)
            else
              ai = dealer.addAi(playerName)
              ai.doSomething(0)
              added.push(playerName)

            msg.send "Added #{added.join(', ')}"
          when action == 'kill'
            if playerName == 'all'
              dealer.killAllAis()
            else
              dealer.killAi(playerName)

            msg.send "Killed #{playerName}"
    catch error
      console.log(error.stack)
      msg.send error.message

  handleReply = (msg, result) ->
    response = formatResponse(result)
    msg.reply response if response?

  formatResponse = (response) ->
    if _.isArray(response)
      return response.join("\n")
    else
      for response in _.flatten([response])
        if response?
          text = if response.toStatus then response.toStatus() else response
          return if text.indexOf("\n") > -1 then "```\n#{text}\n```\n" else text
        else
          return null

  currentRoom = (msg) ->
    '' + msg.message.user.room

  currentDealer = (msg) ->
    rooms.getDealerForRoom(currentRoom(msg))

  dealerFactory = (room) ->
    dealer = new Dealer(the_robot.brain.data, room)
    dealer.addListener(new GameListener(the_robot, room))
    dealer

class GameListener
  constructor: (@robot, @room) ->

  onStatus: (text) ->
    @robot.messageRoom @room, if _.isArray(text) then text.join("\n") else text

  canPushToPlayer: (playerName) ->
    @robot.adapter.client.getDMByName(playerName) != undefined

  onPushToPlayer: (playerName, msg) ->
    @robot.adapter.send {room: playerName}, msg if @robot.brain.userForName(playerName)

  onStartRound: ->

  onFinishRound: ->
