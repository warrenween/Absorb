Action = require('ecstasy').Action
assert = require 'assert'

class ControlComponent
  constructor: ({@owner}) ->

ControlSystem =  
  add: (engine) ->
    @engine = engine
    @entities = engine.e 'control', 'blob'
  update: (delta) ->
    for entity in @entities
      continue unless entity.c('control').owner?
      player = @engine.e(entity.c('control').owner).c 'player'
      continue unless player?
      entBlob = entity.c 'blob'
      entBlob.velX += (player.mouseX - entBlob.velX) / 30
      entBlob.velY += (player.mouseY - entBlob.velY) / 30

ControlRenderSystem =
  add: (engine) ->
    @engine = engine
    @entities = engine.e 'control', 'pos', 'blob'
  update: (delta) ->
    render = @engine.s 'render'
    xSum = 0
    ySum = 0
    radiusSum = 0
    weightSum = 0
    for entity in @entities
      continue unless entity.c('control').owner == engine.player.id
      entPos = entity.c 'pos'
      entBlob = entity.c 'blob'
      xSum += entPos.x * entPos.radius
      ySum += entPos.y * entPos.radius
      radiusSum += entPos.radius
      weightSum += entBlob.weight
    if radiusSum > 0
      render.camera.x = xSum / radiusSum
      render.camera.y = ySum / radiusSum
      render.camera.ratio = Math.pow(render.canvas.width / 2 / 10 / Math.sqrt(weightSum), 0.6)
    else
      render.camera.x = 0
      render.camera.y = 0
      render.camera.ratio = 0.5
    ### Blob 'Merge' code, shouldn't be placed here
    for entity in @entities
      entPos = entity.c 'pos'
      entBlob = entity.c 'blob'
      entBlob.velX += (xSum / @entities.length - entPos.x - entBlob.velX) / 30
      entBlob.velY += (ySum / @entities.length - entPos.y - entBlob.velY) / 30
    ###

ControlSplitAction = Action.scaffold (engine) ->
  assert @player?
  playerComp = @player.c 'player'
  angle = Math.atan2 playerComp.mouseY, playerComp.mouseX
  for entity in engine.s('control').entities
    if entity.c('blob').weight > 100 and entity.c('control').owner == @player.id
      newEntity = engine.e engine.aa 'blobSplit', entity, null, angle
      newEntity.c 'control', entity.c 'control'

module.exports = 
  component: ControlComponent
  system: ControlSystem
  renderSystem: ControlRenderSystem
  action: ControlSplitAction
