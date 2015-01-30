module.exports = class GameCommand
  constructor: (@regexp, @callback, @ai) ->

  execute: (args) ->
    parsed = @regexp.exec(args)
    if parsed
      new ParsedGameCommand(@callback, parsed)


class ParsedGameCommand
  constructor: (@callback, @parsedArgs) ->
