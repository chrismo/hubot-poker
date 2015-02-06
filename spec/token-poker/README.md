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
