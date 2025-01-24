# Zoc

Zoc is a block oriented, stack based concatenative programming language inspired by Zig, Forth and Porth.

The goal is to provide a feature-full language that can be self hosted and used for everyday programming (or not).

`Zoc` programs lives on the stack; no heap allocation except the ones you make.

`Zoc` have a strong typing that make errors harder to do.

# Features
- Compiled
- Stack based
- Concatenative
- Strongly typed
- No hidden allocations
- No hidden control flow
- Usable in production (or not)

# State
- [x] Lexer 🚧
- [x] Parser
- [x] ZIR generation
- [ ] Type analysis
- [ ] Semantic analysis
- [x] AIR generation
- [x] Code generation

# Roadmap
- [x] Basic arithmetic
- [ ] Basic type checking
- [ ] `@syscall`
- [x] Basic functions
- [ ] Stack manipulation
- [ ] Basic if else-if else
- [ ] Full arithmetic, logic and boolean operators
- [ ] More type checking
- [ ] Basic while
- [ ] Basic const and var
- [ ] Arrays and slices
- [ ] Pointer: reference and dereference
- [ ] Strings, characters and multiline strings
- [ ] Even more type checking
- [ ] Lifetime and scope
	- [ ] `defer`
- [ ] Basic for
- [ ] Basic enum
- [ ] Basic struct
- [ ] Basic union
- [ ] Some type checking
- [ ] Value capturing
- [ ] Basic builtins
	- [ ] `@import`
	- [ ] `@as`
	- [ ] `@intCast`
	- [ ] `@compileLog`
	- [ ] `@compileError`
	- [ ] `@panic`

# Quickstart
The `Zoc` compiler is fully written in Zig (0.13). The source code for the compiler sits in `src/`.

The compiler generate FASM assembly, so you'll need to have it installed.

To build and run the `Zoc` compiler
```
zig build run -- <args>
```

# Zoc internals
`Zoc` has 3 stacks:

1. data stack: your normal OS stack for all the data needed
2. working stack: pointers to the data in the data stack
3. return stack: pointers for returning from calls

The working and return stack are of fixed length.

# Language reference

Note that this is actually the goal of the project. It may change at any time.

## Comments
Comments starts with `//` and ends on the new line.

```zig
10 // 11 commented
12 +
```

## Values
### String
A string is a null-terminated slice of bytes (a pointer and a length).

Escaping sequences are supported:

- `\n` - new line
- `\r` - carriage return
- `\"` - double quote
- `\'` - single quote
- `\t` - tab
- `\xFF` - hexadecimal byte
- `\\` - back slash

```zig
"Hello, world!\n"
"Hello, C world!\n\x00"
```

#### Multiline string
They are started by `\\` and ended by a new line.

```zig
\\Hello,
\\multilined
\\world!
const text
```

### Character
The byte of the ASCII inside the quotes.

```zig
'a'
```

### Types
- `u8`
- `u16`
- `u32`
- `u64`    - Only x86_64
- `i8`
- `i16`
- `i32`
- `i64`    - Only x86_64
- `usize`
- `isize`
- `bool`
- `type`
- `void`
- `comptime_int`

### Primitive values
- `true` and `false`
- `undefined`

### Assignments
The `const` keyword is user to assign a value to an identifier.
Its value is the current TOS. When possible the values are expanded during compilation.

```zig
"std" @import const std
10 const ten
struct { usize x usize y } const Pos
```

For a mutable value, use the `var` keyword. Variables are first `undefined` when created.

```zig
var number
11 !number
```

To specify the type of an assignment, put it after the keyword.

```zig
10 const i16 ten

var i16 number
```

## Variables
It is preferable to use `const` over `var`, thus the compiler enforce the use of `const` when a `var` is never mutated.

### Identifiers
Variable identifiers cannot shadow function identifiers. They must start with an alphabetical letter or under score and can contain numbers later.

If you cannot fit the requirements you can use the `@"..."` notation.

### Lifetime
Variables and constants only lives in the block they are defined into.

```zig
10 const ten // ten lives in all this file

fn void example void {
	var i16 example_var // only lives inside the example function
	struct {
		2 const two // two only lives in this struct but can be called from the struct  
	} const MyStruct
	MyStruct.two
}
```

## Integers
Integers are pushed on the stack by writing them.

