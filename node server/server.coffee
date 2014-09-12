console.log "Starting server"

express = require "express"
path = require "path"
fs = require "fs"

app = express()
app.use express.static path.resolve __dirname, "../web interface"

app.post "/add", (req, res) ->
	data = ""
	req.on "data", (chunk) -> data += chunk
	req.on "end", ->
		fs.appendFile "names.txt", "#{data}\n"
	res.end()

app.listen 25635
