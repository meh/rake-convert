rake-convert - Convert Rakefiles to Makefile/configure
======================================================

This is a simple rake plugin that converts the Rakefile to a Makefile and mkmf stuff into a
configure script.

Useful to have a flexible building system like Rake while maintaining no dependencies to build.

Look at https://github.com/meh/craftd to see an example of a convertable Rakefile.

To let the configure script exit with an error after a failed check make sure to use `have_* or die 'reason'`,
in this way rake-convert can generate an error message.

By default when using rake-convert all the mkmf functions always return false.
