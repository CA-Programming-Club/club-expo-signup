fireworksName = null
audioVisualizer = null
form = document.querySelector "form"
form.addEventListener "submit", (e) ->
	return if fireworksName
	e.preventDefault()
	# TODO: add fade out of audio visualizer
	document.body.classList.add "in-fireworks-show"
	fireworksName = form.name.value
	audioVisualizer.lightness = 8
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
	lightness: 20
	_lightness: 20
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
	canvas: document.getElementById "audio-canvas"

	constructor: (@name) ->
		@cx = @canvas.getContext "2d"

		c = document.createElement "canvas"
		cx = c.getContext "2d"
		cx.textBaseline = "middle"
		cx.font = "200 72px Helvetica Neue, sans-serif"
		w = cx.measureText(name).width
		c.height = 72 * 1.5
		c.width = w
		cx.fillText name, 0, c.height / 2
		imageData = cx.getImageData 0, 0, c.width, c.height
		data = imageData.data

		@particles = []
		for x in [0...c.width]
			for y in [0...c.height]
				i = (x + y * c.width) * 4
				continue unless data[i+3]
				@particles.push {
					x: i % c.width
					y: i // c.width
					color: "rgba(#{data[i]},#{data[i+1]},#{data[i+2]},#{data[i+3]})"
				}

		requestAnimationFrame @draw

	draw: =>
		w = @canvas.width = innerWidth
		h = @canvas.height = innerHeight
		for p in @particles
			@cx.fillStyle = p.color
			@cx.fillRect p.x, p.y, 1, 1
		requestAnimationFrame @draw

main()
