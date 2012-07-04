require 'rubygems'
require 'net/http'
require 'ipaddress'
require 'json'
require 'hpricot'


class String
    def is_i?
      !!(self =~ /^[-+]?[0-9]+$/)
    end
end


def get_location ip_address
   url = URI.parse("http://www.freegeoip.net/xml/" + ip_address)
   req = Net::HTTP::Get.new(url.path)
   res = Net::HTTP.start(url.host, url.port) {|http| http.request(req)}
end


def get_ips
   args = []
   if ARGV.size < 1
       puts "No arguments supplied. What do you expect me to do?"
   else
       ARGV.each_with_index do |x, i|1
           if !x.nil? && IPAddress.valid?(x.to_s) then
                 args << x
           else
               puts "Problem with arg["+i.to_s+"]. Not IP address."
           end
       end
   end    

   return args
end

def parse_xml xml
   xml_fields = ["Ip", "CountryCode", "CountryName", "RegionCode", "RegionName", "City", "ZipCode", "Latitude", "Longitude", "MetroCode"]

   doc = Hpricot::XML(xml)
   results = []
   (doc/:Response).each do |response|
       xml_fields.each do |field|
           results << {field, response.at(field).innerHTML}
       end
   end
   return results
end
   


def read_count_file location

   missing_count_file = "WARNING, count file could not be located in " + `pwd` + "/" +  location + "." + "\n"*2
   corrupt_count_file =  "WARNING, count file corrupted. Re-writing count file." + "\n"*2
   generic_warning = "Creating new count file... You may be blocked from using freegeoip if this program makes over 1000 requests an hour. Usually we keep count but something bad happened to the file that kept count.\n"
   contents = []
   if File.exist?(location) then
       contents = File.read(location).split
       if ((contents.size == 2) &&  
           (contents[0].is_i?) && (contents[1].is_i?)) then
           puts "So far #{contents[0]} requests made in the last #{contents[1]} minutes" + "\n"*5    
       else
           puts corrupt_count_file.concat(generic_warning)
           contents = [0, Time.now.to_i]
                   File.open(location, 'w') {|f| f.write("0 0") }
       end
   else
       puts missing_count_file.concat(generic_warning)
       contents = [0, Time.now.to_i]
               File.open(location, 'w') {|f| f.write("0 0") }
   end
   return contents
end


def update_count_file (location, original_count, number_of_queries, start_time)
   current_time = Time.now.to_i
       if File.exist?(location) then
               if (current_time-start_time > 60*60) then
                       start_time = current_time
                       count = number_of_queries
               end
               File.open(location, 'w') {|f| f.write((original_count.to_i+number_of_queries.to_i).to_s + " " + start_time.to_s) }
       puts "#{original_count.to_s} queries in the last #{((current_time-start_time)/60).to_s} minutes"
       else
               puts "WARNING: Couldn't find count file: EXITING(-1)"
               exit(-1)
       end
end


if __FILE__ == $0
   location = "COUNT.txt"
   count, time = 0
   max_count = 999
   original_count, time = read_count_file location
   ips = get_ips
   results = []
   if ((Integer(original_count)+ips.size) > 999) then
       original_count = Integer(original_count)
       max_count = 999-original_count
       ips = ips[0..max_count]
       puts "WARNING. Approaching limit, only " + (max_count+1).to_s + " IPs will be queried"
   end
   ips.each_with_index do |x, i|
       results[i] = parse_xml(get_location(x).body)
       puts "Result #{i+1}\n\n"
       results[i].each{|field| puts "#{field.keys} : #{field.values}\n"}
       (1..5).each{|x|if x==4 then puts "="*10 else puts "\n" end}
   end
   update_count_file(location, original_count, ips.size, time.to_i)
end