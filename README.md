# hubot-aha-create-idea
Hubot command to create a new idea in Aha (see http://aha.oi)

## Installation

In your hubot project, run:

`npm install hubot-aha-create-idea --save`

Then add **hubot-aha-create-idea** to your `external-scripts.json`:

```json
[
  "hubot-aha-create-idea"
]
```

## Dependencies

This relies on request-promise npm module

## Configuration

    * HUBOT_AHA_USER - username of user in Aha who has permission to create features
    * HUBOT_AHA_PASS - password for aha user
    * HUBOT_AHA_ACCOUNTNAME - the name of the Aha.io account
    * HUBOT_AHA_IDEA_VISIBILITY - visibility of the new idea (use 'aha', 'employee', or 'public' - employee is default)
    * HUBOT_AHA_PRODUCT - product that the new idea is created under

## Sample Interaction

### Default
``` 
user1>> hubot create idea adding hubot integration: we should use the hubot-aha-create-idea module to let people create ideas straight from Slack
hubot>> @user1: The idea 'adding hubot integration' has been created in Aha as P-I-114: https://myaccount.aha.io/ideas/ideas/P-I-114 
```