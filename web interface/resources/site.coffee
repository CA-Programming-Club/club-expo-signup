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
				if skip % @size != 0
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
					color: "rgba(#{data[i]},#{data[i+1]},#{data[i+2]},#{data[i+3]})"
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

main()