# Description:
#   Allows Hubot herd frigg workers
#
# Dependencies:
#   promised-ssh
#
# Configuration
#   PRIVATE_KEY_PATH
#
# Commands:
#   worker-stats <command> - get them stats
#   workers <host> <command> - run service command on host.
#
# Authors:
#   relekang

ssh = require 'promised-ssh'
fs = require 'fs'
request = require 'superagent'

module.exports = (robot) ->
  robot.respond /worker-stats/i, (msg) ->
    request.get('https://ci.frigg.io/api/stats')
      .end (err, res) ->
        if err
          msg.send err
        msg.send JSON.stringify(res.body.stats, null, 2)

  robot.respond /workers ([\w\.]+) (\w+)/i, (msg) ->
    msg.send 'Commanding workers'
    commandWorkers(msg.match[1], msg.match[2])
      .spread((stdout, stderr) ->
        if msg.match[2] == 'status'
          msg.send stdout
        else
          msg.send 'Made the workers "' + msg.match[2] + '"'
      )
      .catch((error) ->
        console.log error.stack
        msg.send 'The command had an error ' + error
      )

commandWorkers = (host, command) ->
  return ssh
    .connect({
      host: host,
      username: 'root',
      privateKey: fs.readFileSync process.env.PRIVATE_KEY_PATH, {encoding: 'utf8'}
    })
    .then((connection) ->
      return connection.exec ['service frigg-worker ' + command]
    )
