## Solitaire concepts
1. When we handle a stack ...
   1. What card is on top?
   2. What card is the transition?
   3. How do cards stack before and after transition?
2. When a card moves onto a stack
   1. if a card moves onto another card: inherit properties from card ... propagate
   2. if a card moves onto an empty stack: inherit properties from stack ... propagate

### What can stack?
1) alternate colours
2) same suits
3) nothing

### Development Approaches
YES YES  : Card Stack -> Card -> Card -> ... -> Card
NO NO NO : Card -> Card Stack 

YES YES : Card -> Card -> Card
YES YES : Card Stack -> Card Stack -> Card Stack

```
- CardStack
| - CardStack
| | - CardStack
| | | - CardStack
```

## Stuff I did offstream
### Stream 1 -> Stream 2
- documented new content in [StackableCard] and in [CardStack]
- minor adjustments for readability
### Stream 2 -> Stream 3
- added `Stuff I did offstream` section to this document and populated with accurate info
- updated documentation in several classes
  - added class-level descriptions
  - updated existing documentation to match functionality
  - added section markers when possible
  - added type info to [Globals] declarations
- modified [Globals]
  - changed [member Globals.deck_style] and [member Globals.discard_count] from `const` to `static var`
  - changed drag-and-drop flags from 4 boolean exports to a single bit-flag export
  - added corresponding enum in [Globals] as DragAndDrop
- updated logic in [DiscardStack], [GameBoard], and [DeckStack]
  - adjusted [DiscardStack] to flip all existing cards face-down before adding new cards
  - handles deck cycling
  - properly arranges cards in scene tree
  - properly arranges cards in their visual container
