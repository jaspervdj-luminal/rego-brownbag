---
title: 'Rego & Fugue Rules 101'
author: 'Jasper Van der Jeugt'
patat:
  incrementalLists: true
  eval:
    rego:
      command: fregot repl -v0
    sql:
      command: sqlite3
    javascript:
      command: node
    bash:
      command: bash
    eval:
      command: bash
      fragment: false
      replace: true
...

# Introduction

## About this talk

 -  Let's learn Rego
     *  We'll compare Rego to a few other languages, including ones which you
        may be familiar with including JavaScript and SQL.
     *  Gradually we'll focus deeper and deeper on what sets Rego apart.
     *  Packages, input, rules

 -  Fugue rules
     *  Simple rules
     *  Advanced rules
     *  Custom error messages

 -  Interactive part

 -  Advanced Rego topics
     *  Comprehensions
     *  Unification

## Tools

We're using fregot:

<https://github.com/fugue/fregot>

Releases > darwin binary works on Mac OS X.

. . .

Please stop me at any time to ask questions.

## Repository

<https://github.com/jaspervdj-luminal/rego-brownbag>

```eval
tree
```

# What is Rego?

## Rego is like JavaScript

Scalars: Numbers, strings, booleans, `null`

```rego
1 + 2
"Hello world"
false
null
```

## Rego is like JavaScript

Compound objects: Arrays

```rego
arr = [1, 2, 3, 4]
count(arr)  # ?
array.slice(arr, 0, 2)  # ?
arr[0]  # ?
sum(arr)  # ?
```

## Rego is like JavaScript

Compound objects: Objects

```rego
tags = {"owner": "Finance"}
tags.owner  # ?
```

## Rego is like JavaScript

Compound objects: Sets

```rego
allowed_ports = {80, 443, 8080}
count(allowed_ports)  # ?
allowed_ports[80]  # ?
intersection({allowed_ports, {8080}})  # ?
```

## Rego is like JavaScript

Built-in functions

```rego
re_match("^::", "::/0")  # ?
time.now_ns()  # ?
base64.encode("Hello world")  # ?
```

Full list at:

<https://www.openpolicyagent.org/docs/latest/policy-reference/#built-in-functions>

## Rego is like JavaScript

Find natural numbers that add up to 5:

```javascript
const numbers = [1, 2, 3, 4, 5];
var pairs = [];
for (const x of numbers)
  for (const y of numbers)
    if (x < y && x + y == 5)
      pairs.push([x, y]);

console.log(pairs);  // ?
```

## Rego is like JavaScript

Ok so Rego is actually not like JavaScript:

 -  Immutable (cannot modify `pairs` after assignment)
     *  Obviously has an effect on built-ins
     *  Functional Programming
 -  Not Turing Complete
     *  Guaranteed to terminate
     *  But not that hard to write a query that would take longer than the
        age of the universe to compute
 -  Declarative
     *  Order isn't that important
     *  Non Turing-Completeness allows for tricks™

## Rego is not like JavaScript

```rego
numbers = [1, 2, 3, 4, 5]
pairs[[x, y]] {
  x + y = 5
  x = numbers[i]
  y = numbers[j]
  i < j
}

pairs[_]  # ?
```

## Rego is like SQL

```sql
CREATE TABLE numbers (value INT);
INSERT INTO numbers (value) VALUES (1),(2),(3),(4),(5);

SELECT n1.value, n2.value
FROM numbers AS n1 JOIN numbers AS n2
WHERE n1.value < n2.value AND n1.value + n2.value = 5;
```

...but with first-class JSON support and friendlier syntax

## Rego is like jq

```bash
jq_script='
    .[] as $x | .[] as $y |
    select($x<$y) | select($x+$y==5) |
    [$x, $y]'
echo '[1, 2, 3, 4, 5]' | jq -c "$jq_script"
```

...but sometimes you can actually read the code

## Conclusion

 -  Operates on JavaScript values (with the addition of sets)
 -  Syntax looks like JavaScript
 -  But it's not an imperative language
 -  Closer to datalog, SQL, jq, prolog

# Modules, rules and queries

## The Rego tree

In Rego, everything is immutable, which means that almost* everything is data:

    data
    |-package a
    | |-package a.x
    |   |-rule a.x.foo
    |-package b
      |-rule b.bar

## The Rego tree

In `fregot repl`, you're always in the "open" package:

```rego
:open a.x
foo = 1
data  # ?
data.a.x.foo  # ?
```

## The Rego tree

```eval
cat rules/rule0.rego
```

