Text::Markover
==============

Back in 2009, I thought it would be a good idea to write my own
[Markdown](http://daringfireball.net/projects/markdown/) parser in Perl. I had
some ideas on syntaxes for [definition
lists](http://www.justatheory.com/computers/markup/modest-markdown-proposal.html)
and
[tables](http://www.justatheory.com/computers/markup/markdown-table-rfc.html)
and wanted to make them so. So I started work using the only parser I knew anything
about, [HOP::Parser](http://search.cpan.org/perldoc?HOP::Parser).

After a while, I got busy with real work, not to mention frustrated with HOP
(which really was more of an experiment itself, although [the
book](http://hop.perl.plover.com/) is *great*), so the project went on
permanent hiatus.

Later, Dave Rolsky was kind enough to write
[Markdent::Dialect::Theory](http://search.cpan.org/perldoc?Markdent::Dialect::Theory),
which implement most of what I wanted. So if you're really interested, check
it out.

In the meantime, as my Subversion server is going away, I've moved the code to
[GitHub](https://github.com/theory/text-markover), on the off chance that
someone else might find it vaguely interesting.

Copyright and Licence
---------------------

Copyright (c) 2009, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
