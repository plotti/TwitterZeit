require 'rubygems'
require 'init'
require 'open-uri'
require 'readability'
require 'sinatra'
require 'digest'
require 'pismo'

# Returns strong ties [[id, strengthth],...] for a given user using the infochimp API
def get_strong_ties_for(username)
	begin 
		result = YAML.load_file("/data/" + username + "_strongties")
	rescue
		puts "Have to get strong ties first"
	end
	if result == nil
		request = Chimps::QueryRequest.new("social/network/tw/graph/strong_links.json", 
										:query_params =>{:screen_name => "plotti"})
		response = request.get
		response.parse!
		result = Hash[response.data["strong_links"]]
		File.open("/data/" + username + "_strongties","w") {|file| file.puts(result.to_yaml)}
		return result
	else
		return result
	end	        
end

def get_friends_for(username)
	friends = []
	cursor = -1 
	counter = 0
	max = MAX_FRIENDS/100
	while cursor != 0 && counter < max
		result = Twitter.friends(username, {:cursor => cursor})
		friends += result[:users]
		cursor = result[:next_cursor]
		puts "Next Cursor for #{username} is #{cursor}"
		counter += 1
	end
	return friends
end

# Computes Indegree Measures for members of the egonetwork of a given user
def get_centralities_for(username)
	#implement a simple 'caching mechanism' to load centralities when we have computed them already
	begin
		result = YAML.load_file("/data/" + username + "_centralities")
	rescue 
		puts "Have to compute centralities first...This might take a while."
	end
	if result == nil
		friends_friends = {}
		friends = get_friends_for(username)
		i = 0
		friends.each do |friend|
			puts "Working #{friend.screen_name}"
			friends_friends[friend.screen_name] = get_friends_for(friend.screen_name).collect{|f| f.id}
		end
		friends.each do |f|
			f[:in_degree] = 0 
			friends_friends.each do |ff|
				if ff[1].include? f.id
					f[:in_degree] += 1
				end
			end	
		end
		result = {}
		friends.each do |friend|
			result[friend[:screen_name]] = friend[:in_degree]
		end
		File.open("/data/" + username + "_centralities","w") {|file| file.puts(result.to_yaml)}
		return result
	else
		return result
	end
end

def get_content_for(tweets)
	tweets.each do |tweet|
		begin
			file = YAML.load_file("/data/" + Digest::SHA1.hexdigest(tweet[:uri]) + "_content")
			tweet[:content] = file[:content]
			tweet[:title] = file[:title]
			tweet[:image] = file[:image]
		rescue
			puts "Have to obtain content for this url first"
		end
		if file == nil
			#text = open(tweet[:uri]).read rescue ""
			#tweet[:content] = Readability::Document.new(text).content(remove_unlikely_candidates=true) rescue ""
	    	#tweet[:title] = Nokogiri::HTML(text).at_css("title").text  rescue ""
		    #tweet[:image] = ""
		    begin 
		    	doc = Pismo::Document.new(tweet[:uri])
		    	tweet[:content] = doc.body
		    	tweet[:title] = doc.title
		    	tweet[:image] = doc.images.first rescue ""
		    	tweet[:icon] = doc.favicon rescue ""
		    rescue
		    	tweet[:content] = tweet[:uri]
		    	tweet[:title] = ""
		    	tweet[:image] = ""
		    	tweet[:icon] = ""
		    end
		    File.open("/data/" + Digest::SHA1.hexdigest(tweet[:uri]) + "_content","w"){|file| file.puts(tweet.to_yaml)}
		end
	end
	return tweets
end

def get_retweets_for(tweets)
	i = 0
	tweets.each do |tweet|
		begin
			tweet[:retweet_ids] = YAML.load_file("/data/" + tweet.id.to_s + "_retweets")
		rescue
		end
		if tweet[:retweet_ids] == nil
			i += 1
			puts "Calculating #{i} of #{tweets.count}"
			tweet[:retweet_ids] = []
			Twitter.retweeters_of(tweet.id, {:count => 100}).each do |retweet|
				tweet[:retweet_ids] << { :id => retweet.id, :person => retweet.screen_name, :published_at => retweet.created_at}
			end
			File.open("/data/" + tweet.id.to_s + "_retweets","w") {|file| file.puts(tweet[:retweet_ids].to_yaml)}
		end
	end
	return tweets
end

def get_links_for(tweets)
	url_regexp = /http:\/\/\w/
	result = []
	tweets.each do |item|
		url = item.text.split.grep(url_regexp)
		if url != []
			item[:uri] = url.first
			result << item
		end
	end
	return result
end

def get_tweets_for(username)
	tweets = Twitter.home_timeline(:count => 500)
end

def get_news_value_for(tweets)
	#News value is only based on recency so far
	tweets.each do |tweet|
		tweet[:news_value] = 1/((Time.now - Time.parse(tweet.created_at))/3600+1)
	end
end

def calculate_newspaper(tweets,strong_ties,centralities)
	 max_retweets = 0
	 max_centrality = 0
	 max_strong = 0
	 #Normalization of Values to 1
     centralities.each do |centrality|
     	if centrality[1] > max_centrality
     		max_centrality = centrality[1]
     	end
     end
     tweets.each do |tweet|
     	if tweet[:retweet_ids].count > max_retweets
     		max_retweets = tweet[:retweet_ids].count
     	end
     end
     strong_ties.each do |tie|
     	if tie[1] > max_strong
     		max_strong = tie[1]
     	end
     end
     tweets.each do |tweet|
        rt_score = (tweet[:retweet_ids].count / max_retweets).to_f
        st_score = (strong_ties[tweet.user.id].to_f/ max_strong)
        ct_score = (centralities[tweet.user.screen_name].to_f / max_centrality)
        nw_score = tweet[:news_value]
		score = rt_score + st_score + ct_score + nw_score
		tweet[:score_string] = "Total Score: #{score} RT: #{rt_score} ST: #{st_score} CT: #{ct_score} NW: #{nw_score}"
		tweet[:score] = score
     end
     return tweets
end

get '/show/:username' do |username|
	@username = username
	puts "Calculating strongies"
	strong_ties = get_strong_ties_for(username)
	puts "Calculating Centralities"
	centralities = get_centralities_for(username)
	puts "Getting tweets"
	result = get_tweets_for(username)
	puts "Filtering only to tweets with links"
	result = get_links_for(result)
	puts "Getting retweets for tweets"
	result = get_retweets_for(result)
	puts "Getting news value for tweets"
	result = get_news_value_for(result)
	puts "Calculating newspaper"
	result = calculate_newspaper(result,strong_ties,centralities)
	puts "Getting content for best 20 items"
	result = result.sort!{|a,b| a[:score] <=> b[:score]}.reverse[0..20]
	@news = get_content_for(result)
	haml :show
end

__END__
@@layout
%html
  <?xml version="1.0" encoding="UTF-8"?>
  %header
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  %title="The #{@username} Times"
  %body
    %h1="The #{@username} Times"
    %content=yield


@@ show
- @news.each do |item|
  %p
    %h1
      -if item[:icon] != ""
        %img{:src => item[:icon]}
      %a{:href => item[:uri]}
        =item[:title]
    ="Tweet: #{item[:text]} (#{item[:created_at]}). "
    %br
    %b="Tweeted by: #{item[:user][:screen_name]}"
    %br
    %b="#{item[:score_string]}."
    %br
    %b="Retweeted by #{item[:retweet_ids].count}"    
  %p
    - if item[:image] != ""
      %p
        %img{:src => item[:image]}
    =item[:content]
  %hr
