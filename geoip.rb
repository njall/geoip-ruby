require 'rubygems'
require 'net/http'
require 'ipaddress'
require 'json'
require 'hpricot'




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
		ARGV.each_with_index do |x, i|
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
	xml_fields = ["Ip", "CountryCode", "CountryName", "RegionCode", "RegionName", "City", "ZipCode", 			      "Latitude", "Longitude", "MetroCode"]

	doc = Hpricot::XML(xml)
	results = []
	(doc/:Response).each do |response|
		xml_fields.each do |field| 
			results << {field, response.at(field).innerHTML}
		end
	end
	return results
end
	
def read_count_file

__COUNT_LOCATION__ = "/home/server/Documents/COUNT.txt"
missing_count_file = "WARNING, count file could not be located in " + __COUNT_LOCATION__ +
corrupt_count_file =  "WARNING, count file corrupted. Re-writing count file"
generic_warning = ". Creating new count file... You may be blocked from using freegeoip if this program makes over 1000 requests an hour. Usually we keep count but something bad happened to the file that kept count."

	contents = []
	if File.exist?(__COUNT_LOCATION__) then
		contents = File.read(__COUNT_LOCATION__).split
		if ((contents.size == 2) || 
		    (contents[0].numeric?) || (contents[1].numeric?)) then
		puts "So far #{contents[0]} requests made in the last #{contents[1]} minutes" + "\n"*5	
		else
			puts corrupt_count_file.concat(generic_warning)
			contents = [0,0]
		end
	else
		puts missing_count_file.concat(generic_warning)
		contents = [0,0]
	end
	return contents
end

def numeric?
    Float(self) != nil rescue false
end 




if __FILE__ == $0
	
	count, time = read_count_file
	count = (Integer)count

	ips = get_ips
	results = []
	if (count.numeric? && ((count+ips.size) > 999))
		ips = ips[0..999-count]
		puts "WARNING. Approaching limit, only the first " + (999-count).to_s + "IPs will be queried"
	end
	ips.each_with_index do |x, i|
		results[i] = parse_xml(get_location(x).body)
		puts "Result #{i+1}\n\n"
		results[i].each{|field| puts "#{field.keys} : #{field.values}\n"}
		(1..5).each{|x|if x==4 then puts "="*10 else puts "\n" end} 
	end
end

def update_count_file
	File.exist?("/home/server/Documents/COUNT.txt")

end




