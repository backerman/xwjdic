# Helper methods defined here can be accessed in any controller or view in the application

Xwjdic.helpers do
  IDEOGRAPHIC_SPACE = "&#x3000;" # HTML entity

  # Parse one <character> element.
  def parse_kanjidic_entry(e)
    res = {}
    res[:kanji] = highlight_matches e.find_first("literal")
    res[:kanji_text] = just_text res[:kanji]
    # FIXME associate readings w meanings within rmgroup
    readings = []
    reading_elems = e.find(".//reading")
    reading_elems.each do |r|
      reading = highlight_matches r
      type    = r.attributes["r_type"]
      readings.push({:reading => reading, :type => type})
    end
    nanori = e.find(".//nanori")
    nanori_txt = []
    nanori.each do |n|
      this_reading = highlight_matches(n)
      readings.push({:reading => this_reading, :type => "nanori"})
      nanori_txt.push(this_reading)
    end
    res[:readings] = readings
    
    # Post-processing readings for the view
    res[:japanese] = readings.select {|x| x[:type] =~ /^ja_/}.\
      map {|x| x[:reading] }.join(IDEOGRAPHIC_SPACE)
    if ! nanori_txt.empty?
      res[:nanori] = nanori_txt.join(IDEOGRAPHIC_SPACE)
    end
    
    # Senses
    senses = Array.new
    sense_elems = e.find(".//meaning")
    sense_elems.each do |m|
      if (!m.attributes["m_lang"]) or m.attributes["m_lang"] == "en"
        senses.push(highlight_matches m)
      end
    end
    res[:senses] = senses
    
    res
  end

  def parse_kanjidic_results(xml)
    results = Array.new
    chars = xml.find("character")
    chars.each do |e|
      results.push parse_kanjidic_entry(e)
    end
    results
  end
  
end