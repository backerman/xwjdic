import module namespace jdic="http://facefault.org/xquery/jdic"
    at "xmldb:exist:///db/jdic/jdic.xqm";
import module namespace session="http://exist-db.org/xquery/session";

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
    return ($match-elem/ancestor::ent_seq or 
            $match-elem/ancestor::k_ele or 
            $match-elem/ancestor::r_ele or
            $match-elem/ancestor::info or
            local:language-specific-match($match-elem, $langs) or
            $match-elem/ancestor::xref or
            $match-elem/ancestor::misc or
            $match-elem/ancestor::info)
};

declare function local:language-specific-match($elem as element()*,
                                               $langs as xs:string+)
    as xs:boolean
{
    some $lang in $langs satisfies
        if ($lang = "eng")
            then $elem/ancestor::gloss[empty(@xml:lang) or @xml:lang="eng"]
            else $elem/ancestor::gloss[@xml:lang = $lang]
};

declare function local:query-matches-and-save() as element()*
{
    let $entry-id := request:get-parameter("entry-id", "", false())
    let $search-term := request:get-parameter("query", "gift", false())
    let $lang-str := request:get-parameter("languages", "eng", false())
    let $acceptable-languages := jdic:split-language-list($lang-str)
    let $matches :=
        for $entry in 
            if ($entry-id) 
                then //entry[ent_seq = $entry-id]
                else if ($search-term) 
                        then /JMdict/ft:query(entry, $search-term)
                        else ()
        order by $entry/k_ele[1]/ke_pri[starts-with(text(), 'nf')][1] empty greatest
        return $entry
    let $matches2 :=
        if ($entry-id)
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
