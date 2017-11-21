# semver - PL/SQL Semantic Versioning

Implements [Semver 2.0.0](http://www.semver.org) specification

## Versions

A `version` is described by the `v2.0.0` specification found at
<http://semver.org/>.

A leading `"="` or `"v"` character is stripped off and ignored.

## Ranges

A `range` is a set of sets of `comparators` which specify versions
that satisfy the range.

A `comparator` is composed of an `operator` and a `version`.  The set
of primitive `operators` is:

* `<` Less than
* `<=` Less than or equal to
* `>` Greater than
* `>=` Greater than or equal to
* `=` Equal.  If no operator is specified, then equality is assumed,
  so this operator is optional, but **MAY** be included.

For example, the comparator `>=1.2.7` would match the versions
`1.2.7`, `1.2.8`, `2.5.3`, and `1.3.9`, but not the versions `1.2.6`
or `1.1.0`.

Comparators can be joined by whitespace to form a `comparator set`,
which is satisfied by the **intersection** of all of the comparators
it includes.

A range is composed of one or more `comparator sets`, joined by `||`.  A
version matches a range if and only if every comparator in at least
one of the `||`-separated comparator sets is satisfied by the version.

For example, the range `>=1.2.7 <1.3.0` would match the versions
`1.2.7`, `1.2.8`, and `1.2.99`, but not the versions `1.2.6`, `1.3.0`,
or `1.1.0`.

The range `1.2.7 || >=1.2.9 <2.0.0` would match the versions `1.2.7`,
`1.2.9`, and `1.4.6`, but not the versions `1.2.8` or `2.0.0`.

### Prerelease Tags

> Warning: Change from the Semver specification
>
> If a version has a prerelease tag (for example, `1.2.3-alpha.3`) then
it will only be allowed to satisfy comparator sets if at least one
comparator with the same `[major, minor, patch]` tuple also has a
prerelease tag.
> 
> For example, the range `>1.2.3-alpha.3` would be allowed to match the
version `1.2.3-alpha.7`, but it would *not* be satisfied by
`3.4.5-alpha.9`, even though `3.4.5-alpha.9` is technically "greater
than" `1.2.3-alpha.3` according to the SemVer sort rules.  The version
range only accepts prerelease tags on the `1.2.3` version.  The
version `3.4.5` *would* satisfy the range, because it does not have a
prerelease flag, and `3.4.5` is greater than `1.2.3-alpha.7`.

The purpose for this behavior is twofold.  First, prerelease versions
frequently are updated very quickly, and contain many breaking changes
that are (by the author's design) not yet fit for public consumption.
Therefore, by default, they are excluded from range matching
semantics.

Second, a user who has opted into using a prerelease version has
clearly indicated the intent to use *that specific* set of
alpha/beta/rc versions.  By including a prerelease tag in the range,
the user is indicating that they are aware of the risk.  However, it
is still not appropriate to assume that they have opted into taking a
similar risk on the *next* set of prerelease versions.

#### Prerelease Identifiers

The method `semver.inc` takes an additional `identifier` string argument that
will append the value of the string as a prerelease identifier:

```
SQL> select semver.inc('1.2.3', 'prerelease', 'beta') as new_version from dual;

NEW_VERSION            
------------
1.2.4-beta.0
```

### Advanced Range Syntax

Advanced range syntax desugars to primitive comparators in
deterministic ways.

Advanced ranges may be combined in the same way as primitive
comparators using white space or `||`.

#### Hyphen Ranges `X.Y.Z - A.B.C`

Specifies an inclusive set.

* `1.2.3 - 2.3.4` := `>=1.2.3 <=2.3.4`

If a partial version is provided as the first version in the inclusive
range, then the missing pieces are replaced with zeroes.

* `1.2 - 2.3.4` := `>=1.2.0 <=2.3.4`

If a partial version is provided as the second version in the
inclusive range, then all versions that start with the supplied parts
of the tuple are accepted, but nothing that would be greater than the
provided tuple parts.

* `1.2.3 - 2.3` := `>=1.2.3 <2.4.0`
* `1.2.3 - 2` := `>=1.2.3 <3.0.0`

#### X-Ranges `1.2.x` `1.X` `1.2.*` `*`

Any of `X`, `x`, or `*` may be used to "stand in" for one of the
numeric values in the `[major, minor, patch]` tuple.

* `*` := `>=0.0.0` (Any version satisfies)
* `1.x` := `>=1.0.0 <2.0.0` (Matching major version)
* `1.2.x` := `>=1.2.0 <1.3.0` (Matching major and minor versions)

A partial version range is treated as an X-Range, so the special
character is in fact optional.

* `""` (empty string) := `*` := `>=0.0.0`
* `1` := `1.x.x` := `>=1.0.0 <2.0.0`
* `1.2` := `1.2.x` := `>=1.2.0 <1.3.0`

#### Tilde Ranges `~1.2.3` `~1.2` `~1`

Allows patch-level changes if a minor version is specified on the
comparator.  Allows minor-level changes if not.

* `~1.2.3` := `>=1.2.3 <1.(2+1).0` := `>=1.2.3 <1.3.0`
* `~1.2` := `>=1.2.0 <1.(2+1).0` := `>=1.2.0 <1.3.0` (Same as `1.2.x`)
* `~1` := `>=1.0.0 <(1+1).0.0` := `>=1.0.0 <2.0.0` (Same as `1.x`)
* `~0.2.3` := `>=0.2.3 <0.(2+1).0` := `>=0.2.3 <0.3.0`
* `~0.2` := `>=0.2.0 <0.(2+1).0` := `>=0.2.0 <0.3.0` (Same as `0.2.x`)
* `~0` := `>=0.0.0 <(0+1).0.0` := `>=0.0.0 <1.0.0` (Same as `0.x`)
* `~1.2.3-beta.2` := `>=1.2.3-beta.2 <1.3.0` Note that prereleases in
  the `1.2.3` version will be allowed, if they are greater than or
  equal to `beta.2`.  So, `1.2.3-beta.4` would be allowed, but
  `1.2.4-beta.2` would not, because it is a prerelease of a
  different `[major, minor, patch]` tuple.

#### Caret Ranges `^1.2.3` `^0.2.5` `^0.0.4`

Allows changes that do not modify the left-most non-zero digit in the
`[major, minor, patch]` tuple.  In other words, this allows patch and
minor updates for versions `1.0.0` and above, patch updates for
versions `0.X >=0.1.0`, and *no* updates for versions `0.0.X`.

Many authors treat a `0.x` version as if the `x` were the major
"breaking-change" indicator.

Caret ranges are ideal when an author may make breaking changes
between `0.2.4` and `0.3.0` releases, which is a common practice.
However, it presumes that there will *not* be breaking changes between
`0.2.4` and `0.2.5`.  It allows for changes that are presumed to be
additive (but non-breaking), according to commonly observed practices.

* `^1.2.3` := `>=1.2.3 <2.0.0`
* `^0.2.3` := `>=0.2.3 <0.3.0`
* `^0.0.3` := `>=0.0.3 <0.0.4`
* `^1.2.3-beta.2` := `>=1.2.3-beta.2 <2.0.0` Note that prereleases in
  the `1.2.3` version will be allowed, if they are greater than or
  equal to `beta.2`.  So, `1.2.3-beta.4` would be allowed, but
  `1.2.4-beta.2` would not, because it is a prerelease of a
  different `[major, minor, patch]` tuple.
* `^0.0.3-beta` := `>=0.0.3-beta <0.0.4`  Note that prereleases in the
  `0.0.3` version *only* will be allowed, if they are greater than or
  equal to `beta`.  So, `0.0.3-pr.2` would be allowed.

When parsing caret ranges, a missing `patch` value desugars to the
number `0`, but will allow flexibility within that value, even if the
major and minor versions are both `0`.

* `^1.2.x` := `>=1.2.0 <2.0.0`
* `^0.0.x` := `>=0.0.0 <0.1.0`
* `^0.0` := `>=0.0.0 <0.1.0`

A missing `minor` and `patch` values will desugar to zero, but also
allow flexibility within those values, even if the major version is
zero.

* `^1.x` := `>=1.0.0 <2.0.0`
* `^0.x` := `>=0.0.0 <1.0.0`

### Range Grammar

Putting all this together, here is a Backus-Naur grammar for ranges,
for the benefit of parser authors:

```bnf
range-set  ::= range ( logical-or range ) *
logical-or ::= ( ' ' ) * '||' ( ' ' ) *
range      ::= hyphen | simple ( ' ' simple ) * | ''
hyphen     ::= partial ' - ' partial
simple     ::= primitive | partial | tilde | caret
primitive  ::= ( '<' | '>' | '>=' | '<=' | '=' | ) partial
partial    ::= xr ( '.' xr ( '.' xr qualifier ? )? )?
xr         ::= 'x' | 'X' | '*' | nr
nr         ::= '0' | ['1'-'9'] ( ['0'-'9'] ) *
tilde      ::= '~' partial
caret      ::= '^' partial
qualifier  ::= ( '-' pre )? ( '+' build )?
pre        ::= parts
build      ::= parts
parts      ::= part ( '.' part ) *
part       ::= nr | [-0-9A-Za-z]+
```

# `semver` API

## `semver_version` object type

**Attributes**

- `major` - major version
- `minor` - minor version
- `patch` - patch version
- `prerelease` - collection prerelease tags (`semver_tags`)
- `batch` - collection build tags (`semver_tags`)

**Methods**

- `semver_version(major, minor, patch, prerelease, build)` constructor function - create SemVer Version object if passed versions make up valid SemVer range object. Otherwise exception is thrown.
- `semver_version(version)` constructor function - create SemVer Version object from SemVer Version string. If string is invalid it throws exception. 
- `inc` member procedure
- `to_string` member function - return formatted SemVer object as string.
- `compare` member function - compare SemVer version with version passed in parameter and return 
    - `-1` if less than 
    - `0` if equal 
    - `1` if greater than 

## `semver_comparator` object type

**Attributes**

- `operator` - comparison operator to compare other SemVer version with comparator's `version` - one of `=`, `!=`, `<`, `<=`, `>`, `>=`
- `version` - SemVer `semver_version` object - boundary of interval

**Methods**

- `to_string` member function - return comparator formatted as string e.g.: `<=1.2.0`, `>1.3.1-beta`
- `test(version)` member function - `version` satisfies comparision with comparators's `version` and `operator`.
- `intersects(comparator)` member function - return true if comparators intersects.
- `compare` member function - compare woth comparator object passed as param and return
    - `-1` if less than 
    - `0` if equal 
    - `1` if greater than 

## `semver_comparator_set` object type

**Attributes**

- `comparators` - comparators in set

**Methods**

- `to_string` - return comparator set as string - comparators are separated by space
- `test(version)` member function - return `true` if `version` satisfies all comparators in set

## `semver_range` object type

**Attributes**

- `comparator_sets` - set of `semver_comparator_set` objects

**Methods**

- `semver_range(range)` constructor function - parses `range` SemVer range string. Throws if `range` is not a valid SemVer Range string
- `to_string` member function - return range formatted as string. separate individual comparator sets with `||` 
- `test(version)` member function - `version` satisfies at leas one set of comparators in range.
- `intersects(range)` meber function - `range` intersects range

## `semver` package methods

PL/SQL Semver does not implement loose version of parser, yet, so not-quite-valid semver strings are rejected.

Strict-mode Comparators and Ranges are strict about the SemVer
strings that they parse.

- `parse(version)` - Parse version into `semver_version` object.
- `valid(version)` - Return the parsed version, or null if it's not valid.
- `inc(version, release, identifier)` - Return the version incremented by the release type (`major`,   `premajor`, `minor`, `preminor`, `patch`, `prepatch`, or `prerelease`), or null if it's not valid
    - `premajor` in one call will bump the version up to the next major version and down to a prerelease of that major version. `preminor`, and `prepatch` work the same way.
    - If called from a non-prerelease version, the `prerelease` will work the same as `prepatch`. It increments the patch version, then makes a prerelease. If the input version is already a prerelease it simply
increments it.
    - optionally specify prerelease `identifier` that will be appended to version
- `major(version)` - Return the major version number.
- `minor(version)` - Return the minor version number.
- `patch(version)` - Return the patch version number.
    - `prerelease(version)` - Returns an array of prerelease components, or null
  if none exist. Example: `prerelease('1.2.3-alpha.1') -> ['alpha', 1]`
    - `intersects(r1, r2, loose)` - Return true if the two supplied ranges
  or comparators intersect.
  
### Version Comparison

- `gt(version1, version2)` - `version1 > version2`
- `gte(version1, version2)` - `version1 >= version2`
- `lt(version1, version2)` - `version1 < version2`
- `lte(version1, version2)` - `version1 <= version2`
- `eq(version1, version2)` - `version1 = version2` This is true if they're logically equivalent, even if they're not the exact same string.
- `neq(version1, version2)` - `version1 != version2` The opposite of `eq`.
- `cmp(version1, operator, version2)` - Pass in a comparison string, and it'll call
  the corresponding function above. Throws if an invalid comparison string is provided.
- `compare(version1, version2)` - Return `0` if `version1 == version2`, or `1` if `version1` is greater, or `-1` if
  `version2` is greater.  Sorts in ascending order if passed to `Array.sort()`.
- `rcompare(version1, version2)` - The reverse of compare.  Sorts an array of versions
  in descending order when passed to `Array.sort()`.
- `diff(version1, version2)` - Returns difference between two versions by the release type
  (`major`, `premajor`, `minor`, `preminor`, `patch`, `prepatch`, or `prerelease`),
  or null if the versions are the same.

### Ranges

- `valid_range(range)` - Return the valid range or null if it's not valid.
- `satisfies(version, range)` - Return `true` if the `version` satisfies the
  `range`.
- `max_satisfying(versions, range)` - Return the highest version in the list
  that satisfies the range, or `null` if none of them do.
- `min_satisfying(versions, range)` - Return the lowest version in the list
  that satisfies the range, or `null` if none of them do.
- `gtr(version, range)` - Return `true` if version is greater than all the
  versions possible in the range.
- `ltr(version, range)` - Return `true` if version is less than all the
  versions possible in the range.
- `intersects(range1, range2)` - Return true if any of the ranges comparators intersect

Note that, since ranges may be non-contiguous, a version might not be
greater than a range, less than a range, *or* satisfy a range!  For
example, the range `1.2 <1.2.9 || >2.0.0` would have a hole from `1.2.9`
until `2.0.0`, so the version `1.2.10` would not be greater than the
range (because `2.0.1` satisfies, which is higher), nor less than the
range (since `1.2.8` satisfies, which is lower), and it also does not
satisfy the range.

If you want to know if a version satisfies or does not satisfy a
range, use the `satisfies(version, range)` function.