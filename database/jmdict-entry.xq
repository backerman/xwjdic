import module namespace jdic="http://facefault.org/xquery/jdic"
    at "xmldb:exist:///db/jdic/jdic.xqm";
import module namespace session="http://exist-db.org/xquery/session";

declare function local:get-matches() as element()*
{
    session:create(),
    let $saved-matches := session:get-attribute("matches")
    return
        if ($saved-matches)
            then $saved-matches
            else local:query-matches-and-save()
};

declare function local:query-matches-and-save() as element()*
{
    let $entry-id := request:get-parameter("entry-id", "", false())
    let $search-term := request:get-parameter("query", "fool", false())
    let $matches :=
        for $entry in 
            if ($entry-id) 
                then //entry[ent_seq = $entry-id]
                else if ($search-term) 
                        then //entry[ft:query(., $search-term)]
                        else ()
        order by $entry/k_ele[1]/ke_pri[starts-with(text(), 'nf')] empty greatest
        return $entry
    let $saveme := session:set-attribute("matches", $matches)
    return $matches
};

let $start := xs:integer(request:get-parameter("_start", "1", false()))
let $how-many := xs:integer(request:get-parameter("_howmany", "10", false()))
let $matches := local:get-matches()

return <results>
<totalHits>{ count($matches) }</totalHits>
{util:expand(subsequence($matches, $start, $how-many), "expand-xincludes=no")} 
</results>
