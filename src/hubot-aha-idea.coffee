# Description:
#   Command for hubot to create an idea in Aha
#
# Configuration:
#   HUBOT_AHA_USER - username of user in Aha who has permission to create features
#   HUBOT_AHA_PASS - password for aha user
#   HUBOT_AHA_ACCOUNTNAME - the name of the Aha.io account
#   HUBOT_AHA_IDEA_VISIBILITY - visibility of the new idea (use 'aha', 'employee', or 'public' - employee is default)
#   HUBOT_AHA_PRODUCT - product that the new idea is created under
#
# Dependencies:
#   request-promise
#
# Commands:
#   hubot create idea <name>: <description> <tags> - hubot will create a new idea in Aha with the name <name> and description of <description> with tags <tags>
#
# Author:
#   Dennis Newel <dennis.newel@newelcorp.com>
#
# Notes:
#   The user used for this integration cannot be linked to a single sign-on system; it must be a user with basic username/password
#

aha_api = "https://" + process.env.HUBOT_AHA_ACCOUNTNAME + ".aha.io/api/v1/"
default_release = process.env.HUBOT_AHA_RELEASE ? "P-R-1"
usertoken = new Buffer(process.env.HUBOT_AHA_USER + ":" + process.env.HUBOT_AHA_PASS).toString('base64')
visibility = process.env.HUBOT_AHA_IDEA_VISIBILITY ? "employee"
product = process.env.HUBOT_AHA_PRODUCT ? "P"

rp = require 'request-promise'

req_headers = {
    "X-Aha-Account": process.env.HUBOT_AHA_ACCOUNTNAME,
    "Content-Type": "application/json",
    Accept: "application/json",
    Authorization: "Basic " + usertoken,    
}

module.exports = (robot) =>

    robot.respond /create idea (.*):([\w|\s]*)\s+?(#\w+){0,1} ?(#\w+){0,1}/i, (msg) ->
        msg.reply "hmm...something's missing from what you're asking me. Try again" unless msg.match[1] && msg.match[2]

        options = {
            method: 'POST',
            uri: aha_api + "products/" + product + "/ideas",
            headers: req_headers,
            body: {
                "idea": {
                    "name": msg.match[1],
                    "description": msg.match[2],
                    "created_by": msg.message.user.profile.email
                    "tags": msg.match[3...4]
                }
            },    
            json: true 
        }

        rp(options)
            .then (parsedBody) -> 
                msg.reply "The idea '#{msg.match[1]}' has been created in Aha as #{parsedBody.idea.reference_num}: #{parsedBody.idea.url}"
                return
            .catch (err) ->
                msg.reply "Something went wrong when creating the idea: #{err}"
                return
