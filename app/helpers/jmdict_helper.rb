# Helper methods defined here can be accessed in any controller or view in the application

require "cookiejar"
require "rexml/element"
require "rexml/formatters/default"

Xwjdic.helpers do
  
  DB_URL = "http://localhost:8080/exist/rest/db/jdic/"
  
  def highlight_matches(gloss, formatter)
    gloss.elements.each("exist:match") do |m|
      match_el = REXML::Element.new("span")
      match_el.attributes["class"] = "search_term"
      match_el.text = m.text
      m.replace_with(match_el)
    end
    out = ''
    gloss.each_child { |e| formatter.write(e, out) }
    out
  end

  # Parse one <entry> element.
  def parse_jmdict_entry(e, formatter)
    res = {}
    kanji = []
    e.elements.each("k_ele/keb") do |k|
      kanji.push({:kanji => k.text, :unique_readings => []})
    end
    res[:kanji] = kanji
    res[:char_literal] = kanji[0]
    res[:ent_seq] = e.elements["ent_seq"].text
    readings = []
    e.elements.each("r_ele") do |r|
      reading = r.elements["reb"].text
      restr = []
      r.elements.each("re_restr") do |restriction|
        applicable_kanji = restriction.text
        restr.push applicable_kanji
        kanji.each do |k|
          if k[:kanji] == applicable_kanji
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
    e.elements.each("sense") do |s|
      gloss_text = Array.new
      s.elements.each("gloss") do |g|
        if g.attributes["xml:lang"] == "eng"
          gloss_text.push highlight_matches(g, formatter).strip
        end
      end
      senses.push gloss_text.join("; ")
    end
    res[:senses] = senses
    res
  end

  def parse_jmdict_results(xml)
    formatter = REXML::Formatters::Default.new
    results = Array.new
    xml.elements.each("//entry") do |e|
      results.push parse_jmdict_entry(e, formatter)
    end
    results
  end
  
  def grab_xml(xquery, params)
    escaped_params = params.map { |name, value| \
      name.to_s + "=" + CGI.escape(value.to_s) }
    my_url = DB_URL + xquery + "?" + escaped_params.join('&')
    puts "Querying: #{my_url}"
    uri = URI.parse(my_url)
    request = Net::HTTP::Get.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 3 # in seconds
    http.read_timeout = 3 # in seconds
    res = http.request(request)
    # puts "Body: " + res.body
    #puts "Cookie header: " + res["set-cookie"]
    if params[:_session]
      new_session = params[:_session]
    else
      cookie = CookieJar::Cookie.from_set_cookie(
        my_url, res["Set-Cookie"])
      new_session = cookie.value
    end
    # FIXME: Assumes there's only one cookie.
    { :xml => REXML::Document.new(res.body),
      :session_id => new_session }
  end
  
end