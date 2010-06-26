require "net/http"
require "uri"
require "cgi"
require "rexml/document"
require "rexml/formatters/pretty"
require "compass"

Xwjdic.controllers :jmdict do
  
  JMDICT_SEARCH = "jmdict-entry.xq"
  
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
      if session.has_key?(:db_session)
        if session[:saved_query] == query
          db_query[:_session] = session[:db_session]
        else
          # FIXME: Expire that session
        end
      end
      query_response = grab_xml(JMDICT_SEARCH, db_query)
      xml = query_response[:xml]
      session_id = query_response[:session_id]
      results = parse_jmdict_results(xml)
      session[:db_session] = session_id
      session[:saved_query] = query
      total_hits = xml.elements["results/totalHits"].text.to_i
      locals =
        {:results => results,
         :query => params[:query],
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
      # FIXME: Implement those footnote
      # marker thingies to map kanji to kana.
      # FIXME: Kana-only entries shouldn't have () around them.
      render "jmdict/jmdict_results", :locals => locals
    end
  end
  
  get '/detail/:ent_seq' do
    query_response = grab_xml(JMDICT_SEARCH, :"entry-id" => params[:ent_seq])
    xml = query_response[:xml]
    formatter = REXML::Formatters::Pretty.new
    headword = xml.elements["//k_ele/keb"].text
    formatted_xml = ''
    formatter.write(xml.elements["//entry"], formatted_xml)
    locals = {:xml => formatted_xml,
              :headword => headword}
    render "jmdict/jmdict_detail", :locals => locals
  end
  
  get :search do
    # FIXME need to figure out how to use url command
    # successfully.
    redirect "/jmdict/text/#{params[:query]}"
  end
  
end