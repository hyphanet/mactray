#!/bin/sh

# Script to correct Xcode's XLIFF formatting and remove noise from developer notes
#
# Transifex will only accept "note" elements if they include a "from=developer" attribute

# fix developer note format for Transifex
perl -i -pe 's/<note>/<note from="developer">/' $1

# completey get rid of Xcode noise in XIB string developer notes
perl -i -pe 's/\s*Class\s=\s"\w+";\s*//' $1

perl -i -pe 's/\s*ObjectID\s=\s"[\w\s\-]*";\s*//' $1

# don't need the title or placeholders to be included in developer notes, they're redundant
perl -i -pe 's/\s*title\s=\s"[\w\s\-\?\/\,\.\:]*";\s*//' $1
perl -i -pe 's/\s*placeholderString\s=\s"[\w\s\-\?\/\,\.\:]*";\s*//' $1

# capture the nested developer note and replace the entire enclosed "Note=" string with the actual note
perl -i -pe 's/\s*Note\s=\s"([\w\s\-\?\/\\\,\.\:]*)";\s*/$1/' $1

