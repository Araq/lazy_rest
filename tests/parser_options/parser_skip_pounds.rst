=====================================
lazy_rest parsing test to skip pounds
=====================================

Intro
-----

This rst file has some embedded pounds signs (#) which will be discarded.

# This is a pound block
# that will be skipped
# if the appropriate
# parser option is true

Middle
------

So, did that work?

#This one won't be indented as
#a block visually because we
#are not leaving any space between
#the hash and the body

##   How about
##   a second double
##   pounded skip block?

Last
----

These won't be ignored

### Triple hashes with pound skipping
### will work like a single column
### of hashes does in the normal
### parsing mode, since the first two
### are discarded but the third remains
