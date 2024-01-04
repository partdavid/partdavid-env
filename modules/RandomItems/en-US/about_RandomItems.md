# about_RandomItems

## Short description

Explains how to use RandomItems module to generate random/mock data.

## Long description

This module collects utilities allowing the user to flexibly define
random data to be used in situations like software testing or other
situations where mock data is desired. The following design priorities
influenced the implementation.

- Correctness
- Evenly-distributed randomness
- Ergonomics (cmdlets behave similarly to non-random equivalents)
- Efficiency

## Get-RandomIp

IP address generation has subtleties and tricks--you can't just
generate four random bytes. You probably need to make sure you didn't
accidentally choose a network, broadcast or loopback address, you may
want to place your IPs in particular networks, etc. The Get-RandomIp
cmdlet allows you to generate IPv4 or IPv6 addresses that meet
typical constraints (and allow you to configure the constraints,
as well).

## Get-RandomDate

Generating a random date turns out to also be more complicated than it
appears on the surface. You may want to generate a date in a certain
interval, or with setting a certain field to a value; but you can't
just generate any date and then set the field to that value. And you
find when you start trying to adjust dates, you get a problem with
incorrectness (generate a random 29th of the month, and getting Feb
29/Mar 1) or skewed distribution (constrain dates to spring over two
years; if you try to implement this be moving a random date into the
interval, some dates will be more likely than others.

This behaves similarly to Get-Date, otherwise.

## Get-RandomString and New-Password

Generates a random string which is useful in a lot of places where you
need a "well-behaved" string (no weird characters). By default, it ensures
that the first character is a letter and subsequent characters are letters
and numbers, but you can provide your own alphabet for each.

The New-Password cmdlet is essentially the same command, with a different
ergonomic focus, i.e., its default options are good for passwords of many
kinds.

## Get-RandomWord and New-Password

Gets a random word from a dictionary; by default, an English dictionary
bundled with the module, but can be any dictionary file (its built-in
dictionary is based on Linux's /usr/share/dict/words). You can also
provide an array of words or your own dict file (which can be any arbitrary
UTF-8-encoded text file).

## New-RandomItem

Generates an Item (usually a file or directory but can be an environment
variable or any other item with a Powershell provider) in a manner
similar to New-Item (and accepts some of its parameters). It allows
for a very flexible way to specifying a target item with a random name
(based on `mktemp`-style templates or EPS templates) as well as random,
or randomly-influenced contents using EPS templates. It's very easy, for
example, to set up a skeleton directory tree which is materialized with
random filenames and randomly-influenced contents, including random
numbers of files and directories.
