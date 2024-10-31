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
Each block can be called. They can also contain data. They can be named, annonimous and inlined.

# Syntax
Everything is evaluated from top to bottom, left to right.

## Comments
Comments are marked as `//` and everything after it is ignored until `\n` (UNIX EOL only).

Doc comments are marked by `///` and are like regular comments. For now nothing is really planned but they should translate to markdown files.

## Definitions
In Zog, mostly everything is defined by a definition. Definitions links to the next declared block. As the langage is strongly typed, they need a stack descriptor so the type checker know what to do.

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

If the definition return a pointer, yon can directly fetch its data with `@\`name\`` or store a data of the correct type with `!\`name\`.
