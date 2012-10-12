{EventEmitter} = require 'events'
cluster = require 'cluster'

class Mediator extends EventEmitter
	eventListeners:{}
	emitCounts:{}
	@on: (event, func) -> (@eventListeners[event] ?= []).push func
	@emit: (event) -> @emitCounts[event] ?= 0; @emitCounts[event]++

class HP
	constructor: (@mediator, hp) ->
		if !(@mediator instanceof Mediator)
			throw new Exception("bad contructor")
		@hp = hp or 100
	change: (num) -> @mediator.emit "hp", @hp += num, num

class Skill
	constructor: (@mediator, @worker) ->
		if !(@mediator instanceof Mediator)
			throw new Exception("bad contructor")
		@mediator.on 'hp', => @worker.send({id:cluster.worker.id,player:'Player'+@worker.pid,damage:arguments[1],health:arguments[0]})

if cluster.isMaster
	#do Stuff With Master
	num = 50
	while num -= 1
		worker = cluster.fork()
		worker.on 'message', (msg) ->
			if msg.player
				if msg.health > 0 and msg.damage < 0
					console.log "#{msg.player} has been hit, #{-msg.damage} Damage!, #{msg.health} Remaining..."
				else if msg.health > 0 and msg.damage > 0
					console.log "#{msg.player} has been healed #{msg.damage} HP!"
				else if msg.health <= 0
					console.log "#{msg.player} has been killed!!!!!"
					cluster.workers[msg.id].destroy()
			else
				console.log "#{msg}"

		worker.on 'disconnect', () ->
			console.log "Player#{worker.process.pid} logged off crying!"
else
	#Do Stuff With Fork
	process.send "Player#{cluster.worker.process.pid} logs on..."
	playerMediator = new Mediator()
	skill = new Skill(playerMediator, process)
	hp = new HP(playerMediator)
	setInterval ->
		hp.change(Math.floor(Math.random()*90-50))
		#console.log "here"
	,
	10
	#​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​​