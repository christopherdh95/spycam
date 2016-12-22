express = require 'express'
fs = require 'fs'

cameras = 2

imageFolder = '/home/ritapazi/imagesFromMotion/'

app = express()
app.use express.static '/home/ritapazi/spycam/public'

app.get '/', (req, res)-> res.end()

app.get '/info', (req, res)->
	cbFunct = (data)->
		res.end data
	diskUsage(cbFunct)

app.get '/state', (req, res)->
	res.end readStatus()

server = app.listen 3333, ()->
   host = server.address().address
   port = server.address().port
   
   console.log("Example app listening at http://%s:%s", host, port)

disk = require('diskusage');
 
diskUsage = (cb)->
	disk.check '/', (err, info)->
		console.log err if err
		dfInPercent = (Math.round(info.free/info.total*100)).toString()
		if dfInPercent<5 then seekAndDestroy()
		cb dfInPercent

readStatus = (cb, camNr)->
	data = ""
	c = cameras
	while c--
		status = fs.readFileSync 'state'+c+'.info', 'utf8'
		data = status+"_"+data
	data
	
oldestFolder = (dir, cb)->
	list = fs.readdir dir, (err, res)->
		console.log err if err
		return console.log "Image folder empty!" if res.length<1
		oldest = file:"", date:-1
		res.forEach (file)->
			dd = file.split("_")
			return console.log "dirName wrong "+file if dd.length<2
			newDate = new Date(dd[1]+"."+dd[0]+"."+dd[2]).getTime()
			if (newDate<oldest.date||oldest.date==-1)
				oldest = file:file, date: newDate
		cb oldest.file
	
oldestFile = (dir, cb)->
	dir = imageFolder+dir
	list = fs.readdir dir, (err, res)->
		console.log err if err
		oldest = file:"", date:24*60*60*60
		res.forEach (file)->
			dd = file.split("_")[0].split(":")
			return console.log "fileName wrong "+file if dd.length<2
			newTime = parseInt((dd[0]*60*60)+(dd[1]*60)+(dd[2]*0))
			console.log file, newTime, dd, oldest
			if (newTime<oldest.date)
				oldest = file:file, date: newTime
		cb dir+"/"+oldest.file	
	
	
seekAndDestroy = ()-> # remove oldest file
	oldestFolder imageFolder, (oldestFolderName)->
		oldestFile	oldestFolderName, (oldestFileName)->
			console.log "REMOVE: "+oldestFileName
			fs.unlink oldestFileName, (err)->
				if err # no more files left in folder
					fs.rmdir oldestFileName, (err)->
						console.log err if err

#seekAndDestroy()

