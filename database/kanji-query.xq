import module namespace jdic="http://facefault.org/xquery/jdic"
    at "xmldb:exist:///db/jdic/jdic.xqm";
import module namespace session="http://exist-db.org/xquery/session";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare function local:get-matches() as element()*
{
    jdic:create-session(),
    let $saved-matches := session:get-attribute("matches")
    return
        if ($saved-matches)
            then $saved-matches
            else local:query-matches-and-save()
};

declare function local:is-match($elem as element(), $langs as xs:string+,
                                $search-term as xs:string) 
    as xs:boolean
{
    let $match-elem := $elem//exist:match[
        contains(jdic:strip-string(.), jdic:strip-string($search-term))]
    return ($match-elem/ancestor::literal or 
            $match-elem/ancestor::codepoint or 
            $match-elem/ancestor::radical or
            $match-elem/ancestor::misc or
            $match-elem/ancestor::dic_number or
            $match-elem/ancestor::query_code or
            $match-elem/ancestor::reading or
            $match-elem/ancestor::nanori or
            local:language-specific-match($match-elem, $langs))   
};

declare function local:language-specific-match($elem as element()*,
                                               $langs as xs:string+)
    as xs:boolean
{
    some $lang in $langs satisfies
        if ($lang = "en")
            then $elem/ancestor-or-self::meaning[empty(@m_lang)]
            else $elem/ancestor-or-self::meaning[@m_lang = $lang]
};

declare function local:query-matches-and-save() as element()*
{
    let $literal := request:get-parameter("literal", "", false())
    let $search-term := request:get-parameter("query", "fo*", false())
    let $lang-str := request:get-parameter("languages", "en", false())
    let $acceptable-languages := jdic:split-language-list($lang-str)
    let $matches :=
        for $entry in 
            if ($literal)
                then //character[literal = $literal]
                else if ($search-term) 
                        then /kanjidic2/ft:query(character, $search-term)
                        else ()
        order by $entry//grade empty greatest
        return $entry
    let $matches2 :=
        if ($literal)
            then $matches
            else for $entry in util:expand($matches, "expand-xincludes=no")
                where local:is-match($entry, $acceptable-languages, $search-term)
                return $entry
    let $saveme := jdic:set-attribute("matches", $matches2)
    return $matches2
};

let $start := xs:integer(request:get-parameter("_start", "1", false()))
let $how-many := xs:integer(request:get-parameter("_howmany", "10", false()))
let $matches := local:get-matches()

return <results>
<totalHits>{ count($matches) }</totalHits>
{subsequence($matches, $start, $how-many)} 
</results>

