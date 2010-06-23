import module namespace jdic="http://facefault.org/xquery/jdic"
    at "xmldb:exist:///db/jdic/jdic.xqm";

let $search-term := jdic:param("query", "cart")
let $search := concat($search-term, "*")
let $all-hits := //gloss[ft:query(., $search)]
let $my-lang-hits := $all-hits[@xml:lang="eng"]
let $ordered-hits := 
    for $hit in $my-lang-hits/ancestor::entry
    order by $hit//ke_pri[starts-with(text(), "nf")] empty greatest
    return $hit
for $entry in util:expand(subsequence($ordered-hits, 1, 10), "expand-xincludes=no")
return <entry>
{$entry/ent_seq}
{$entry//gloss[exist:match and @xml:lang="eng"]}
</entry>