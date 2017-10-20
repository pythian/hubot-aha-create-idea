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
#   hubot create idea <name>: <description> (optional)tags: <tag1>, <tag2> (optional)categories: <category1>, <category2> 
#   hubot create observation <name>: <description> (optional)tags: <tag1>, <tag2>
#   hubot list idea categories
#
# Author:
#   Dennis Newel <dennis.newel@newelcorp.com>
#   Dennis Walker <denniswalker@me.com>
#
# Notes:
#   The user used for this integration cannot be linked to a single sign-on system; it must be a user with basic username/password
#
yaml = require('js-yaml');

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
  Authorization: "Basic " + usertoken
}

createAhaIdea = (msg, categories=[]) ->
  name = parseName(msg.match[1])
  description = parseDescription(msg.match[1])
  tags = parseTags(msg.match[1])
  categories = parseCategories(msg.match[1]) unless categories[0]

  msg.reply "hmm...something's missing from what you're asking me. Try again" unless name && description
  options = {
    method: 'POST',
    uri: aha_api + "products/" + product + "/ideas",
    headers: req_headers,
    body: {
      "idea": {
        "name": name,
        "description": description,
        "created_by": msg.message.user.profile.email,
        "categories": categories,
        "tags": tags
      }
    },
    json: true
  }

  rp(options)
    .then (parsedBody) ->
      msg.reply "The idea '#{name}' has been created in Aha as #{parsedBody.idea.reference_num}: #{parsedBody.idea.url}"
      return
    .catch (err) ->
      msg.reply "Something went wrong when creating the idea: #{err}"
      getIdeaCategories(msg) if "#{err}".match(/unknown idea category: new category/i)
      return

getIdeaCategories = (msg) ->
  options = {
    method: 'GET',
    uri: aha_api + "products/" + product + "/idea_categories",
    headers: req_headers,
    json: true
  }

  rp(options)
    .then (parsedBody) ->
      hierarchy = sortCategoriesIntoHierarchy(parsedBody.idea_categories)
      aha_categories = "The categories for product #{product} are:"
      aha_categories = "#{aha_categories}\n#{hierarchy}"
      msg.reply aha_categories
      return
    .catch (err) ->
      msg.reply "Something went wrong when creating the idea: #{err}"
      return

sortCategoriesIntoHierarchy = (categories) ->
  hierarchy = {}
  hierarchy_array = []

  # Populate top level hierarchy
  for parent in categories when parent.parent_id is null
    hierarchy[parent.id] = {"name": parent["name"], "children":[]}

  # Push children into parent arrays
  for category in categories when category.parent_id isnt null
    hierarchy[category.parent_id]["children"].push(category.name)

  # Strip parent IDs
  for item of hierarchy
    temp = { "#{hierarchy[item].name}": hierarchy[item].children }
    hierarchy_array.push(temp)
  
  categories_in_yml = yaml.safeLoadAll(JSON.stringify(hierarchy_array, null, ""))
  return yaml.safeDump(categories_in_yml)


parseTags = (message) ->
  tags = message.match(/tags:([A-Z0-9.,()\s'\-]*(?![categories:]))/i)
  return tags[1].trim().split(/\,\s+/)

parseCategories = (message) ->
  categories = message.match(/categories:([A-Z0-9.,()\s'\-]*(?![tags:]))/i)
  return categories[1].trim().split(/\,\s*/)

parseName = (message) ->
  name = message.match(/(.*?):/i)
  return name[1].trim()

parseDescription = (message) ->
  description = message.match(/:([A-Z0-9.,()\s'\-]*(?![tags:|categories:]))/i)
  return description[1].trim()

module.exports = (robot) ->
  robot.respond /create idea (.*)/i, (msg) ->
    createAhaIdea(msg)

  robot.respond /create observation (.*)/i, (msg) ->
    createAhaIdea(msg, ["observation"])

  robot.respond /list idea categories/i, (msg) ->
    getIdeaCategories(msg)
    
    
