import module namespace jdic="http://facefault.org/xquery/jdic"
    at "xmldb:exist:///db/jdic/jdic.xqm";

import module namespace json="http://www.json.org";
declare option exist:serialize "method=text media-type=application/json";

let $char := lower-case(jdic:param("ucs", "54c0"))
let $xml := <index>
{
for $reading in //character[descendant::cp_value[@cp_type="ucs"] = $char]//dic_ref
(: FIXME add other attributes along with data($reading) :)
return element { $reading/@dr_type } { data($reading) }
}
</index>
return json:xml-to-json($xml)
