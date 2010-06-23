(: Frequently-used functions :)
module namespace jdic="http://facefault.org/xquery/jdic";
import module namespace request="http://exist-db.org/xquery/request";

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