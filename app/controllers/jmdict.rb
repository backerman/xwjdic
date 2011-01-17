require "net/http"
require "uri"
require "cgi"
require "rexml/document"
require "rexml/formatters/pretty"
require "compass"
require "json"

Xwjdic.controllers :jmdict do
  
  JMDICT_SEARCH = "jmdict-entry.xq"
  JMDICT_AUTOCOMPLETE = "autocomplete.xq"
  JMDICT_SESSION_QUERY = :jmdict_query
  JMDICT_SESSION_ID    = :jmdict_query_session
  
  get :index do
    render 'jmdict/index'
  end
  
  [{:sym => :text, :path => '/text/:query'},
    {:sym => :textat, :path => '/text/:query/at/:start'}, 
    {:sym => :textatby, :path => '/text/:query/at/:start/by/:howmany'}
    ].each do |mapping|
    # get mapping[:sym], :map => mapping[:path] do
    get mapping[:path] do
      query = params[:query]
      if params[:start]
        start = params[:start].to_i
      else
        start = 1
      end
      if params[:howmany]
        howmany = params[:howmany].to_i
      else
        howmany = 10
      end
      db_query = {
        :query => query,
        :_start => start,
        :_howmany => howmany
      }
      if session.has_key?(JMDICT_SESSION_QUERY)
        if session[JMDICT_SESSION_QUERY] == query
          db_query[:_session] = session[JMDICT_SESSION_ID]
        else
          # FIXME: Expire that session
        end
      end
      query_response = grab_xml(JMDICT_SEARCH, db_query)
      xml = query_response[:xml]
      session_id = query_response[:session_id]
      error = query_response[:error]
      results = parse_jmdict_results(xml)
      session[JMDICT_SESSION_ID] = session_id
      session[JMDICT_SESSION_QUERY] = query
      totalhits_elem = xml.find_first("/results/totalHits")
      if totalhits_elem
        total_hits = totalhits_elem.content.to_i
      else
        total_hits = 0
      end
      locals =
        {:results => results,
         :query => query,
         :error => error,
         :detail_url => "/jmdict/detail/",
         :paging => {
           :start_num => start,
           :end_num => [start + howmany - 1, total_hits].min,
           :total_hits => total_hits,
           :next_url => false,
           :prev_url => false
          }
         }
      if start + howmany <= total_hits
        locals[:paging][:next_url] =
          "/jmdict/text/#{query}/at/#{start + howmany}/by/#{howmany}"
      end
      if start > 1
        locals[:paging][:prev_url] = 
          "/jmdict/text/#{query}/at/#{[start - howmany, 1].max}/by/#{howmany}"
      end
      if error
        if production?
          locals[:error_message] = <<ERR
Your search has generated an error.  If you used a wildcard, please ensure that
your search was not excessively broad (e.g. just *).  This error has been logged.
ERR
        else
          locals[:error_message] = query_response[:status_message]
        end
      end
         
      render "jmdict/jmdict_results", :locals => locals
    end
  end
  
  get '/detail/:ent_seq' do
    query_response = grab_xml(JMDICT_SEARCH, :"entry-id" => params[:ent_seq])
    xml = query_response[:xml]
    headword_elem = xml.find_first("//k_ele/keb")
    headword_elem = xml.find_first("//r_ele/reb") if ! headword_elem
    headword = if headword_elem
                  then
                    headword_elem.content
                  else
                    ""
                  end
    formatted_xml = xml.find_first("//entry").to_s
    locals = {:xml => formatted_xml,
              :headword => headword}
    render "jmdict/jmdict_detail", :locals => locals
  end
  
  get :search do
    # FIXME need to figure out how to use url command
    # successfully.
    redirect "/jmdict/text/#{params[:query]}"
  end
  
  get :autocomplete, :provides => [:json] do
    query_response = grab_xml(JMDICT_AUTOCOMPLETE, :query => params[:term])
    xml = query_response[:xml]
    res = Array.new
    entries = xml.find("//entry")
    entries.each do |entry|
      gloss = just_text(entry.find_first("gloss"))
      res.push({
        :id => entry.find_first("ent_seq").content,
        :value => if gloss.include? " "
                  then
                    '"' + gloss + '"'
                  else 
                    gloss
                  end,
        :label => gloss
      })
    end
    
    res_deduped = Array.new
    res.each do |r|
        if ! res_deduped.detect {|x| x[:label] == r[:label] }
          res_deduped.push r
        end
    end
    
    res_deduped.to_json
  end
  
end