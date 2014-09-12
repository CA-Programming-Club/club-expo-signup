extend = (o, p) -> o[k] = v for k, v of p; o

fireworks = {}
fireworks.default =
	fadeLength: 3
	fireworkSpeed: 2
	fireworkAcceleration: 4
	showShockwave: true
	showTarget: false
	particleCount: 30
	particleSpeed: 5
	particleSpeedVariance: 10
	particleWind: 50
	particleFriction: 5
	particleGravity: 1
	flickerDensity: 20
	hueMin: 0
	hueMax: 360
	hueVariance: 30
	lineWidth: 1
	clearAlpha: 25

extend fireworks.debug = Object.create(fireworks.default),
	showTarget: true

getDt: (lastTime) ->
	now = Date.now()
	dt = (now - lastTime) / 16
	if dt > 5 then 5 else dt

fireworksName = null
audioVisualizer = null
form = document.querySelector "form"
form.addEventListener "submit", (e) ->
	return if fireworksName
	e.preventDefault()
	# TODO: add fade out of audio visualizer
	document.body.classList.add "in-fireworks-show"
	fireworksName = form.name.value
	setTimeout () ->
		audioVisualizer.lightness = 15
	, 3000
	new ParticleVisualizer fireworksName

main = ->
	audioVisualizer = new AudioVisualizer

@AudioContext ?= @webkitAudioContext

class AudioVisualizer
	canvas: document.getElementById "audio-canvas"

	constructor: ->
		@cx = @canvas.getContext "2d"
		@context = new AudioContext
		@analyser = @context.createAnalyser()
		navigator.webkitGetUserMedia audio: true, (stream) =>
			@source = @context.createMediaStreamSource stream
			@source.connect @analyser
			@arr = new Uint8Array Math.floor @analyser.frequencyBinCount * .7
			setInterval @poll, 1000 / 60
		, (e) -> console.log e

	hue: 0
	damping: .03
	lightness: 30
	_lightness: 30
	poll: =>
		@analyser.getByteFrequencyData @arr
		w = @canvas.width = innerWidth
		h = @canvas.height = innerHeight
		@hue += .1
		# grad = @cx.createLinearGradient 0, h / 2, 0, h
		# grad.addColorStop 0, "hsl(#{@hue}, 80%, 40%)"
		# grad.addColorStop 1, "hsl(#{@hue}, 80%, 10%)"
		# @cx.fillStyle = grad
		@_lightness += (@lightness - @_lightness) * @damping
		for x, i in @arr
			x *= .5
			# x = Math.min 127.5, x + 50 + Math.random() * 50
			@cx.fillStyle = "hsl(#{@hue - x / 255 * 120}, 80%, #{@_lightness}%)"
			@cx.fillRect i * w // @arr.length, h * (1 - x / 255), Math.ceil(w / @arr.length), h * x / 255

class ParticleVisualizer
	canvas: document.getElementById "particle-canvas"
	size: 6

	constructor: (@name) ->
		@cx = @canvas.getContext "2d"

		c = document.createElement "canvas"
		cx = c.getContext "2d"
		cx.textBaseline = "alphabetic"
		cx.font = "200 72px Helvetica Neue, sans-serif"
		w = cx.measureText(name).width
		c.height = 72 * 1.5
		c.width = w
		cx.font = "200 72px Helvetica Neue, sans-serif"
		cx.fillStyle = "#fff"
		cx.fillText name, 0, 75 * 1.05
		imageData = cx.getImageData 0, 0, c.width, c.height
		data = imageData.data

		@startTime = Date.now()
		@particles = []
		skip = 0
		dw = Math.max 0, (c.width - c.height * .5) / 2
		for px in [0...c.width]
			for py in [0...c.height]
				skip = skip + 1
				if skip % @size
					continue
				i = (px + py * c.width) * 4
				continue unless data[i+3]
				x = (innerWidth - c.width) / 2 + px
				y = (innerHeight - c.height) / 2 + py
				rx = (if px < c.width / 2 then -1 else 1) * Math.max 0, Math.abs(px - c.width / 2) - dw
				ry = py - c.height / 2
				s = .5 + Math.random() * 3
				vx = rx / 6 * s + Math.random() * 2 - 1
				vy = ry / 6 * s + Math.random() * 2 - 1
				life = 1.4 - s / 5
				@particles.push {x, y, vx, vy, life}

		requestAnimationFrame @draw

	draw: =>
		w = @canvas.width = innerWidth
		h = @canvas.height = innerHeight
		t = (Date.now() - @startTime) / 1000
		@cx.fillStyle = '#fff'
		i = @particles.length
		while i--
			p = @particles[i]
			if t > p.life
				@particles.splice i, 1
				continue
			@cx.globalAlpha = 1 - (t / p.life)
			@cx.fillRect p.x | 0, p.y | 0, @size-1, @size-1
			p.vx *= 0.97
			p.vy *= 0.97
			p.x += p.vx
			p.y += p.vy
		if @particles.length
			requestAnimationFrame @draw

