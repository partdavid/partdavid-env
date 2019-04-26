# note

This program allows you to really efficiently create notes about what
you're doing with your time.  It's designed to put an end to
discussions about what you have been spending your time doing, because
you never remember the interruptions, extra work, administrative BS
that doesn't go into however you're tracking your 'real work'.


## Usage

Use `note --help` to get a usage note.

## Notes

A note is a structured document with a very light "data model"
describing an activity. A note consists of free text (the note text
itself, like "helped with SSH"), and some metadata (field-value pairs,
like `help=bob` (meaning Bob was the person you helped; or `time=2h`
to reflect that you spent a couple hours on it). The data model is
"lightly structured" because there is some small special handling for
fields name `timestamp` (which is set for you when you create a note),
`help` and `ticket`. When you view notes, these fields will show up in
tabular form along with the note text--any other fields you set are
preserved, and you can use them to selectively list notes, but they
are displayed in a JSON blob under the next text.

### Creating Notes

You create notes with a single invocation of the `note` command. Since
`--action` defaults to `create`, you can omit it, and just type the
metadata fields as `field=value` and the text of the note after it.
You don't usually need to quote these words.

```
note project=deployment time=2h read up on cloud providers
```

You can't put the metadata after the free text. Remember that you can
provide as many metadata fields as you want, but `time`, `ticket` and
`help` are displayed in a friendly way.

You can quote the words (or parts of them) to include shell metacharacters.
You can also use `-` to show that you want the note text read from stdin.
However, multi-line notes are not displayed very well.

As a matter of style, it's best to consider notes informal, unpunctuated
and short--reminders and summaries, not documentation. If you need to write
a paragraph to describe what you did, make a comment on a ticket.

### Listing Notes

If you invoke `note` with metadata arguments or note text, it creates a note.
Without them, or when you specify `--action list`, the program lists your notes.

If you specify `--action list`, then any metadata fields and note text
are taken as conditions restricting the list of notes to display. You can also
use the `--select <condition>` option (possibly multiple times) for the same
purpose. The following command-lines are equivalent (short-option equivalents
are omitted):

```
note --action list project=deployment discuss
note --action list --select project=deployment --select discuss
note --select project=deployment --select discuss
```

Note, however that the following are not equivalent:

```
note --action list --select project=deployment discuss
# produces a warning that `discuss` will be ignored because only the --select conditions are honored
note project=deployment discuss
# creates a new note with text "discuss" and the project field set to "deployment"
```

As with note creation, any "bare text" included is matched against the
note texts. If the text string is included anywhere in the note, the note matches.
Likewise, you have more options that exact equality when matching fields, depending
on what you put after the `=` sign in the metadata expression.

If you leave the value blank, then notes will be selected that have a blank or missing
value for the field. For this purpose, there is no difference between a note that
does not have the field; a note that has the field but the value is `null`; and a
note that has the field and the value is an empty string.

```
note --select time=
# Lists notes with no `time` field value
```

If you surround the value with slashes (`/`), then the value is interpreted as
a regular expression.

```
note --select help=/bob|robert/
# Lists notes where `help` contains 'bob' or 'robert'
```

If you precede the value with tilde (`~`), then the value is interpreted as
a substring match.

```
note --select tag=plus
# Lists notes where `tag` contains the string `plus`
```

If you precede the value with less than (`<`) or greater than (`>`), then the
value is compared lexically to see if it's greater or less than the comparison.

```
note --select 'timestamp>2019-02-20 11:59:59' --select 'timestamp<2019-04-20 12:00:00'
# Lists notes created between noon on February 20th and noon on April 20th
```

Note that when you specify multiple conditions, they must all be satisfied in order
to select the note (AND logic). There is no OR logic or logical groupings. You can
sometimes simulate some OR variations using regular expressions, as in the above example.

### Deleting Notes

You can use `--action delete` and `--select` to select notes for deletion. If you want to
delete a specific note, the safest way is to use `--action list` and then using
`note --action delete --select id=<id>` to remove only that specific note.

### Editing Notes

You can use `--action edit` to edit notes. Use `--select` to select the notes to be updated.
The other arguments on the command line are metadata fields to set on the edited notes, or
an updated note text. Note that there's no concept of "editing" a field value (including
the note text), only replacing it.

```
note --action edit --select id=1556302051.json time=2h discuss potential candidates
# Set the text of note 1556302051.json to "discuss potential candidates" and the `time` field
# to "2h"
```

```
note --action edit --select project=deployment time=
# Clear the `time` field of all notes with `project` equal to "deployment"
```

## Design Considerations

This command is designed to be very simple and used frequently for small-grained notes
about what you did. It's designed to assist your recall when figuring out (usually) what
got in the way of "real work". You will be surprised at how much time you spend it meetings,
on phone calls, etc.
