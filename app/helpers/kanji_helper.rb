# Helper methods defined here can be accessed in any controller or view in the application

Xwjdic.helpers do
  IDEOGRAPHIC_SPACE = "&#x3000;" # HTML entity
  
  # Lookup between dictionary codes in XML and display code/name
  DICTIONARY_CODE = {
    "nelson_c" => {
      :code => "N",
      :name => "Modern Reader's Japanese-English Character Dictionary " + 
                "(Classic Nelson)"
    },
    "nelson_n" => {
      :code => "V",
      :name => "The New Nelson Japanese-English Character Dictionary"
    },
    "halpern_njecd" => {
      :code => "H",
      :name => "New Japanese-English Character Dictionary (Halpern)"
    },
    "halpern_kkld" => {
      :code => "DK",
      :name => "Kanji Learners Dictionary (Halpern)"
    },
    "heisig" => {
      :code => "L",
      :name => "Remembering The Kanji (Heisig)"
    },
    "gakken" => {
      :code => "K",
      :name => "A New Dictionary of Kanji Usage (Gakken)"
    },
    "oneill_names" => {
      :code => "O",
      :name => "Japanese Names (O'Neill)"
    },
    "oneill_kk" => {
      :code => "DO",
      :name => "Essential Kanji (O'Neill)"
    },
    "moro" => {
      # FIXME This one also has the MP element to do
      :code => "MN",
      :name => "Daikanwajiten (Morohashi)"
    },
    "henshall" => {
      :code => "E",
      :name => "A Guide To Remembering Japanese Characters (Henshall)"
    },
    "sh_kk" => {
      :code => "IN",
      :name => "Kanji & Kana (Spahn and Hadamitzky)"
    },
    "sakade" => {
      :code => "DS",
      :name => "A Guide To Reading and Writing Japanese (Sakade)"
    },
    "henshall3" => {
      :code => "DH",
      :name => "A Guide To Reading and Writing Japanese 3ed (Henshall)"
    },
    "tutt_cards" => {
      :code => "DT",
      :name => "Tuttle Kanji Cards (Kask)"
    },
    "crowley" => {
      :code => "DC",
      :name => "The Kanji Way to Japanese Language Power (Crowley)"
    },
    "kanji_in_context" => {
      :code => "DJ",
      :name => "Kanji in Context (Nishiguchi and Kono)"
    },
    "busy_people" => {
      :code => "DB",
      :name => "Japanese For Busy People (AJLT)"
    },
    "kodansha_compact" => {
      :code => "DG",
      :name => "Kodansha Compact Kanji Guide"
    },
    "jf_cards" => {
      :code => "DF",
      :name => "Japanese Kanji Flashcards (Hodges and Okazaki, White Rabbit Press)"
    },
    "maniette" => {
      :code => "DM",
      :name => "Les Kanjis dans la tête (Maniette)"
    }
  }

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
    nanori_txt = Array.new
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
    
    # Code points
    codepoints = Array.new
    cp_elems = e.find("./codepoint/cp_value")
    unicode_val = nil
    cp_elems.each do |cp|
      this_cp = Hash.new
      this_cp[:type] = cp.attributes["cp_type"]
      this_cp[:value] = highlight_matches(cp)
      if this_cp[:type] == "ucs"
        unicode_val = this_cp[:value]
      end
      codepoints.push(this_cp)
    end
    res[:codepoints] = codepoints
    res[:unicode_hex] = unicode_val
    
    # Dictionary references
    dic_refs = Array.new
    dic_elems = e.find("./dic_number/dic_ref")
    dic_elems.each do |elem|
      dic_lookup = DICTIONARY_CODE[elem.attributes["dr_type"]]
      if dic_lookup
        this_dic = dic_lookup.dup
        this_dic[:index] = highlight_matches(elem)
        dic_refs.push(this_dic)
      else
        logger.debug "Warning: Dictionary code lookup failed for " +
          "#{elem.attributes["dr_type"].inspect}"
      end
    end
    res[:dic_refs] = dic_refs
    
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