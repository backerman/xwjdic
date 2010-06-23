# xwjdic (temporary name) v0.01 #

This is a (currently highly experimental) front end for the JMDict/KANJIDIC2 files maintained by the [Electronic Dictionary Research and Development Group][1] at Monash University.  It is written from scratch using XQuery and Ruby, and does not use any of the legacy jdic code base.

My design goals for this system:
* Maximally portable code (to the limits of the XQuery specification), self-contained and easy to install
* Usable by both humans and machines
* Looks good (yay for [Blueprint][2])

License: WTFPL for my code; this repository also includes a copy of jQuery, which is licensed under the MIT License.  The dictionary files (available separately) are licensed under Creative Commons Attribution-Share Alike 3.0 Unported.

[1]: http://www.edrdg.org/
[2]: http://www.blueprintcss.org/
