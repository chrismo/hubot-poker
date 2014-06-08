# Token Poker

Contributors: 
- glv (original odds parsing script)
- woodall (contribution instructions)

## Hands (in winning order)

- Six of a kind (333 333): 10 combinations
- Five of a kind (133 333): 540 combinations
- Two triples (223 233): 900 combinations
- Full house (113 333): 1,350 combinations
- Six straight (132 465): 3,600 combinations
- Three pair (113 773): 10,800 combinations
- Four of a kind (123 333): 10,800 combinations
- Five straight (132 495): 25,184 combinations
- Crowded house (113 733): 43,200 combinations
- One triple (111 798): 100,800 combinations
- Snowflake (123 798): 133,216 combinations
- Two pair (113 738): 226,800 combinations
- One pair (113 798): 442,800 combinations

Interestingly, unlike card poker, a hand with no duplicate numbers and no
sequence of five or more is not the most common hand; two-pair and one-pair
hands are much more common. That's one reason we've given such hands the name
"snowflake" rather than the nondescript "high card" name used for such hands
in poker.

Other interesting hands:

- All evens (246 862)
- All odds (133 795)
- Fibonacci (112 358)
- Primes (235 711)

### Notes

0 no longer acts as an Ace, high or low. It's simply low.

<hr>

## Contributing
_Step by step instructions from fork to PR_

### Grab the repos
**Step 1.** fork this repo


**Step 2.** Grab hubot

Chances are that you'll want to test locally before you submit a PR. 
In order to do so, you'll need an install of [Hubot](https://hubot.github.com) as well. 
Make sure in lives under the same parent directory as token_poker (see deploy step).

### Uses node
**Step 3.** Make sure you have node installed. 

Typing `node` in the terminal should provide you with a prompt.
If it doesn't, then [download node](http://nodejs.org/download/)

**Step 4.** Install Node Packages

From the *token_poker* directory, in command line run `npm install`

### Make sure you're clean
**Step 5.** type `rake` to see the tests pass


**Step 6.** Hack away!

Not sure what to work on? 
- Peruse the [specs](https://github.com/chrismo/token_poker/tree/master/spec) and find a pending one.
- Peruse the [code](https://github.com/chrismo/token_poker/tree/master/js/token-poker) and look for TODOs.
- Peruse the [issues](https://github.com/chrismo/token_poker/issues).

Be sure to communicate in advance what you'll be hacking on, there's not a lot of real estate yet and
chrismo is still prone to do some big refactorings. If you work on something in silence, it might get
implemented out from underneath you or set you up for a nasty rebase.

### Deploy
**Step 7.** Deploy

To play around with your code, run `rake deploy` from your *token_poker* directory. _(This will copy the files over to hubot)_.
Again, make sure *hubot* and *token_poker* checkouts are in sibling directories.

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
