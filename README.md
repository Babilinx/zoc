# Zoc

Zoc is a block oriented, stack based concatenative programming language highly inspired by Zig.

# Features
- Compiled
- Stack based
- Concatenative
- Strongly typed
- Errors as values
- Can call C function
- No hidden allocations
- No hidden control flow
- Somewhat data oriented design

# State
- [x] Lexer
- [ ] Parser 🚧
	- [ ] Ast
- [ ] ZIR generation
- [ ] Semantic analysis
	- [ ] Type analysis
- [ ] AIR generation
- [ ] Code generation
	- [ ] LLVM

# Roadmap
- [ ] Basic arithmetic
- [ ] Basic type checking
- [ ] Basic functions
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
- [ ] Optionals
- [ ] Error unions
- [ ] Value capturing
- [ ] Basic builtins
	- [ ] `@import`
	- [ ] `@as`
	- [ ] `@intCast`
	- [ ] `@compileLog`
	- [ ] `@compileError`
	- [ ] `@panic`

# Language reference
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
- `u64`
- `i8`
- `i16`
- `i32`
- `i64`
- `usize`
- `isize`
- `bool`
- `type`
- `void`
- `comptime_int`

### Primitive values
- `true` and `false`
- `null`
- `undefined`

### Assignments
The `const` keyword is user to assign a value to an identifier.
Its value is the current TOS.

```zig
10 const ten
```

For a mutable value, use the `var` keyword. Variables are first `undefined` when created.

```zig
var number
11 >number
```

To specify the type of an assignment, put it after a `:` after the identifier.

```zig
10 const ten: i16

var number: i16
```

To make the assignement visible on imports, add the `pub` keyword before it.

```zig
10 pub const ten

pub var number: i16
```

## Test
You can create tests right inside your program.

```zig
"std" @import const std
std.testing.expect const expect

test "addition" {
	1 2 +
	3 = try expect
}
```

You can also test if an expression returns an error.

```zig
test "error program" {
	try errorFunction
}
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
	var example_var: i16 // only lives inside the example function
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

### Special
- `a orelse { b }` - execute `b` if `a` is `null`
- `a catch { b }`  - execute `b` if `a` returns an error. Push the error on the stack
- `a.?`            - unwrap of `a`
- `&a`             - address of `a`
- `a.*`            - pointer dereference

## Arrays
```zig
"std" @import const std
std.testing.expect const expect

[_]u8{ 'h' 'e' 'l' 'l' 'o' } const message

test "array length" {
	message.len 5 = try expect 
}

test "iterate over an array" {
	0 message for byte in {
		byte +
	}
	'h' 'e' 'l' 'l' 'o' + + + +
	= try expect
}

var some_int: [100]i16

test "modify an array" {
	for &some_int 0.. in with {
		i @intCast >item.*
	}
	some_int[37] 37 = try expect
	some_int[69] 69 = try expect
}

// array operation only works on comptime know arrays length
[_]i32{ 1 2 3 4 5 } const part_one
part_one [_]{ 6 7 8 9 10 } ++ const all_parts

test "array concatenation" {
	i32 &all_parts &[_]{ 1 2 3 4 5 6 7 8 9 10 } std.mem.eql try expect
}

// initialize an array
[_]u8{0} 10 ** const zero_initialized

test "array multiplication" {
	zero_initialized[3] 0 = try expect
	zero_initialized.len 10 = try expect
}

test "get the index from the stack" {
	2 message[>] 'l' = try expect
}
```

### Multidimensional arrays
```zig
[4][4]u8{ [_]u8{ 0 1 2 3 } ** 4 } const multi_array
```

### Sentinel-terminated arrays
```zig
// null-terminated string
[_:0]u8{ 'h' 'e' 'l' 'l' 'o' } const hello

test "sentinel-terminated string" {
	hello.len 4 = try expect
	hello[5] 0 = try expect
}
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
"std" @import const std
std.testing.expect const expect

test "0-terminated slice" {
	"hello" const slice: [:0]const u8
	slice.len 5 = try try expect
	slice[5] 0 = try expect
}

test "sentinel-terminated slicing" {
	var array
	[_]u8{ 3 2 1 0 } >array
	var runtime_length: usize
	2 >runtime_length
	&runtime_length >_

	array[0..runtime_length :2] const slice
	slice.len 2 = try expect
	slice[2] 2 = try expect
}

