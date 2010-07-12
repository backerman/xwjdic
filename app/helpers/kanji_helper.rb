# Helper methods defined here can be accessed in any controller or view in the application

Xwjdic.helpers do

  # Parse one <character> element.
  def parse_kanjidic_entry(e)
    def matches(elem)
      highlight_matches(elem, @formatter)
    end
    
    res = {}
    res[:kanji] = matches e.elements["literal"]
    # FIXME associate readings w meanings within rmgroup
    readings = []
    e.elements.each("//reading") do |r|
      reading = matches r
      type    = r.attributes["r_type"]
      readings.push({:reading => reading, :type => type})
    end
    res[:readings] = readings

    # Senses
    senses = Array.new
    e.elements.each("//meaning") do |m|
      if (!m.attributes["m_lang"]) or m.attributes["m_lang"] == "en"
        senses.push matches m
      end
    end
    res[:senses] = senses
    
    res
  end

  def parse_kanjidic_results(xml)
    @formatter = REXML::Formatters::Default.new
    out = ''
    @formatter.write(xml,out)
    puts "Got results: #{out}"
    results = Array.new
    xml.elements.each("//character") do |e|
      results.push parse_kanjidic_entry(e)
    end
    results
  end
  
end