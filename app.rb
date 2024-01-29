require "sinatra"
require "sinatra/reloader"
require "sinatra/activerecord"
require "http"
require "json"

#Homepage: includes search bar, word of the day, definitions of WOD
get("/") do

  @rand_word = ["cause",
  "flesh",
  "audience",
  "age",
  "protest",
  "error",
  "hook",
  "Europe",
  "winter",
  "fence",
  "swing",
  "paradox",
  "wire",
  "stock",
  "haircut",
  "liver",
  "enhance",
  "bland",
  "merit",
  "decisive",
  "fly",
  "rear",
  "teacher",
  "inn",
  "reader",
  "civilian",
  "carve",
  "well",
  "labour",
  "cash",
  "low",
  "bird",
  "screw",
  "estimate",
  "visual",
  "tasty",
  "ministry",
  "wedding",
  "use",
  "undress",
  "night",
  "drown",
  "deport",
  "climb",
  "looting",
  "exotic",
  "freeze",
  "sum",
  "dedicate",
  "space"].sample

  #Merriam-Webster API Request: sending the request for data
  mw_apikey = ENV.fetch("MERRIAM_WEBSTER_API")

  raw_responseMW = HTTP.get("https://www.dictionaryapi.com/api/v3/references/collegiate/json/#{@rand_word}?key=#{mw_apikey}")

  data_stringMW = raw_responseMW.to_s
  parsed_respMW = JSON.parse(data_stringMW)

  #Merriam-Webster: digging + access relevant data

  #Pronounciation: determine base form of word for pronounciation
  hom_num = parsed_respMW.dig(0,"hom")

  if hom_num != 1 
    base_form_word = parsed_respMW.dig(0, "meta","stems",0)
    base_raw_response = HTTP.get("https://www.dictionaryapi.com/api/v3/references/collegiate/json/#{base_form_word}?key=#{mw_apikey}")

    base_data_stringMW = base_raw_response.to_s
    base_parsed_respMW = JSON.parse(base_data_stringMW)
  
    @pronounciation = base_parsed_respMW.dig(0, "hwi","prs",0, "mw").gsub("'", "")
  else
    @pronounciation = parsed_respMW.dig(0, "hwi","prs",0, "mw").gsub("'", "")
  end

  #Part of speech:
  @part_of_speech = parsed_respMW.dig(0,"fl") 

  #Definitions 1-3:
  short_def = []

  parsed_respMW.each do |a_hash|
    sd_array = a_hash.fetch("shortdef")
    length = sd_array.length

    if length >= 2
      short_def << sd_array
    end
  end

  @short_def_display = short_def[0]
  
  erb(:homepage)
end

#Results page: 
get("/:word_results") do

  @user_input = params.fetch("search_bar")

  #Merriam-Webster API Request:
  mw_apikey = ENV.fetch("MERRIAM_WEBSTER_API")

  raw_responseMW = HTTP.get("https://www.dictionaryapi.com/api/v3/references/collegiate/json/#@user_input}?key=#{mw_apikey}")


  data_stringMW = raw_responseMW.to_s
  @parsed_respMW = JSON.parse(data_stringMW)

  #Error-handling starts here: viable word vs. misspelled vs. nil

  if @parsed_respMW[0].class == String
    @status = "misspelled word"
  elsif @parsed_respMW.dig(0,"meta","id") == "C + W"
    @status = "invalid word"
  else
    @status = "ok"
  end

  if @status == "invalid word"
    @error_message = "Please enter a valid word above."
  elsif @status == "ok"
    
    #Searched word
    @word_search = @parsed_respMW.dig(0, "meta","id").gsub(/[^a-z]/i, "")
  
    #Word pronounciation
    hom_num = @parsed_respMW.dig(0,"hom")

    if hom_num != 1 
      base_form_word = @parsed_respMW.dig(0, "meta","stems",0)
      base_raw_response = HTTP.get("https://www.dictionaryapi.com/api/v3/references/collegiate/json/#{base_form_word}?key=#{mw_apikey}")

      base_data_stringMW = base_raw_response.to_s
      base_parsed_respMW = JSON.parse(base_data_stringMW)
    
      @pronounciation = base_parsed_respMW.dig(0, "hwi","prs",0, "mw").gsub("'", "")
    else
      @pronounciation = @parsed_respMW.dig(0, "hwi","prs",0, "mw").gsub("'", "")
    end

    #Part of speech
    @part_of_speech = @parsed_respMW.dig(0,"fl") 

    #Definitions 1-3:
    short_def = []

    @parsed_respMW.each do |a_hash|
      sd_array = a_hash.fetch("shortdef")
      length = sd_array.length

      if length >= 1
        short_def << sd_array
      end
    end

    @short_def_display = short_def[0]
  end

  erb(:word_results)
end
