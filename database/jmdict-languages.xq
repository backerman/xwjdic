(: Return available language codes for the JMdict database. :)

let $langs := distinct-values(/JMdict//gloss/@xml:lang)
return <languages>
    {for $lang in $langs
     return <language>
        <code>{$lang}</code>
        {/language-codes/language[code[@std="iso-639-2"]=$lang]/name}
     </language>}
</languages>