(: Frequently-used functions :)
module namespace jdic="http://facefault.org/xquery/jdic";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace session="http://exist-db.org/xquery/session";

declare function jdic:param($param-name as xs:string, $default as xs:string)
    as xs:string
{
    let $result := request:get-parameter($param-name, $default, false())
    return $result
};

(: Order JMdict entries in order of ke_pri element. :)
declare function jdic:jmdict-priority($entry as element()) as xs:string
{
    let $entry-priority := $entry//ke_pri[starts-with(text(), "nf")]
    return if ($entry-priority) 
        then $entry-priority
        else "zzz"
};

declare function jdic:create-session() as empty()
{
    if (request:exists())
        then session:create()
        else ()
};

declare function jdic:set-attribute($name as xs:string, $value as item()*)
    as empty()
{
    if (session:exists())
        then session:set-attribute($name, $value)
        else ()
};