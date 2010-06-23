import module namespace jdic="http://facefault.org/xquery/jdic"
    at "xmldb:exist:///db/jdic/jdic.xqm";

import module namespace json="http://www.json.org";
(: FIXME need to declare raw collation :)
let $char := lower-case(jdic:param("char", "殺"))
return //character[literal = $char]
