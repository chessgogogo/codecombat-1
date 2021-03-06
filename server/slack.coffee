config = require '../server_config'
request = require 'request'
log = require 'winston'

roomChannelMap =
  main: '#general'
  artisans: '#artisan'

module.exports.sendSlackMessage = sendSlackMessage = (message, rooms=['tower'], options={}) ->
  return unless config.isProduction
  unless token = config.slackToken
    log.info "No Slack token."
    return
  for room in rooms
    channel = roomChannelMap[room] ? room
    form =
      channel: channel
      token: token
      text: message
    if options.papertrail
      secondsFromEpoch = Math.floor(new Date().getTime() / 1000)
      link = "https://papertrailapp.com/groups/488214/events?time=#{secondsFromEpoch}"
      form.text += " #{link}"
    # https://api.slack.com/docs/formatting
    form.text = form.text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    url = "https://slack.com/api/chat.postMessage"
    request.post {uri: url, form: form}, (err, res, body) ->
      return log.errr('Error sending Slack message:', err) if err
      return log.error("Slack returned error: #{body.error}") unless body.ok
      log.warn("Slack returned warning: #{body.warning}") if body.warning 
      # log.info "Got Slack message response:", body
