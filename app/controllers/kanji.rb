Xwjdic.controllers :kanji do

  KANJIDIC_SEARCH = "kanji-query.xq"
  KANJIDIC_SESSION_QUERY   = :kanjidic_query
  KANJIDIC_SESSION_ID      = :kanjidic_query_session
  
  [{:sym => :text, :path => '/text/:query'},
    {:sym => :textat, :path => '/text/:query/at/:start'}, 
    {:sym => :textatby, :path => '/text/:query/at/:start/by/:howmany'}
    ].each do |mapping|
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
      if session.has_key?(KANJIDIC_SESSION_ID)
        if session[KANJIDIC_SESSION_QUERY] == query
          db_query[:_session] = session[KANJIDIC_SESSION_ID]
        else
          # FIXME: Expire that session
        end
      end
      query_response = grab_xml(KANJIDIC_SEARCH, db_query)
      xml = query_response[:xml]
      session_id = query_response[:session_id]
      results = parse_kanjidic_results(xml)
      session[KANJIDIC_SESSION_ID] = session_id
      session[KANJIDIC_SESSION_QUERY] = query
      totalhits_elem = xml.find_first("/results/totalHits")
      if totalhits_elem
        total_hits = totalhits_elem.content.to_i
      else
        total_hits = 0
      end
      locals =
        {:results => results,
         :query => query,
         :detail_url => "/kanji/detail/",
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
          "/kanji/text/#{query}/at/#{start + howmany}/by/#{howmany}"
      end
      if start > 1
        locals[:paging][:prev_url] = 
          "/kanji/text/#{query}/at/#{[start - howmany, 1].max}/by/#{howmany}"
      end
      render "kanji/kanji_results", :locals => locals
    end
  end
  
  get '/detail/:character' do
    query_response = grab_xml(KANJIDIC_SEARCH, :literal => params[:character])
    xml = query_response[:xml]
    literal = xml.find_first("//literal")
    locals = {:xml => xml.find_first("character").to_s,
              :character => literal.content}
    render "kanji/kanji_detail", :locals => locals
  end
  
  get :search do
    # FIXME need to figure out how to use url command
    # successfully.
    redirect "/kanji/text/#{params[:query]}"
  end
  
    
end