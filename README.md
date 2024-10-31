# Zoc

Zoc is a block oriented, stack based concatenative programming language highly inspired by Zig.

# Functionalities
- Compiled
- Stack based
- Concatenative
- Strongly typed
- Programmed in itself
- No hidden allocations
- No hidden control flow
- Somewhat data oriented design
- Portable to *any* architecture

# Concepts
Everything is a block. The file itself, functions, variables etc.

Each block can be called. They can also contain data. They can be named, annonymous and inlined.

# Syntax
Everything is evaluated from top to bottom, left to right.

## Comments
Comments are marked as `//` and everything after it is ignored until `\n` (UNIX EOL only).

Doc comments are marked by `///` and are like regular comments. For now nothing is really planned but they should translate to markdown files.

## Stack descriptor
The stack descriptor is only used by the type checker to verify definitions.
The syntax is the following:
```
inT::outT
```
You can group types by putting parenthesis arround them.
```
(T, T)::T
```
If the input or output is null, yon can leave it blank
```
::T
```
Nesting parenthesis is allowed, but does not change anything but help with readability in some cases
```
T::(T, (T, T))
```
The order of the types, from left to right is top of the stack (TOS) to bottom of the stack (BOS)

## Definitions
In Zoc, mostly everything is defined by a definition. Definitions links to the next declared block. As the langage is strongly typed, they need a stack descriptor so the type checker know what to do.

Definitions are started by the `define` keyword followed by the name of it. The next seen stack descriptor is linked to the most recent definition.

By convention:
```
define myDefinition (...)::(...) { ... }
```

### Naming specifications
A name should always start by a letter (lower or upper case).

If a name starts by `>`, it will only be acessible by point syntax.

### Calling specifications
Calling a definition by its name will do what the block linked to it does.

If the definition return a pointer, yon can directly fetch its data with `@'name'` or store a data of the correct type with `!'name'`.

## Types

Types are used in 2 ways:
1. Making sure that types are OK with their usage
2. Getting the number of bytes needed for the specific type

### Integers
Integers are of size 8, 16, 32 and 64 bits and can be signed or unsigned.

They are referenced by `i` for signed and `u` for unsigned numbers follow by the number of bits.
```
i32 u16 u8 i64
```

### Booleans
Booleans are of size 1 byte.
`true` is represented by `1` and `false` by `0`. *But* in Zoc, `true` and `1` are totally different. They are denoted with `bool`.
```bool```

### Pointers
Pointers points to a type, and are themself types.
Fetching a pointer pushes on the stack the dereference of the values it points to.
```
*u8 -> u8
***u32 -> **u32
*(u8, u8, u8) -> u8 u8 u8
*(bool, (*u8, u32)) -> bool *u8 u32
```

### Strings (special)
Strings are delemited by `"` and can be multilines (as it is easyer to parse). They are stocked in data segment and push on the stack its length and pointer. So it is not really a type in itself.

Lenght is of type `u32` and the pointer is of type `*u8` as the string is an array of bytes.

### Operations
You can repeat any type to do, for example, an array.
```
u16 ** 10
```
Note that it only works between parenthesis.
