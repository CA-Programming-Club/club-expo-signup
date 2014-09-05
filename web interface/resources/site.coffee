fireworks =
	default:
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

	debug: # show the target to allow for easier debugging
		fadeLength: 3
		fireworkSpeed: 2
		fireworkAcceleration: 4
		showShockwave: true
		showTarget: true
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

getDt: (lastTime) ->
	now = +new Date
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
		@cx.fillStyle = "hsl(#{@hue}, 80%, #{@_lightness}%)"
		for x, i in @arr
			x *= .5
			# x = Math.min 127.5, x + 50 + Math.random() * 50
			@cx.fillRect i * w // @arr.length, h * (1 - x / 255), Math.ceil(w / @arr.length), h * x / 255

class ParticleVisualizer
	canvas: document.getElementById "particle-canvas"

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

		# left/right : subtract or add 4
		# above/below: subtract or add 4 * the canvas width (c.width)
		@startTime = +new Date
		@particles = []
		@size = 5
		skip = 0
		for x in [0...c.width]
			for y in [0...c.height]
				skip = skip + 1
				if skip % @size
					continue
				i = (x + y * c.width) * 4
				continue unless data[i+3]
				xLoc = (innerWidth - c.width) / 2 + 2 + x
				yLoc = (innerHeight - c.height) / 2 + 2 + y
				rx = xLoc - innerWidth / 2
				ry = yLoc - innerHeight / 2
				magnitude = Math.sqrt rx * rx + ry * ry
				tvx = 1 * Math.random() * (-20 + (50 / Math.abs(rx))) * (rx / magnitude)
				tvy = 1.5 * Math.random() * (-20 + (50 / Math.abs(ry))) * (ry / magnitude)
				vMagnitude = Math.sqrt tvx * tvx + tvy * tvy
				@particles.push {
					x: xLoc
					y: yLoc
					vx: (tvx + 7 * tvx / vMagnitude) * innerWidth / 750
					vy: (tvy + 7 * tvy / vMagnitude) * innerHeight / 650
					color: "rgb(#{data[i]},#{data[i+1]},#{data[i+2]})"
				}

		setTimeout () =>
			@cx.clearRect 0, 0, innerWidth, innerHeight, false
		, 4010

		requestAnimationFrame @draw

	draw: =>
		w = @canvas.width = innerWidth
		h = @canvas.height = innerHeight
		for p in @particles
			@cx.fillStyle = p.color
			@cx.fillRect p.x | 0, p.y | 0, @size, @size
			p.vx *= 0.99
			p.vy *= 0.99
			p.x += p.vx
			p.y += p.vy
		if (+new Date) - @startTime < 4000
			requestAnimationFrame @draw
		# Hackey way of getting rid of the stupid top-left-of-screen particle bug
		@cx.clearRect 0, 0, @size, @size

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
	nextFloat: () ->
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
		@lastTime = +new Date
		requestAnimationFrame @update

	update: () ->
		dt = getDt @lastTime
		@lastTime = +new Date
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






