module FuncList

  @@func_regex = /\s*(\w+)\s*:\s*\(\s*\w*\s*\s*\w+\s*\*?\s*\)\s*\w+\s*/
  @@func_simple_regex = /\s*[-\+]\s*\(\s*\w+\s*\*?\)\s*(\w+)\s*;*/
  @@hcls_regex = /@interface\s+(\w+)\s*/
  @@mcls_regex = /@implementation\s+(\w+)\s*/
  @@property_regex = /\s*@property\s*\(.*?\)\s*\w+\s*\*?\s*(\w+)\s*;/

  def self.to_utf8(str)
    str = str.force_encoding('UTF-8')
    return str if str.valid_encoding?
    str.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '')
  end

  def self.capture(content_str,type = "m") 
    results = []
    str = to_utf8 content_str
    str.scan @@func_regex do |curr_match|
      md = Regexp.last_match
      whole_match = md[0]
      captures = md.captures

      captures.each do |capture|
        results << "f:#{capture}"
        #p [whole_match, capture]
        p "f:[#{capture}]"
      end
    end
    #no arguments function
    str.scan @@func_simple_regex do |curr_match|
      md = Regexp.last_match
      whole_match = md[0]
      captures = md.captures

      captures.each do |capture|
        results << "f:#{capture}"
        #p [whole_match, capture]
        p "f:[#{capture}]"
      end
    end
    cls_regex = ""
    if type == "h"
      cls_regex = @@hcls_regex
    else
      cls_regex = @@mcls_regex
    end
    str.scan cls_regex do |curr_match|
      md = Regexp.last_match
      whole_match = md[0]
      captures = md.captures

      captures.each do |capture|
        results << "c:#{capture}"
        #p [whole_match, capture]
        p "c:[#{capture}]"
      end
    end
    str.scan @@property_regex do |curr_match|
      md = Regexp.last_match
      whole_match = md[0]
      captures = md.captures

      captures.each do |capture|
        results << "p:#{capture}"
        #p [whole_match, capture]
        p "p:[#{capture}]"
      end
    end
   
    results
  end

  def self.genFuncList(path,type = "m")
    capture_methods = []
    p_methods = []
    funclist_path = "#{path}/func.list"  
    file = File.open(funclist_path, "w")
    file_pathes = []
    if type == "h" || type == "m"
      file_pathes = `find #{path} -name "*.#{type}" -d`.split "\n"
    elsif type == "all"
      file_pathes += `find #{path} -name "*.h" -d`.split "\n"
      file_pathes += `find #{path} -name "*.m" -d`.split "\n"
    end
    file_pathes.each do |file_path|
      content = File.read file_path
      captures = capture content , type 
      captures.each do |capture_method| 
        method_type = capture_method.split(":").first
        method_content = capture_method.split(":").last
        if !method_content.start_with? "init" 
          if method_type == "c" || method_type == "f"
            if !capture_methods.include? capture_method 
              capture_methods << capture_method 
            end
          elsif method_type == "p"
            if !p_methods.include? capture_method 
              p_methods << capture_method 
            end
          end
        end
      end
    end
    
    p_methods.each do |capture_method|
      method_type = capture_method.split(":").first
      method_content = capture_method.split(":").last
      c_method = "c:#{method_content}"
      f_method = "f:#{method_content}"
      if capture_methods.include? c_method
        capture_methods.delete c_method
      end
      if capture_methods.include? f_method
        capture_methods.delete f_method
      end
    end

    capture_methods += p_methods

    if capture_methods.length > 0 
      file.write(capture_methods.join "\n") 
    end
    file.close
    funclist_path
  end
  
end