```zig
10 const decimal
0xFE const hexadecimal
0xfea0 const longer_lowercase_hex
0o723 const octal
0b1001101101001 const binary

10_000_000_000 const ten_bilions
0xFA_FF_60_10_00 const some_bytes
0o7_5_5 const permissions
0b0000_1111_0000_1111 const mask
```

Decimals integers are not supported.

## Operators
Operator overloading is not supported.

### Arithmetic
- `+`  - addition
- `-`  - subtraction
- `*`  - multiplication
- `/`  - division
- `%`  - reminder
- `>>` - left shift
- `<<` - right shift
- `&`  - bitwise and
- `|`  - bitwise or
- `^`  - bitwise xor
- `~`  - bitwise not
- `++` - array concatenation
- `**` - array multiplication

### Logical
- `and` - boolean and
- `or`  - boolean or
- `not` - boolean not
- `=`   - equality
- `!=`  - inequality
- `<`   - less than
- `>`   - greater than
- `<=`  - less than equal
- `>=`  - greater than equal

### Stack
- `dup`   - duplicate the TOS
- `drop`  - delete the TOS
- `swap`  - swap the top 2 elements of the stack
- `over`  - copy the element below the TOS
- `rot`   - rotate the top 3 elements
- `.`     - use the TOS element
- `.N`    - use the TOS - N element

### Special
- `&a`  - the address of `a`
- `a.*` - dereference of `a`
- `!`   - store `>1` at `>`
- `!var`  - equivalent of `n &var !`

## Arrays
```zig
[_]u8{ 'h' 'e' 'l' 'l' 'o' } // push the array on the stack
dup const message
// array length
// accessing a field of an in-stack array does not consumes it
>len 5 = expect

// iterate oven an array
// using an array on the stack in for consumes it
0 swap for >1 in { // use one bellow TOS
	+
}
'h' 'e' 'l' 'l' 'o' + + + +
= expect
}

// You can define var and const with an array
var [100]i16 some_int

// array operation only works on comptime know arrays length
[_]i32{ 1 2 3 4 5 } const part_one
part_one [_]i32{ 6 7 8 9 10 } ++ const all_parts

// initialize an array
[_]u8{0} 10 **

>[3] 0 = // true
>len 10 = // true

// get the index from the stack
2 message[>] 'l' = expect
```

### Multidimensional arrays
```zig
[4][4]u8{ [_]u8{ 0 1 2 3 } ** 4 }
```

### Sentinel-terminated arrays
```zig
// null-terminated string
[_:0]u8{ 'h' 'e' 'l' 'l' 'o' }

>len 4 = expect
>[5] 0 = expect
```

## Pointers
There are two types of pointers: single-item and many-item pointers.

- `*T`   - single-item pointer to one item
    * Supports deref (`ptr.*`)
- `[*]T` - many-item pointer to unknown number of items
    * Supports index syntax (`ptr[i]`)
    * Supports slice syntax (`ptr[start..end]` and `ptr[start..]`)
    * Supports pointer arithmetic

Closely related to arrays and slices:

- `*[N]T` - pointer to N items, equivalent of a pointer to an array
    * Supports index syntax (`array_ptr[i]`)
    * Supports slice syntax (`array_ptr[start..end]`)
    * Supports len (`array_ptr.len`)
- `[]T`   - many-item pointer (`[*]T`) and a length (`usize`): a slice
    * Supports index syntax (`slice[i]`)
    * Supports slice syntax (`slice[start..end]`)
    * Supports len (`slice.len`)

To obtain a single-item pointer, use `&x`.

## Slices
A slice is a combination of a pointer and a length. The difference with an array is that the slice length is known at runtime.

### Sentinel terminated slices
```zig
"hello" // a string litteral is of type []const u8
// accessing a field of an in-stack slice does not consumes it
>.len 5 = // true
>[5] 0 = // true

var array
[_]u8{ 3 2 1 0 } !array

// slices have a runtime-know size
array[0..2 :2]
>.len 2 = // true
>[2] 2 = // true

// This will fail as array[2] isn't equal to 0. It will lead
// to a runtime panic
1 array[0..> :0] // slice array from 0 to >
drop
```

## struct
Note that a `Zoc` file is interpreted as a struct.