test "sentinel mismatch" {
	var array
	[_]u8{ 3 2 1 0 } >array

	var runtime_length: usize
	2 >runtime_length
	&runtime_length >_

	// This will fail as array[2] isn't equal to 0. It will lead
	// to a runtime panic
	array[0..runtime_length :0] const slice
}
```

## struct
```zig
"std" @import const std
std.testing.expect const expect

struct { #x: i32 #y: i32 } const Point

Point{ 37 >.x 69 >.y } const p

Point{ 34 >.x undefined >.y } var p1
78 >p1.y

struct {
	#prev: ?*Node
	#next: ?*Node
	#data: T
} const Node

fn type LinkedList comptime type {
	struct {
		#first: ?*Node
		#last: ?*Node
		#len: usize
	}
}

test "linked list" {
	i32 LinkedList{ null >.first null >.last 0 >.len } const list
	var node: Node
	Node{ null >.prev null >.next 1234 >.data } >node
	i32 LinkedList{ &node >.first &node >.last 1 >.len } const list

	list.first.?.data 1234 = try expect
}
```

### Default field values
It allows the field to be omitted on struct assignement.

```zig
struct {
	1234 >#a: i32
	#b: i32
} const Foo
```

### Anonymous struct literals
It is allowed to omit the struct type of a literal.

The result struct can coerce to an already defined struct type, or by inferred.

```zig
struct { #x: i16 #y: i16 } const Point

var point: Point
.{ 45 >.x 64 >.y } >point

.{ 10 i16 @as >.some "value" >.thing } const something
```

### Tuples
Tuples are like anonymous structs but without specifying the name of the fields.

```zig
.{ 45 i16 @as true "hello\n" } const tuple

tuple[0] // 45
```

## enum
```zig
"std" @import const std
std.testing.expect const expect

enum { #ok #not_ok } const Type

Type.ok const c

enum(u8) { #zero #one #two #three } const Value

test "int from enum" {
	Value.zero @intFromEnum 0 = try expect
	Value.one @intFromEnum 1 = try expect
	Value.two @intFromEnum 2 = try expect
	Value.three @intFromEnum 3 = try expect
}

enum(u16) {
	100 >#hundred
	1_000 >#thousand
	1_000_000 >#million
} const Value2

test "set enum value" {
	Value2.hundred @intFromEnum 100 = try expect
	Value2.thousand @intFromEnum 1000 = try expect
	Value2.million @intFromEnum 1000000 = try expect
}

enum(u8) {
	3 >#a
	#b
	0 >#c
	#d
} const Value3

test "enum set and auto values" {
	Value3.a @intFromEnum 3 = try expect
	Value3.b @intFromEnum 4 = try expect
	Value3.c @intFromEnum 0 = try expect
	Value3.d @intFromEnum 1 = try expect
}

enum {
	#red #green #blue

