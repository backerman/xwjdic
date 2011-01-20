# Helper methods defined here can be accessed in any controller or view in the application

require "cookiejar"
require "libxml"
require "typhoeus"

Xwjdic.helpers do
  
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
    xml.to_s.gsub(/<\/?[^>]+>/, "").strip
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
      re_restrs = r.find("./re_restr")
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
      senses.push gloss_text.join("; ") unless gloss_text.empty?
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
    my_url = options.db_url + xquery
    logger.debug "Querying #{my_url} with parms #{params.inspect}"
    response = Typhoeus::Request.get(my_url,
                                    :params => params)
    retval = {
      :code => response.code,
      :status_message => response.status_message
    }
    logger.debug "Returned; #{retval.inspect}"
    if response.code == 200
      # Successful query.
      retval[:error] = false
      retval[:xml]= LibXML::XML::Document.string(response.body)
    elsif response.code >= 400 && response.code < 600
      # Fail.  Possibly the user tried a stupid search
      # e.g. "a*"
      retval[:error] = true
      # Put in a dummy XML body.
      dummy_body = <<EOF
<entry>
</entry>
EOF
      retval[:xml] = LibXML::XML::Document.string(dummy_body)
    end

    # Get the session ID to keep with data --
    # this allows database-side paging to work.
    if params[:_session]
      new_session = params[:_session]
    else
      rhh_sc = response.headers_hash["Set-Cookie"]
      if rhh_sc && rhh_sc.is_a?(String)
          cookie = CookieJar::Cookie.from_set_cookie(my_url, rhh_sc)
          new_session = cookie.value
      else
        new_session = nil
      end
    end
    
    if new_session
      logger.debug "Session ID is now #{new_session.inspect}."
      retval[:session_id] = new_session
    end
    
    retval
  end
  
end