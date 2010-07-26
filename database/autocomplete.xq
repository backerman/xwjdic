import module namespace jdic="http://facefault.org/xquery/jdic"
    at "xmldb:exist:///db/jdic/jdic.xqm";

declare function local:language-specific-match($elem as element()+,
                                               $langs as xs:string+)
    as xs:boolean
{
    some $lang in $langs satisfies
        if ($lang = "eng")
            then $elem//exist:match/ancestor::gloss[empty(@xml:lang) or @xml:lang="eng"]
            else $elem//exist:match/ancestor::gloss[@xml:lang = $lang]
};

let $search-term := jdic:param("query", "cart")
let $lang-str := request:get-parameter("languages", "eng", false())
let $acceptable-languages := jdic:split-language-list($lang-str)
let $search := concat($search-term, "*")
let $all-hits := //gloss[ft:query(., $search)]/ancestor::entry
let $my-lang-hits := 
    for $hit in util:expand($all-hits, "expand-xincludes=no")
    where local:language-specific-match($hit, $acceptable-languages)
    return $hit
let $ordered-hits := 
    for $hit in $my-lang-hits
    order by $hit//ke_pri[starts-with(text(), "nf")] empty greatest
    return $hit
for $entry in subsequence($ordered-hits, 1, 10)
return <entry>
{$entry/ent_seq}
{$entry//gloss[exist:match and local:language-specific-match(., $acceptable-languages)]}
</entry>