class SeededRand
	constructor: (@state1, @state2) ->
		@mod1 = 4294967087
		@mul1 = 65539
		@mod2 = 4294965887
		@mul2 = 65537
		if typeof @state1 != "number"
			@state1 = Math.floor(Math.random() * 2147483647)
		if typeof @state2 != "number"
			@state2 = @state1
		@state1 = @state1 % (@mod1 - 1) + 1
		@state2 = @state2 % (@mod2 - 1) + 1
	# random float in range 0 to 1
	nextFloat: ->
		return (@randTo 4294965886) / 4294965885
	# random int in range min to max
	randRange: (min, max) ->
		return (@randTo (max - min + 1)) + min
	# random int in range 0 (inclusive) to limit (exclusive)
	nextInt: (limit) ->
		@state1 = (@state1 * @mul1) % @mod1
		@state2 = (@state2 * @mul2) % @mod2
		if @state1 < limit and @state2 < limit and @state1 < @mod1 % limit and @state2 < @mod2 % limit
			return random(limit)
		return (@state1 + @state2) % limit
main()

# Fireworks based off of (but still different from) Jack Rugile's Canvas Fireworks Demo

class Firework
	canvas: document.getElementById "firework-canvas"
	constructor: (@rand, config) ->
		@config = Object.create config # Remove direct references
		@cx = @canvas.getContext "2d"
		@minX = 0
		@maxX = innerWidth
		@minDestinationY = innerHeight / 2
		@maxDestinationY = innerHeight
		@startX = @rand.randRange @minX, @maxX
		@startY = 0
		@x = @startX
		@y = @startY
		@hitX = false
		@hitY = false
		@fadeLength = @config.fadeLength
		@history = []
		@history.push { x: @starX, y: @startY } for [0...@fadeLength]
		@targetX = @rand.randRange @startX - innerWidth / 10, @startX + innerWidth / 10
		@targetY = @rand.randRange @minDestinationY, @maxDestinationY
		@speed = @config.fireworkSpeed
		@angle = Math.atan2 @targetY - @startY, @targetX - @startX
		@shockwaveAngle = @angle + Math.PI / 2
		@acceleration = @config.fireworkAcceleration / 100
		@hue = @rand.nextInt @config.hueMin, @config.hueMax
		@brightness = @rand.nextInt 0, 50
		@alpha = rand.nextInt(50, 100) / 100
		@lineWidth = @config.lineWidth
		@targetRadius = 1
		@showTarget = @cofig.showTarget
		@lastTime = Date.now()
		requestAnimationFrame @update

	update: () ->
		dt = getDt @lastTime
		@lastTime = Date.now()
		@cx.lineWidth = @lineWidth
		vx = Math.cos(@angle) * @speed
		vy = Math.sin(@angle) * @speed
		@speed *= 1 + @acceleration
		for i in [(@fadeLength - 1)...0]
			@history[i] = @history[i - 1]
		@history[0] = { x: @x, y: @y }

		if @showTarget
			if @targetRadius < 8
				@targetRadius += .25 * dt
			else
				@targetRadius = dt

		if @startX >= @targetX
			if @x + vx <= @targetX
				@x = @targetX
				@hitX = true
			else
				@x += vx * dt
		else
			if @x + vx >= @targetX
				@x = @targetX
				@hitX = true
			else
				@x += vx * dt

		if @startY >= @targetY
			if @x + vy <= @targetY
				@y = @targetY
				@hitY = true
			else
				@y += vy * dt
		else
			if @y + vy >= @targetY
				@y = @targetY
				@hitY = true
			else
				@y += vy * dt

		if @hitX and @hitY
			@createParticles()
		else
			requestAnimationFrame @update
	createParticles: () ->
		# TODO: Implement






