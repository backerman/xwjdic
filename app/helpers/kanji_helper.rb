# Helper methods defined here can be accessed in any controller or view in the application

Xwjdic.helpers do

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
    nanori.each do |n|
      readings.push({:reading => highlight_matches(n), :type => "nanori"})
    end
    res[:readings] = readings
    
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