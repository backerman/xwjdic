(: Return available language codes. :)

let $langs := distinct-values(/JMdict//gloss/@xml:lang)
return <languages>
    {for $lang in $langs
     return <language>{$lang}</language>}
</languages>