# Helper methods defined here can be accessed in any controller or view in the application

require "cookiejar"
require "libxml"

Xwjdic.helpers do
  
  DB_URL = "http://localhost:8080/exist/rest/db/jdic/"
  
  def highlight_matches(gloss)
    matches = gloss.find("exist:match", 
      "exist:http://exist.sourceforge.net/NS/exist")
    matches.each do |m|
      match_el = LibXML::XML::Node.new("span")
      match_el.attributes["class"] = "search_term"
      match_el.content = m.content
      # Replace m with match_el
      m.next = match_el
      m.remove!
    end
    gloss.inner_xml.strip
  end
  
  # Just return the text in an XML fragment -- remove all tags and
  # attributes.
  def just_text(xml)
    xml.to_s.gsub(/<\/?[^>]+>/, "")
  end

  # Parse one <entry> element.
  def parse_jmdict_entry(e)
    res = {}
    kanji = []
    kebs = e.find("k_ele/keb")
    kebs.each do |k|
      kanji.push({:kanji => highlight_matches(k),
                  :unique_readings => [],
                  :ktext => just_text(k)})
    end
    res[:kanji] = kanji
    res[:char_literal] = kanji[0]
    res[:ent_seq] = e.find_first("ent_seq").content
    readings = []
    r_eles = e.find("r_ele")
    r_eles.each do |r|
      reading = highlight_matches(r.find_first("reb"))
      restr = []
      re_restrs = e.find("re_restr")
      re_restrs.each do |restriction|
        applicable_kanji = just_text restriction
        restr.push applicable_kanji
        kanji.each do |k|
          if k[:ktext] == applicable_kanji
            k[:unique_readings].push reading
          end
        end
      end
      readings.push({:kana => reading, :restrictions => restr})
    end
    # Assign footnote numbers to each k_ele w/ special readings
    current_num = 0
    kanji.each do |k|
      if not k[:unique_readings].empty?
        current_num += 1
        k[:footnote_number] = current_num
      end
    end
    res[:readings] = readings

    # Senses
    senses = Array.new
    sense_elems = e.find("sense")
    sense_elems.each do |s|
      gloss_text = Array.new
      glosses = s.find("gloss")
      glosses.each do |g|
        if g.attributes["lang"] == "eng"
          gloss_text.push highlight_matches(g)
        end
      end
      senses.push gloss_text.join("; ")
    end
    res[:senses] = senses
    res
  end

  def parse_jmdict_results(xml)
    results = Array.new
    entries = xml.find("entry")
    entries.each do |e|
      results.push(parse_jmdict_entry(e))
    end
    # puts results.inspect
    results
  end
  
  def grab_xml(xquery, params)
    escaped_params = params.map { |name, value| \
      name.to_s + "=" + CGI.escape(value.to_s) }
    my_url = DB_URL + xquery + "?" + escaped_params.join('&')
    # puts "Querying: #{my_url}"
    uri = URI.parse(my_url)
    request = Net::HTTP::Get.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 3 # in seconds
    http.read_timeout = 3 # in seconds
    res = http.request(request)
    if params[:_session]
      new_session = params[:_session]
    else
      cookie = CookieJar::Cookie.from_set_cookie(
        my_url, res["Set-Cookie"])
      new_session = cookie.value
    end
    # FIXME: Assumes there's only one cookie.
    { :xml => LibXML::XML::Document.string(res.body),
      :session_id => new_session }
  end
  
end