```bash
fregot eval 'data' rules/rule0.rego | jq '.'
```

All your rules are just data!

## The Rego tree

Working with the Rego tree:

    import data.rules.aws.ports_by_account
    foo = ports_by_account.allowed_ports

. . .

    import data.rules.aws
    foo = aws.ports_by_account.allowed_ports

. . .

    import data.rules as top
    foo = top.aws.ports_by_account.allowed_ports

. . .

    foo = data.rules.aws.ports_by_account.allowed_ports

## The Rego tree

Aside from `data.`, there's `input.` which holds the _input document_.

You can set this by using `--input foo.json` on the command line or by using
`:input` in `fregot repl`:

```rego
:input inputs/resource1.json
input.id
```

## The Rego tree: conclusion

Two JSON trees:

 -  `input` is the static input JSON document.  In the case of Fugue Rules, this
    is either a single resource or a collection of resources.

 -  `data` is derived _from input_ through the rules you load, but it is also
    just a static document.

## What is inside the Rego tree?

Rules and functions.

    package rules.aws.ports_by_account

    resource_type = "aws_security_group"

## What is inside the Rego tree?

Rules can have _bodies_.  A body is a list of _queries_.

```eval
cat rules/rule1.rego
```

```rego
:input inputs/resource1.json
:load rules/rule1.rego
account_id  # ?
```

## What is a query?

A query is a pure function that takes the current environment, and produces a
list of new environments:

```rego
numbers = ["zero", "one"]
x = numbers[i]; [i, x]  # ?
```

## What is a query?

A query is a pure function that takes the current environment, and produces a
list of new environments:

```rego
numbers = ["zero", "one"]
x = "one"
x = numbers[i]; [i, x]  # ?
```

## What is a query?

A query is a pure function that takes the current environment, and produces a
list of new environments:

```rego
numbers = ["zero", "one"]
i = 3
x = numbers[i]; [i, x]  # ?
```

## What is a query?

A query is a pure function that takes the current environment, and produces a
list of new environments:

    numbers = ["zero", "one"]
    x = numbers[i]; [i, x]

 -  `{}           ->  [{i = 0, x = "zero"}, {i = 1, x = "one"}]`
 -  `{x = "one"}  ->  [{i = 1, x = "one"}]`
 -  `{i = 3}      ->  []`

## What is inside the Rego tree?

Rules can have _bodies_.  A body is a list of _queries_.

```eval
cat rules/rule1.rego
```

## How do I read queries?

    rule = result_1 {
        query_1_a
        query_1_b
    }

    rule = result_2 {
        query_2_a
        query_2_b
    }

Read as:

    IF query_1_a AND query_1_b THEN rule = result_1
    IF query_2_a AND query_2_b THEN rule = result_2

## How do I read queries?

    rule = result_1 {
        query_1_a
        query_1_b
    } {
        query_2_a
        query_2_b
    }

Read as:

    IF query_1_a AND query_1_b THEN rule = result_1
    IF query_2_a AND query_2_b THEN rule = result_1

Alternatively:

    IF (query_1_a AND query_1_b) OR (query_2_a AND query_2_b)
    THEN rule = result_1

## How do I read queries?

    rule {
        query_1_a
        query_1_b
    }

Read as:

    IF query_1_a AND query_1_b THEN rule = true

## How do I read queries?

    rule = result_1 {
        query_1_a
        query_1_b
    }

    default rule = result_2

Read as:

    IF query_1_a AND query_1_b THEN rule = result_1

    ELSE rule = result_2

## Kind of rules

There are different kinds of rules:

 -  Complete rule (_single result_)
 -  Set rules (_generate sets_)
 -  Object rules (_generate objects_)

And then there are functions which are slightly different:

 -  Partial rules (_aka functions_)

All of these rules can have a body consisting of queries.

## Kind of rules

### Set rules

```eval
cat rules/rule2.rego
```

```rego
:input inputs/resource1.json
:load rules/rule1.rego
:load rules/rule2.rego
allowed_ports  # ?
```

## Kind of rules

### Object rules

```eval
cat rules/rule3.rego
```

```rego
:input inputs/resource1.json
:load rules/rule1.rego
:load rules/rule3.rego
allowed_ports  # ?
```

## Kinds of rules

### Functions

What makes functions special?

```rego
double(x) = y {
  y = x + x
}
double(10)  # ?
```

We cannot iterate over all "double" values.

## Kinds of rules

### Functions

What makes functions special?

```rego
double[x] = y {
  nums = [1, 2, 3]
  x = nums[_]
  y = x + x
}
double[1]  # ?
double[_]  # ?
```

