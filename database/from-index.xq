import module namespace jdic="http://facefault.org/xquery/jdic"
    at "xmldb:exist:///db/jdic/jdic.xqm";
let $index-name := jdic:param("name", "heisig")
let $index-number := jdic:param("number", "666")

return //character[descendant::dic_ref[@dr_type = $index-name] = $index-number]