```zig

struct { i32: x i32: y } const Point

Point{ 37 !x 69 !y }

// accessing an in-stack struct does not consumes it
>x 37 = // true
>y 69 = // true

struct {
	*Node: prev
	*Node: next
} const Node

struct { i32: a i32: b }
// the struct type is not consumed 
>{ 1 !a 2 !b }

struct {
	usize: x1
	usize: x2
	usize: y1
	usize: y2

	// struct can have methods
	fn usize scalarProduct (*Pos) {
		>.x1 >.x2 * >1.y1 >1.y2 * +
	}
}
```

### Default field values
It allows the field to be omitted on struct assignement.

```zig
struct {
	i32: 1234 !a
	i32: b
} const Foo
```

### Anonymous struct
```zig
struct { i32: x i32: y } const Pos
var Pos pos

.{ 37 !.x 69 !.y } !pos
```



## enum
```zig
enum { ok not_ok } const Type

Type.ok const c

enum u8 { zero one two three } const Value

Value.zero @intFromEnum 0 = // true
Value.one @intFromEnum 1 = // true
Value.two @intFromEnum 2 = // true
Value.three @intFromEnum 3 = // true

enum u16 {
	hundred: 100
	thousand: 1_000
	million: 1_000_000
} const Value2

Value2.hundred @intFromEnum 100 = // true
Value2.thousand @intFromEnum 1000 = // true
Value2.million @intFromEnum 1000000 = // true

enum u8 {
	a: 3
	b
	c: 0
	d
}

// the enum is not consumed
>a @intFromEnum 3 = expect
>b @intFromEnum 4 = expect
>c @intFromEnum 0 = expect
>d @intFromEnum 1 = expect

enum {
	red green blue

	fn bool isRed (Color) {
		Color.red =
	}
} const Color

Color.red const color

color Color.isRed execpt

Color.green const color

color switch {
	.red => { false }
	.green => { true }
	.blue => { false }
} // true
```

## union
A union defines a set of possibles types that can be used by a value. Only one field can be acceded.

```zig
union {
	i32: int
	u32: uint
	bool: boolean
} const Payload

var Payload payload
Payload{ 10 !.int } !payload
	payload.uint // really unsafe, but it works
}
```

## Blocks
They are used to limit the scope of variable declarations and other builtin expressions.

### Shadowing
Identifiers cannot be named the same as an already existing identifier in the scope.

```zig
fn void hello (void) { }

{
	"hello hello" const hello // This will fail
}

// it's ok
{
	1 number const
}
{
	2 number const
}
```

## switch
```zig
10 const u32 a
100 const u32 b
a switch {
	0 => { 0 }
	// if 1, 2, 3, 4, 5, 6, 7, 8 or 9
	1...9 => { 1 }
	// You can switch a variable as long as it is know at comptime
	b => { 3 }
	// Switch needs to handle every case possible.
	// A lot of time else is mandatory
	else => { 99 }
} 99 = // true

enum { red green blue } const Color

Color.green switch {
	Color.red => { false }
	.green => { true } // the type is inferred
	.blue => { false }
	// No else as every case has been handled
} // true
```

## while
```zig
0 while 100 < do {
	1+
} 99 = // true
```

## for
```zig
[_]u32{ 1 2 3 4 5 } const items

// for loops iterates over arrays and slices
0 for items[0..2] in {
	+
} 3 = // true

// You can capture the value
0 for items in with value {
	// You can break or continue a for loop
	value 2 = if { continue }
	value +
} 13 = // true

// Multiple values are supported
// You can get the index with 0..
[_]u32{ 6 7 8 9 10 } const items2
var [5]u32 result
for items items2 0.. in with value value2 {
	value value2 + !result[>] // >0 gets consumed by ! and >1 by >
} result[3] 13 = // true

0 for 0..10 in {
	8 = if { break }
	1+
// else gets executed on breaking
} else {
	7 = // true
}
```

## if
```zig
4 const four
four 4 = if {
	true
} else { unreachable }

four 5 % 0= if {
	unreachable
} four 3 % 0= elif {
	unreachable
} four 2 % 0= elif {
	true
} else { unreachable }
```

## defer
Executes an expression on scope exit.

```zig
fn u32 deferExample (void) {
	var u32 a
	2 !a
	{ defer { 4 !a } }
	a 4 = // true
	5 !a
	a
}

deferExample 5 = // true 
```

Last deferred is first executed
```zig
"std" @import const std
std.debug.print const print

defer { "1 " print }
defer { "2 " print }
defer { "3\n" print }
// 3 2 1
```

