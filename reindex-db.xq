import module namespace xmldb="http://exist-db.org/xquery/xmldb";

let $reindex := xmldb:reindex('/db/${collection.name}')
return <status>Reindexed.</status>
