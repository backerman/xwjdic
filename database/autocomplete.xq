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

let $search-term := jdic:param("query", "fr")
let $filter-regex := concat("^(.*\W)?", $search-term)
let $lang-str := request:get-parameter("languages", "eng", false())
let $acceptable-languages := jdic:split-language-list($lang-str)
let $gloss-hits := //gloss[ngram:contains(., $search-term) 
                         and matches(., $filter-regex)]/ancestor::entry
let $my-lang-gloss-hits :=
    for $hit in util:expand($gloss-hits, "expand-xincludes=no")
    where local:language-specific-match($hit, $acceptable-languages)
    return $hit
let $keb-hits := //keb[ngram:contains(., $search-term)]/ancestor::entry
let $reb-hits := //reb[ngram:starts-with(., $search-term)]/ancestor::entry
let $ordered-hits := 
    for $hit in $my-lang-gloss-hits | $keb-hits | $reb-hits
    order by $hit/k_ele[1]/ke_pri[starts-with(text(), 'nf')] empty greatest
    return $hit
let $results :=
    for $entry in subsequence($ordered-hits, 1, 10)
        return <entry>
        {$entry/ent_seq}
        {$entry//gloss[exist:match and 
            local:language-specific-match(., $acceptable-languages)]}
        </entry>
return <autocomplete-results>
            {$results}
       </autocomplete-results>