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
...

# What is Rego?

## Introduction

We'll compare Rego to a few other languages, including ones which you may
be familiar with including JavaScript and SQL.

. . .

Gradually we'll focus deeper and deeper on what sets Rego apart.

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

## Rego is like JavaScript

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

## Rego is a query language

Ok but actually no

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

## Rego is like jq

```bash
jq_script='
    .[] as $x | .[] as $y |
    select($x<$y) | select($x+$y==5) |
    [$x, $y]'
echo '[1, 2, 3, 4, 5]' | jq "$jq_script"
```

## Conclusion

 -  Operates on JavaScript values (with the addition of sets)
 -  Syntax looks like JavaScript
 -  But it's not an imperative language
 -  Closer to datalog, SQL, jq, prolog

# Rules and queries

## Unification

```rego
provider = "provider.aws.us-east-1"
region = r {
  [_, _, r] = split(provider, ".")
}

region  # ?
```
