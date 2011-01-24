(: Return available language codes from the kanji dictionary.
   Since English is implied, we add it here. :)

let $langs := distinct-values(/kanjidic2//meaning/@m_lang | <lang>en</lang>)
return <languages>
{ for $lang in $langs 
  return <language>
            <code>{$lang}</code>
            {/language-codes/language[code[@std="iso-639-1"]=$lang]/name}
         </language>
}
</languages>