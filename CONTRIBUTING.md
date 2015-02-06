## Contributing
_Step by step instructions from fork to PR_

### Grab the repos
**Step 1.** fork this repo


**Step 2.** Grab hubot

Chances are that you'll want to test locally before you submit a PR.
In order to do so, you'll need an install of [Hubot](https://hubot.github.com) as well.
Make sure in lives under the same parent directory as this repo (see deploy step).

### Uses node
**Step 3.** Make sure you have node installed.

Typing `node` in the terminal should provide you with a prompt.
If it doesn't, then [download node](http://nodejs.org/download/)

**Step 4.** Install Node Packages

From the *root* directory, in command line run `npm install`

### Make sure you're clean
**Step 5.** type `rake` to see the tests pass. Probably. (I like to keep some failing as a placeholder for future
work - not always a good habit).


**Step 6.** Hack away!

Not sure what to work on?
- Peruse the [specs](spec) and find a pending one.
- Peruse the [code](js) and look for TODOs.
- Peruse the [issues](issues).


### Deploy
**Step 7.** Deploy

To play around with your code, run `rake deploy`. _(This will copy the files over to hubot)_.
Again, make sure your *hubot* instance and this repo checkouts are in sibling directories.

### Test locally
**Step 8.** Try out your new code

cd into hubot and type  `bin/hubot` for interactive prompt to test locally.

_**NOTE**: make sure ALL of your robot regexes are case-insensitive. Matching on these INCLUDES the name
of the hubot in your room, and the hubot name must match case-sensitive if the regex is also case-sensitive.
In the Shell adapter, Hubot has a capital H, not hubot, all lower-case, and so you can make yourself crazy
having a command be ignored while testing in the Shell._

### Let us in on the fun!
**Step 9.** Submit a PR

Once you're ready, submit a PR and we'll all ~~praise your name for the fun and games you introduced us to~~ immediately
call into question every decision made.

## RubyMine Notes

### Executing *-spec.coffee in RubyMine

```
Node interpreter:  /usr/local/bin/node           # should be default
Working directory: [Full path]/token_poker/spec  # should be default
JavaScript file:   round-spec.coffee             # should be default
```

Set the CoffeeScript settings to be:
```
Path to coffee executable: [Full path]/node_modules/jasmine-node/bin/jasmine-node
CoffeeScript parameters:   --coffee
```

You cannot debug with these settings, though.

### Debugging in RubyMine

The .js files can be debugged.

`rake transpile` ensures all the .js files exist. (Default rake clean removes them all).

The following needs to be added to the `Run Configuration...`
```
Node parameters: [Full path]/token_poker/node_modules/jasmine-node/bin/jasmine-node
```

The *-spec.js file can then be debugged. Not additional `Run Configuration...`
is necessary, just Debug round-spec.js, for example.
