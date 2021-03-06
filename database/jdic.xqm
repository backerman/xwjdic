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

(: Parse a list of acceptable language codes.
   e.g. "eng, deu, esp" returns ("eng", "deu", "esp") :)
declare function jdic:split-language-list($codes as xs:string) as xs:string*
{
    tokenize($codes, ",")
};

(: Wrapper functions for eXist session library -- check first to see if
   we're being called from an HTTP request, and if not, don't try to 
   do things that will fail. :)

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

(: Remove wildcards and punctuation from a string. :)
declare function jdic:strip-string($str as xs:string) as xs:string
{
  let $strip-regex := jdic:strip-regex()
  let $no-stops :=    replace($str, $strip-regex, "")
  return replace($no-stops, "[\p{P}\p{Z}]+", "")
};

(: Regex matching any of the stop words used by Lucene :)
declare function jdic:strip-regex() as xs:string
{
  concat("\W(a|an|and|are|as|at|be|but|by|for|if|in|into|is|it|no|not|",
         "of|on|or|such|that|the|their|then|there|these|they|this|to|was|",
         "will|with)\W")
};
