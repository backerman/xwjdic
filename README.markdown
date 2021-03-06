# xwjdic (temporary name) v0.01 #

_This project is totally stale so I'm archiving it. -BSA 2020-05-21_

This is a (currently highly experimental) front end for the JMDict/KANJIDIC2/JMnedict files maintained by the [Electronic Dictionary Research and Development Group][1] at Monash University.  It is written from scratch using XQuery and Ruby, and does not use any of the legacy jdic code base.

My design goals for this system:

* Maximally portable code (to the limits of the XQuery specification), self-contained and easy to install
* Usable by both humans and machines
* Looks good (yay for [Blueprint][2])

License: [WTFPL][3] for my code; this repository also includes a copy of [jQuery][4], which is licensed under the [MIT/GPLv2 (take your pick) licenses][5].  The [dictionary][6] [files][7] (available separately) are licensed under [Creative Commons Attribution-Share Alike 3.0 Unported][8].

## Installation notes ##

Remove "thin" from the Gemfile before deploying with Passenger.

FreeBSD requires `/usr/ports/converters/ruby-iconv` to be installed for activesupport
to work properly.

You will need to copy the following configuration templates and edit them appropriately:

* deploy-config.xml.tmpl &rarr; deploy-config.xml
* config/database.rb.tmpl &rarr; config/database.rb

To deploy the database files to the eXist server, run `ant deploy`.

[1]: http://www.edrdg.org/
[2]: http://www.blueprintcss.org/
[3]: http://sam.zoy.org/wtfpl/
[4]: http://jquery.com/
[5]: http://jquery.org/license
[6]: http://www.csse.monash.edu.au/~jwb/kanjidic2/index.html
[7]: http://www.csse.monash.edu.au/~jwb/edict_doc.html
[8]: http://creativecommons.org/licenses/by-sa/3.0/
