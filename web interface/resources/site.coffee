extend = (o, p) -> o[k] = v for k, v of p; o
clearAlpha = 25
fireworks = {}
fireworks.default =
	fadeLength: 3
	fireworkSpeed: 2
	fireworkAcceleration: 4
	trailLength: 2
	showShockwave: true
	showTarget: false
	starCount: 30
	starSpeed: 5
	starSpeedVariance: 10
	starWind: 0
	starFriction: 5
	starGravity: 1
	starTrailLength: 3
	flickerDensity: 20
	hueMin: 0
	hueMax: 360
	hueVariance: 30
	lineWidth: 1
	starWidth: 1
	clearAlpha: 25

extend fireworks.debug = Object.create(fireworks.default),
	showTarget: true

getDt = (lastTime) ->
	now = Date.now()
	dt = (now - lastTime) / 16
	if dt > 5 then 5 else dt

hashCode = (str) ->
	hash = 0
	return hash if str.length == 0
	for i in [0...str.length]
		char = str.charCodeAt i
		hash = ((hash << 5) - hash) + char;
		hash = hash & hash
	return hash

fireworksName = null
audioVisualizer = null
form = document.querySelector "form"
form.addEventListener "submit", (e) ->
	e.preventDefault()
	return if fireworksName
	document.body.classList.add "in-fireworks-show"
	fireworksName = form.name.value
	setTimeout ->
		audioVisualizer.lightness = 8
	, 3000
	if fireworksName != "Sam Lazarus" and fireworksName != "Nathan Dinsmore"
		request = new XMLHttpRequest
		request.onload = ->
		request.open "POST", "#{location.protocol}//#{location.host}/add", true
		request.send fireworksName

	new ParticleVisualizer fireworksName
	new Show fireworksName

# Press Control + g to begin sampling for auto gate adjustment
document.addEventListener "keypress", (e) ->
	if e.keyCode == 7 and e.ctrlKey
		console.log "beginning measuring gate (will sample for 5 seconds)"
		audioVisualizer.measuringGate = true
		setTimeout ->
			audioVisualizer.measuringGate = false
			console.log audioVisualizer.gate
			console.log "done measuring gate"
		, 5000


fireworksCanvas = document.getElementById "firework-canvas"
fireworksContext = fireworksCanvas.getContext "2d"
fireworkEntities = []
updateFireworks = ->
	fireworksContext.globalCompositeOperation = "destination-out"
	fireworksContext.fillStyle = "rgba(0, 0, 0, #{clearAlpha / 100})"
	fireworksContext.fillRect 0, 0, fireworksCanvas.width, fireworksCanvas.height
	fireworksContext.globalCompositeOperation = "lighter"

	i = fireworkEntities.length
	while i--
		if false is fireworkEntities[i].update() then fireworkEntities.splice i, 1
	requestAnimationFrame updateFireworks

main = ->
	audioVisualizer = new AudioVisualizer
	random = new SeededRand
	#console.log new Firework random, fireworks.default
	fireworksCanvas.width = innerWidth
	fireworksCanvas.height = innerHeight
	requestAnimationFrame updateFireworks

@AudioContext ?= @webkitAudioContext

class AudioVisualizer
	canvas: document.getElementById "audio-canvas"
	gate: []
	measuringGate: false
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
			reduction = 0
			if @measuringGate
				if @gate.length > i
					@gate[i] = reduction = (@gate[i] + @arr[i]) / 2
				else
					@gate[i] = reduction = @arr[i]
			else
				if @gate.length > i
					reduction = @gate[i]
			@cx.fillRect i * w // @arr.length, h * (1 - (x - reduction) / 255), Math.ceil(w / @arr.length), h * (x - reduction) / 255

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
			# @cx.beginPath()
			# @cx.arc p.x | 0, p.y | 0, @size / 2, Math.PI * 2, false
			# @cx.fill()
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
	nextFloat: () ->
		return (@nextInt 4294965886) / 4294965885
	# random int in range min to max
	nextRange: (min, max) ->
		return (@nextInt (max - min + 1)) + min
	# random int in range 0 (inclusive) to limit (exclusive)
	nextInt: (limit) ->
		@state1 = (@state1 * @mul1) % @mod1
		@state2 = (@state2 * @mul2) % @mod2
		if @state1 < limit and @state2 < limit and @state1 < @mod1 % limit and @state2 < @mod2 % limit
			return @random(limit)
		return (@state1 + @state2) % limit