We can iterate over all "rule" values, because it must assign each variable
including `x`.

## Kinds of rules

### Functions

What makes functions special?

    double(x) = y {
      y = x * x
    }

Normal rules can be evaluated in different ways:

 -  `double[1]`: is `1` a member of the rule?  Give me it's value.
 -  `double[x]`: solve for `x`.
 -  `double`: give me the entire object.

Functions can only be evaluated in a single way:

 -  `double(2)`: What is double of `2`?

## Kinds of rules

### Tests

Tests are just normal rules that start with `test_`.

    test_double {
      double(1) == 2
    }

Just run `fregot test [all input files]` and you're done.

    fregot test aws/ azurerm/ fugue/
    passed: 630, failed: 0, errored: 0

# Fugue rules

## What are Fugue rules?

We've seen that Rego is really just a language for producing JSON based on an
input document, so any "engine" using Rego relies on _conventions_.

## Simple rules

```rego
:input inputs/resource1.json
input.ingress  # ?
```

## Simple rules

Conventions:

 -  There must be a `resource_type` rule (`string`)
 -  There must be a `deny` rule (`bool`)

```eval
cat rules/rule4.rego
```

## Simple rules

Evaluation

```bash
fregot eval 'data' rules/rule4.rego | jq '.'
```

## Simple rules

Interactive evaluation with `fregot repl`:

```rego
:load rules/rule4.rego
:input inputs/resource1.json
deny  # ?
```

## Simple rules

Conventions:

 -  There must be a `resource_type` rule (`string`)
 -  There must either be a `deny` rule (`bool`)...
 -  ...or an `allow` rule (`bool`)...
 -  ...or both.

Use whatever is easier!

## Simple rules

Conventions for custom messages:

 -  There must be a `resource_type` rule (`string`)
 -  There must be a `deny` rule (`set<string>`)

```rego
deny[msg] {
  true
  msg = "Not allowed"
}
deny  #?
```

## Advanced rules

```eval
cat rules/rule5.rego
```

## Advanced rules

Conventions:

 -  There must be a `policy` rule (`set<judgement>`)

You can use the `data.fugue` API to do this:

 -  `fugue.resources("resource_type")` gives you resources of a type
 -  `fugue.allow_resource(resource)` makes a valid judgement
 -  `fugue.deny_resource(resource)` makes an invalid judgement

## Advanced rules

Evaluation

```bash
fregot eval -i inputs/everything.json \
    'data.rules.aws.ports_by_account.policy' \
    lib/fugue.rego rules/rule5.rego | jq '.'
```

## Advanced rules

Are advanced rules "better"?

. . .

**No**

. . .

Should I use a advanced rule?

 -  Yes/no decision about a single resource: **No**
 -  Anything else: **Yes**

## Advanced rules

Conventions:

 -  There must be a `policy` rule (`set<judgement>`)

Full API:

 -  `fugue.resources(resource_type)`
 -  `fugue.allow_resource(resource)`
 -  `fugue.deny_resource(resource)`
 -  `fugue.missing_resource(resource)`
 -  `fugue.deny_resource_with_message(resource, msg)`
 -  `fugue.missing_resource_with_message(resource, msg)`
 -  `fugue.resource_types_v0`

# Interactive part

## Important links

Put `fregot` in your `PATH`: <https://github.com/fugue/fregot>

Run commands from the root of this repository:
<https://github.com/jaspervdj-luminal/rego-brownbag>

## Writing a rule

1.  Obtain input (this is the hard part)
2.  Write the rule (this is easy cruising)

## Writing a rule

We already have the input

       ---------------------------.
     `/""""/""""/|""|'|""||""|   ' \.
     /    /    / |__| |__||__|      |
    /----------=====================|
    | \  /V\  /    _.               |
    |()\ \W/ /()   _            _   |
    |   \   /     / \          / \  |-( )
    =C========C==_| ) |--------| ) _/==] _-{_}_)
     \_\_/__..  \_\_/_ \_\_/ \_\_/__.__.

## Writing a rule

Let's look at a rule

```bash
head -n 3 rules/ports_by_account.rego
```

Evaluating with `fregot repl --watch`:

```rego
:input inputs/resource2.json
:load rules/ports_by_account.rego
deny  # ?
account_id  # ?
```

# Advanced Rego topics

## Comprehensions

## Unification

```rego
provider = "provider.aws.us-east-1"
region = r {
  [_, _, r] = split(provider, ".")
}

region  # ?
```