Return value inside a defer expression is not allowed.
```zig
defer { 1 } // This will fail
```

## fn
```zig
// Parameters are on the stack. The same goes for the returned value(s)
fn i8 add (i8 i8) {
	+
}

fn bool greaterThan2 (i32) { 2 > }

// You can name parameters.
// Named parameters are immutable.
fn i8 sub (i8 i8) with a b {
	a b -
}

// extern tells the compiler that exist outside the Zoc code.
// Currently only C is supported.
extern fn i32 something (i32 i32)

// inline inline a function instead of calling it when invoked.
inline fn i32 div (i32 i32) { / }
```

## with
`with` is used to associate an identifier to a value in a scope. It can be used in `if`, `elif`, `else`, `while`, `for`, `switch`, `defer` and `fn` with the syntax:

```zig
<keyword> with <identifiers> { <expressions> }
```

```zig
fn usize main (usize *[]const u8) with argc argv {
	0
}
```

## asm
It is used for calling assembly inside the code.

```zig
fn void exit (void) asm {
	\\mov rax, 60
	\\mov rdi, 0
	\\syscall
}
// Or
fn void exit (void) {
	asm {
		\\mov rax, 60
		\\mov rdi, 0
		\\syscall
	}
}
```

## Builtins
### Syscall
Perform a syscall with n args.

```zig
0 60 1 @syscall // exit
```

### Import
Imports a file as a value.

Example:
```zig
"std" @import const std
```

### As
Performs a type coercion on a definition. It can not work.

```zig
10 const ten: i16
ten i32 @as
```

### BitCast
Convert a value from one type to another. The size of both types must be the same. The return type is inferred.

```zig
10 0- const i16 ten
ten @bitCast
```

### SizeOf
Return the size it takes to store a type.

```zig
i64 @sizeOf // 8
```

### ByteSwap
Convert a big endian to little endian and little endian to big endian. It only works on integers types.

```zig
10 const i16 ten
ten @byteSwap
```

### CompileError
Throw an error on compilation when semantically analyzed.

```zig
"it does not compiles" @compileError
```

### CompileLog
Prints the arguments passed to it at compile time.

Example:
```zig
10 const ten
"ten: " .{ ten } @compileLog
```

### EmbedFile
Equivalent of a null-terminated string literal with the file content. The path is taken from the zoc file.

Example:
```zig
"file.txt" @embedFile const file
```

### IntFromEnum
Converts a enum value into an integer. The return type is `comptime_int`.

Exemple:
```zig
enum u8 { red green blue } const Color
Color.red @intFromEnum // 0
```

### EnumFromInt
Converts an integer into an enum value. The return type is the inferred result type.

Example:
```zig
enum u8 { reg green blue } const Color
Color 1 @enumFromInt // Color.green
```

### IntCast
Converts an integer to another integer while keeping the same value. It can fail.

Example:
```zig
fn i32 example (i32) { ... }
10 const i16 ten
ten @intCast example
```

### IntFromBool
Converts `true` to `@as(u1, 1)` and `false` to `@as(u1, 0)`.

### IntFromPtr
Converts a pointer to an int of `usize`.

Example:
```zig
10 const i16 ten
&ten @intFromPtr // ptr to `ten`
```

### PtrFromInt
Converts an integer of `uzise` to a pointer of the inferred type.

Example:
```zig
0xA00 const something
something @ptrFromInt const *i16 a_thing
```

### Memcpy
Copies bytes from one region to another.

The destination and the source must be a mutable slice or a pointer to a mutable array. At least one of the elements must have a `len` field. If the two have one, they must be equal.

```zig
source dest @memcpy
```

### PtrCast
Converts a pointer of one type to the pointer of another type.

```zig
value: anytype @ptrCast anytype
```

### SizeOf
Returns the number of bytes needed to store `T`.

```zig
T: type @sizeOf comptime_int
```

### TagName
Converts an enum or union value of to a string literal.

Example:
```zig
enum { red green blue } const Color
Color.red @tagName // "Color.red"
```

### This
Return the type where the function is called.

Example:
```zig
@This const Self

[]u8 items

fn void printItems (*Self) with self {
	self.items for i in {
		i printi
	}
}
```

### Panic
Panic when executed in runtime

Example:
```zig
fn i32 div (i32 i32) {
	dup 0= if { "Dividing by 0 is not allowed" @panic }
	/
}
```
