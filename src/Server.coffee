EngineBuilder = require './EngineBuilder'
Action = require('ecstasy').Action

clientId = 0

module.exports = (io) ->
  console.log 'Starting game engine'
  engine = EngineBuilder.build true 
  console.log 'Hooking protocols to game engine'
  engine.s 'protocol',
    action: (turn, action) ->
      io.emit 'action', action.serialize()
  prevTime = new Date().getTime()
  setInterval () ->
    newTime = new Date().getTime()
    engine.update newTime - prevTime
    prevTime = newTime
  , 16
  setInterval () ->
    console.log 'synchronize'
    io.emit 'engine', engine.serialize()
  , 4000
  io.on 'connection', (socket) ->
    console.log 'A client has connected'
    console.log 'Asking for nickname'
    inited = false
    socket.on 'init', (nickname) ->
      return if inited
      inited = true
      console.log 'Sending engine data'
      socket.emit 'engine', engine.serialize()
      console.log 'Generating Player for client'
      playerName = nickname || 'Player '+(clientId++)
      action = engine.aa 'playerAdd', null, null,
        name: playerName
      playerId = action.result
      socket.emit 'player', playerId
      socket.on 'action', (data) ->
        try
          data.player = playerId
          engine.a Action.deserialize(engine, data)
        catch e
          throw e
      socket.on 'disconnect', () ->
        console.log 'disconnected'
        try
          engine.aa 'playerRemove', null, engine.e(playerId)
        catch e
          throw e
    
  console.log 'Started accepting sockets'