# Fireworks based off of (but still different from) Jack Rugile's Canvas Fireworks Demo


class Show
	startDelay: 3500
	showLength: 50
	fireworksSpawned: 0
	minInterval: 50
	maxInterval: 300
	constructor: (@name) ->
		@hash = hashCode @name
		@rand = new SeededRand Math.abs(@hash)
		# Uses abs to avoid negative hashes messing up the RNG. It shouldn't matter though as
		# we don't really care about the cryptographic integrity of the hash :P
		fireworksCanvas.width = innerWidth
		fireworksCanvas.height = innerHeight
		setTimeout @spawnFirework, @startDelay
	spawnFirework: () =>

		@fireworksSpawned += 1
		if @fireworksSpawned <= @showLength
			setTimeout @spawnFirework, @rand.nextRange(@minInterval, @maxInterval)
		else
			setTimeout () ->
				audioVisualizer.lightness = 30

			, 3000
			setTimeout () ->
				form.name.value = ""
				fireworksName = null
				document.body.classList.remove "in-fireworks-show"
			, 3500
		new Firework @rand, fireworks.default


class Firework
	canvas: document.getElementById "firework-canvas"
	constructor: (@rand, config) ->
		@config = Object.create config # Remove direct references
		@cx = @canvas.getContext "2d"
		@minX = innerWidth / 3
		@maxX = 2 * innerWidth / 3
		@minDestinationY = innerHeight / 5
		@maxDestinationY = innerHeight / 2
		@startX = @rand.nextRange @minX, @maxX
		@startY = innerHeight + 30
		@x = @startX
		@y = @startY
		@hitX = false
		@hitY = false
		@trailLength = @config.trailLength
		@history = []
		@history.push {x: @startX, y: @startY} for [0...@trailLength]
		@targetX = @rand.nextRange @startX - innerWidth / 3, @startX + innerWidth / 3
		@targetY = @rand.nextRange @minDestinationY, @maxDestinationY
		@speed = @config.fireworkSpeed
		@angle = Math.atan2 @targetY - @startY, @targetX - @startX
		@shockwaveAngle = @angle + Math.PI / 2
		@acceleration = @config.fireworkAcceleration / 100
		@hue = @rand.nextRange @config.hueMin, @config.hueMax
		@brightness = @rand.nextRange 50, 80
		@alpha = @rand.nextRange(50, 100) / 100
		@lineWidth = @config.lineWidth
		@targetRadius = 5
		@showTarget = @config.showTarget
		@lastTime = Date.now()
		@draw()
		fireworkEntities.push this

	update: =>
		dt = getDt @lastTime
		@lastTime = Date.now()
		vx = Math.cos(@angle) * @speed
		vy = Math.sin(@angle) * @speed
		@speed *= 1 + @acceleration
		for i in [(@trailLength - 1)...0]
			@history[i] = @history[i - 1]
		@history[0] = {@x, @y}

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
			if @y + vy <= @targetY
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
			@createStars()
			return false
		else
			@draw()

	draw: ->
		@cx.lineWidth = @lineWidth
		randCoord = @rand.nextInt @trailLength
		{x: ox, y: oy} = @history[randCoord]
		@cx.beginPath()
		@cx.moveTo Math.round(ox), Math.round(oy)
		@cx.lineTo Math.round(@x), Math.round(@y)
		@cx.strokeStyle = "hsla(#{@hue}, 100%, #{@brightness}%, #{@alpha})"
		@cx.stroke()
		if @showTarget
			@cx.save()
			@cx.beginPath()
			@cx.arc Math.round(@targetX), Math.round(@targetY), @targetRadius, 0, Math.PI * 2, false
			@cx.closePath()
			@cx.lineWidth = 1
			@cx.stroke()
			@cx.restore()
		if @config.showShockwave
			@cx.save()
			@cx.translate Math.round(@x), Math.round(@y)
			@cx.rotate @shockwaveAngle
			@cx.beginPath()
			@cx.arc 0, 0, @speed / 5, 0, Math.PI, true
			@cx.strokeStyle = "hsla(#{@hue}, 100%, #{@brightness}, #{@rand.nextRange(25, 65) / 100})"
			@cx.lineWidth = @lineWidth
			@cx.stroke()
			@cx.restore()

	createStars: () ->
		(new Star @rand, @x, @y, @hue, @config) for [0...@config.starCount]

