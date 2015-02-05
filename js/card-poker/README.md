# Hubot Texas Hold 'Em

## Direct Message Support Required

This game has only been tested with Slack's adapter, and requires an adapter/platform
that can send direct messages to players, as this is how hole cards are dealt. Tools
like Campfire don't support direct messages so there's currently no way to deal cards
to players.

## Differences from Real Texas Hold 'Em

The goal of this game is to be something quick and easy to play while taking a quick
break from work or whatever. Rounds are a fixed amount of time (2 and a half minutes),
anyone can join during the 1st phase, and betting is a free-for-all. Differences to
real Texas Hold 'em are largely in service of that goal.

Those longing for something else are invited to submit a PR or fork-fork-baby.

### General Play

A round goes in 5 phases: dealing the hole cards, the flop, the turn and the river,
then a settle up phase. The Deal phase is 1 minute, the flop, turn and river phases
each last 20 seconds, and betting can be done at any time during these. A final 30
second settle up phase closes new bets and allows players to call or fold before
the winning hand is revealed.

Players join by entering the `deal` command during the 1st minute. Once the deal
phase is over, no more players can join. No player is automatically joined in the
next round.

### 'Wild West' Betting

Until the settle up phase, when new bets are locked, players can bet at any time and
bet as many times as they want. Multiple bets from the same player accumulate (e.g.
`bet 3` + `bet 4` == `bet 7`).

Issuing a `call` command is the same as `bet #{highest accumulated amount from a
player} - #{what I've already bet so far}`. It makes you even in the Pot. Calling is
not sticky: if more bets are made, raising the `highest player bet` amount in the Pot,
a calling player will need to `bet` or `call` again.

Any player not explicitly folding before the end of the round will be automatically
called, to contribute what they owe.

Players without enough points to match the highest bet remain in the game and are
essentially 'all in'. Players without any points after the round will not be allowed
to play in subsequent rounds.

There is no `raise` command, players can continue to make new bets (until the settle
up phase), and the game will make sure all players remaining in the game have
contributed an equal number of points to the Pot up to the maximum number of points
they have.

Players can fold at any time, and folding forfeits any money already bet to the pot.

In the final phase of the game, no new bets are accepted, players can only call or
fold. Any player not folding will automatically call to match the highest bid by
the end of the round.

Example:

5 Players, each with 25 points.
```
Player A: deal        Pot Total: 1 (ante)
Player B: deal        Pot Total: 2 (ante)
Player C: deal        Pot Total: 3 (ante)
Player D: deal        Pot Total: 4 (ante)
Player E: deal        Pot Total: 5 (ante)

Player E: bet 3       Pot Total: 8
Player A: bet 10      Pot Total: 18
Player B: bet 5       Pot Total: 23
Player B: bet 7       Pot Total: 30
Player C: fold        Pot Total: 30
Player D: call        Pot Total: 42 (12 being the highest total by Player B)
Player A: bet 3       Pot Total: 45 (13 is now the highest total by Player A)
```

Settle Up Round
```
Player D: call        Pot Total: 46 (the additional 1 point to get Player D to 13)
Player E: fold        Pot Total: 46
```

End
```
Player B: [auto call] Pot Total: 47 (the additional 1 point to get Player B to 13)
```

Player B has the best hand.
```
Player A is left with 11 points: 25 - 1 (ante) - 13 (total bet).
Player C is left with 24 points: 25 - 1 (ante). Folded before anything was bet.
Player D is left with 11 points: 25 - 1 (ante) - 13 (total bet).
Player E is left with 21 points: 25 - 1 (ante) - 3 (bet then folded).

Player B wins and ends up with 58 points:

 +25 (original)
 - 1 (ante)
 -13 (total bet)
 + 5 (5 player antes)
 +13 (Player A's bet)
 +13 (self bet)
 +13 (Player C's bet)
 + 3 (Player E's bet)
```

(This scenario is an automated test, see `texas-hold-em-spec.coffee`).


### Ties / Splitting the Pot

There are currently no ties, but not for any reason other than needing to code it
up (both hand comparison and splitting the pot to multiple players).

The hand comparison code actually takes suit into account as a last resort
(for no particular reason), so hands with the same ranks but different suits
will give preference to suits by Spades, Hearts, Clubs, Diamonds, unlike real
Texas Hold 'em.

If the tied hands are entirely community cards, the tie is broken by whatever
default computing order exists (probably the order the players joined the round).
