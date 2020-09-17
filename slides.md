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
...

# What is Rego?

## Rego is like JavaScript

```javascript
const numbers = [1, 2, 3, 4, 5];
for (const x of numbers) {
  for (const y of numbers) {
    if (x < y && x + y == 5) {
      console.log(x + ", " + y);
    }
  }
}
```

## Rego is a query language

```rego
numbers = [1, 2, 3, 4, 5]
makes_ten[[x, y]] {
  x + y = 5
  x = numbers[i]
  y = numbers[j]
  i < j
}

makes_ten[_]  # ?
```

## Rego is like SQL

```sql
CREATE TABLE numbers (value INT);
INSERT INTO numbers (value) VALUES (1),(2),(3),(4),(5);

SELECT n1.value, n2.value
FROM numbers AS n1 JOIN numbers AS n2
WHERE n1.value < n2.value AND n1.value + n2.value = 5;
```

# Rules and queries

## Unification

```rego
provider = "provider.aws.us-east-1"
region = r {
  [_, _, r] = split(provider, ".")
}

region  # ?
```