class Star
	canvas: document.getElementById "firework-canvas"
	constructor: (@rand, @x, @y, @baseHue, config) ->
		@config = Object.create(config)
		@cx = @canvas.getContext "2d"
		@history = []
		@history.push { x: @x, y: @y } for [0...@config.starTrailLength]
		@angle = @rand.nextRange 0, 360
		minSpeed =
			if @config.starSpeed - @config.starSpeedVariance <= 0 then 1
			else @config.starSpeed - @config.starSpeedVariance
		maxSpeed = @config.starSpeed + @config.starSpeedVariance
		@speed = @rand.nextRange minSpeed, maxSpeed
		@friction = 1 - @config.starFriction / 100
		@gravity = @config.starGravity / 2
		@hue = @rand.nextRange @baseHue - @config.hueVariance, @baseHue + @config.hueVariance
		@brightness = @rand.nextRange 50, 80
		@alpha = @rand.nextRange(40, 100) / 100
		@decay = @rand.nextRange(10, 50) / 1000
		@wind = (@rand.nextRange(0, @config.starWind) - @config.starWind / 2) / 25
		@lineWidth = @config.starWidth
		@lastTime = Date.now()
		@draw()
		requestAnimationFrame @update

	update: () =>
		dt = getDt @lastTime
		@lastTime = Date.now()
		radians = @angle * Math.PI / 180
		vx = Math.cos(radians) * @speed
		vy = Math.sin(radians) * @speed + @gravity
		@speed *= @friction
		for i in [(@config.starTrailLength - 1)...0]
			@history[i] = @history[i - 1]
		@history[0] = { x: @x, y: @y }
		@x += vx * dt
		@y += vy * dt
		@angle += @wind
		@alpha -= @decay
		if not (@alpha < .05 or @x > @canvas.width + 20 or @x < -20 or @y < -20 or @y > @canvas.height + 20)
			@draw()
			requestAnimationFrame @update

	draw: () ->
		randCoord = @rand.nextInt @config.starTrailLength
		@cx.beginPath()
		@cx.moveTo Math.round(@history[randCoord].x), Math.round(@history[randCoord].y)
		@cx.lineTo Math.round(@x), Math.round(@y)
		@cx.closePath()
		@cx.strokeStyle = "hsla(#{@hue}, 100%, #{@brightness}%, #{@alpha})"
		@cx.stroke()
		if @config.flickerDensity > 0
			inverseDensity = 50 - @config.flickerDensity
			if @rand.nextRange(0, inverseDensity) is inverseDensity
				@cx.beginPath()
				@cx.arc Math.round(@x), Math.round(@y),
					@rand.nextRange(@config.starWidth, @config.starWidth + 3) / 2,
					0, Math.PI * 2, false
				@cx.closePath()
				randAlpha = @rand.nextRange(50, 100) / 100
				@cx.fillStyle = "hsla(#{@hue}, 100%, #{@brightness}%, #{randAlpha})"
				@cx.fill()

main()