	fn bool isRed Color {
		Color.red =
	}
} const Color

test "enum method" {
	Color.red const color

	color Color.isRed execpt
}

test "enum switch" {
	Color.green const color

	color switch {
		Color.red => { false }
		.green => { true } // This is also valid
		.blue => { false }
	} try expect
}

test "enum literals" {
	.blue const color: Color

	color .blue = expect // Valid as the types needs to be equal for an equality test
}
```

## union
A union defines a set of possibles types that can be used by a value. Only one field can be acceded.

```zig
union {
	#int: i32
	#uint: u32
	#boolean: bool
} const Payload

test "access of multiple fields" {
	var payload: Payload
	.{ 10 >.int } >payload
	payload.uint // Panic as the field int is already in use
}
```

### Tagged union
Unions can be declared with an enum type which makes it usable inside a switch expression.

```zig
enum { #ok #not_ok } const ReturnTypeTag
union(ReturnTypeTag) { #ok: u16 #not_ok: void } const ReturnType

test "switch on tagged union" {
	37 >.ok const ret: ReturnType

	ret switch {
		.ok => { ret.ok 10 = try expect }
		.not_ok => { unreachable }
	}
}
```

## Blocks
They are used to limit the scope of variable declarations and other builtin expressions.

### Shadowing
Identifiers cannot be named the same as an already existing identifier in the scope.

```zig
"hello" const hello

test "shadowing an identifier" {
	{
		"hello hello" const hello // This will fail
	}
}

test "same identifier on different scopes" {
	{
		1 number const
	}
	{
		2 number const
	}
}
```

## switch
```zig
test "simple switch" {
	10 const a: u32
	100 const b: u32
	a switch {
		0 => { 0 }
		// if 1, 2, 3, 4, 5, 6, 7, 8 or 9
		1...9 => { 1 }
		// You can switch a variable as long as it is know at comptime
		b => { 3 }
		// Switch needs to handle every case possible.
		// A lot of time else is mandatory
		else => { 99 }
	} 99 = try expect
}

enum { #red #green #blue } const Color

test "switch enum" {
	Color.green switch {
		.red => { false }
		.green => { true }
		.blue => { false }
		// No else as every case has been handled
	} try expect
}
```

### Tagged union field capture
```zig
struct { #x: i32 #y: i32 } const Point
union(enum) {
	#a: u32
	#b: i32
	#c: bool
	#d: Point
	#e // Normal enum field
} const Item

test "capture tagged union field on switch" {
	.{ 3 >.x 156 >.y } >.c const a

	a switch {
		.a .b => with *val { val.* 1+ >val.* }
		.c => with *val { val.* ! >val.* }
		.d => with *val { val.*.x 1+ >var.*.x val.*.y 1+ > val.*.y }
		.e => {}
	}
}
```

## while

### while with optionals
while loops can take an optional as a condition and loop while it is not `null`. It is possible to capture the value to use it.

```zig
var number_left: u32

fn ?u32 eventuallyNullSequence void {
	numbers_left 0= if { null } else { numbers_left 1- dup >numbers_left }
}

test "while null capture" {
	3 >number_left
	0 while eventuallyNullSequence do with value {
		value +
	} 3 = try expect
}
```

### while with error unions
Like with optionals while loops can work with error union as the condition.

```zig
var numbers_left: u32

fn  !32 eventuallyErrorSequence void {
	numbers_left 0= if { error.ReachedZero } else {
		numbers_left 1- dup >numbers_left
	}
}

test "while with error union" {
	3 >numbers_left
	while eventialyErrorSequence do with value {
		value +
	} else with err {
		err error.ReachedZero = try expect
	}
}
```

## for
```zig
test "basic for" {
	[_]u32{ 1 2 3 4 5 } const items

	// for loops iterates over arrays and slices
	0 for items[0..2] in {
		+
	} 3 = try expect

	// You can capture the value
	0 for items in with value {
		// You can break or continue a for loop
		value 2 = if { continue }
		value +
	} 13 = try expect

	// Multiple values are supported
	// You can get the index with 0..
	[_]u32{ 6 7 8 9 10 } const items2
	var result: [5]u32
	for items items2 0.. in with value value2 {
		value value2 + >result[>]
	} result[3] 13 = try expect
}

test "for else" {
	0 for 0..10 in {
		8 = if { break }
		1+
	// else gets executed on breaking
	} else {
		7 = try expect
	}
}
```

## if
```zig
test "if boolean" {
	4 const four
	four 4 = if {
		true expect
	} else { unreachable }
}

test "if error union" {
	var four: anyerror!u32
	4 >four

	// if not captured, the value is TOS
	four if {
		4 = expect
	} else { drop unreachable }

	error.NotFour >four

	// capture the values
	four if with value {
		value >_
	} else with err {
		err error.NotFour = try expect
	}
}

test "if optionals" {
	var four: ?u32

	4 >four
	four if {
		4 = expect
	// else don't have any value passed to it
	} else { unreachable }

	null >four
	four if { drop unreachable }
	else {
		true try expect
	}
}
```

## defer
Executes an expression on scope exit.

```zig
fn !u32 deferExample void {
	var a: u32
	2 >a
	{ defer { 4 >a } }
	a 4 = try expect
	5 >a
	a
}

test "defer" {
	try deferExample 5 = try expect 
}
```

Last deferred is first executed
```zig
std.io.print const print

test "defer order" {
	defer { "1 " print }
	defer { "2 " print }
	defer { "3\n" print }
}
// 3 2 1
```

Return value inside a defer expression is not allowed.
```zig
test "return value in defer" {
	defer { 1 } // This will fail
}
```

## unreachable
In debug builds `unreachable` gets replaced with `@panic`.
In release builds it is used for optimization.

```zig
test "unreachable" {
	2 3 + 5 != if { unreachable }
}
```

## Functions
```zig
// Parameters are on the stack. The same goes for the returned value(s)
fn i8 add (i8 i8) {
	+
}

// You can remove '()' if there is only one type
fn bool greaterThan2 i32 { 2 > }

// You can name parameters.
// Named parameters are immutable.
fn i8 sub (i8 i8) with a b {
	a b -
}

// extern tells the compiler that exist outside the Zoc code.
// The quoted identifier specify the library to use.
// Currently only "c" is supported.
"c" extern fn i32 something (i32 i32)

// callconv sets how the arguments are passed to the function when called
fn i32 somethingElse (i32 i32) .C callconv { + }

// inline inline a function instead of calling it when invoked.
inline fn i32 div (i32 i32) { / }

// pub make the function visible in imports with @import.
pub fn i32 mul (i32 i32) { * }
```

## Errors
An error set is like an enum. They are represented as an unsigned integer of 16 bits greater than 0.

```zig
error{
	#AccessDenied
	#OutOfMemory
	#FileNotFound
} const FileOpenError

fn FileOpenError foo void { .AccessDenied }

test "error sets" {
	foo .AccessDenied = try expect
}

// Shortcut for declaring error sets of 1 value
error.MyPrettyError
error{ #MyPrettyError }.MyPrettyError = try expect
```

### anyerror
`anyerror` refers to the global error set containing all error sets that are declared.

### Error union type
A lot of time it is useful to have a type that can be an error or a value. You can achieve that with `!`.

```zig
// Here the error set is inferred
fn !32 checkForNull ?i32 {
	if {} else { error.Null }
}

test "basic error union type" {
	32 checkForNull 32 = expect
	null checkForNull error.Null = try expect
}

error{
	#AccessDenied
	#FileNotFound
} const OpenFileError

fn OpenFileError![]u8 openFile []const u8  {
	//...
}

test "error union type 2" {
	"file.txt" try openFile drop
}
```

### catch
`catch` allow the execution of an expression when the previous expression returned an error.

```zig
error{ #DoesNotWork } const MyError
fn !i32 faulty void {
	MyError.DoesNotWork
}

test "catch" {
	faulty catch { drop 1 }
	1 = try expect
}

// You can also capture the error
test "catch with capture" {
	// Here you better do without the capture
	faulty catch with err {
		err switch {
			.DoesNotWork => {}
		}
	}
}
```

### try
Sometimes you want to return the error that you got. With catch you have:

```zig
error{ #DoesNotWork } const MyError
fn !i32 faulty void {
	MyError.DoesNotWork
}

test "catch return" {
	faulty catch { return }
	drop
}
```

`try` does that. It evaluates the expression, and if there is an error returned, the same error is returned. If there is no error, the returned value(s) gets on the stack.

```zig
test "try" {
	try faulty
}
```

### errdefer
`errdefer` is a `defer` that is only called when the scope exits with an error.

## Optionals
An optional is created by putting `?` in front of a type.

```zig
1234 const int: i32
1234 const optional_int: ?i32
```

### orelse
`orelse` execute the next expression if TOS is null.

```zig
var some_int: ?i32

test "orelse" {
	null >some_int

	some_int orelse { 37 } const number

	number 37 = try expect
}
```

## Builtins
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
10 0- const ten: i16
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
10 const ten: i16
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
.{ "ten: " ten } @compileLog
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
enum(u8) { #red #green #blue } const Color
Color.red @intFromEnum // 0
```

### EnumFromInt
Converts an integer into an enum value. The return type is the inferred result type.

Example:
```zig
enum(u8) { #reg #green #blue } const Color
1 @enumFromInt // Color.green
```

### IntCast
Converts an integer to another integer while keeping the same value. It can fail.

Example:
```zig
fn i32 example i32 { ... }
10 const ten: i16
ten @intCast example
```

### IntFromBool
Converts `true` to `@as(u1, 1)` and `false` to `@as(u1, 0)`.

### IntFromPtr
Converts a pointer to an int of `usize`.

Example:
```zig
10 const ten: i16
&ten @intFromPtr // ptr to `ten`
```

### PtrFromInt
Converts an integer of `uzise` to a pointer of the inferred type.

Example:
```zig
0xA00 const something
something @ptrFromInt const a_thing: *i16
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

#items: []u8

fn void printItems *Self with self {
	self.items for i in {
		i printi
	}
}
```

### TypeName
Convert a type to a string literal.

Example:
```zig
enum { reg green blue } const Color
Color @typeName // "Color"
```

### TypeOf
Return the type of an expression. The expressions will not have any runtime effect.

Example:
```zig
fn [:0]const u8 humainType type {
	switch {
		i8 => { "i8" }
		i16 => { "i16" }
		i32 => { "i32" }
		i64 => { "i64" }
		else => { "something else" }
	}
}

10 const ten: i16
ten @TypeOf humainType print
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