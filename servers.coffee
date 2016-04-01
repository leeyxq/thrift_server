cluster = require('cluster');
numCPUs = require('os').cpus().length;
thrift = require 'thrift'
userService = require './gen-nodejs/UserService'
ttypes = require './gen-nodejs/user_types'
winston = require('winston');

if cluster.isMaster
	logFile = 'servers.log'
	cluster.schedulingPolicy = cluster.SCHED_RR
	if process.argv.length > 2
		logFile = process.argv[2]

	if process.argv.length > 3
		if process.argv[3] == 'false'
			winston.remove(winston.transports.Console)
	if process.argv.length > 4 and process.argv[4] == 'none'
		cluster.schedulingPolicy = cluster.SCHED_NONE
	cluster.setupMaster({ silent: true })
	winston.add winston.transports.File, {
			filename: logFile
			json:false
			formatter: (options)->
				return options.message
		}

	for i in [0...numCPUs]
		cluster.fork()
	cluster.on 'listening', (worker, address)->
		winston.info "A worker with #{worker.id} is now connected to #{address.address} #{address.port}"
	for id of cluster.workers
		cluster.workers[id].process.stdout.on 'data', (chunk)->
			winston.info chunk.toString()

else
	server = thrift.createServer userService, {
		add: (u, result)->
			console.log "work-#{process.pid} #{u}"
			result(null,"ok")
	}
	server.listen(9002)