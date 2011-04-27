require 'config/init'
require 'open-uri'
require 'readability'
require 'digest'
require 'pismo'

# Returns strong ties [[id, strength],...] for a given user using the infochimp API
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

# Returns all friends for a twitter user (friends == people a user follows)
def get_friends_for(username)
	begin 
		friends = YAML.load_file("/data/" + username + "_friends")
	rescue
		puts "Have to get all the friends for the user #{username} first"
	end
	if friends == nil
		friends = []
		cursor = -1 
		counter = 0
		#Dont get more friends than we think is necessary, default 1000
		max = MAX_FRIENDS/100
		while cursor != 0 && counter < max
			begin
				result = Twitter.friends(username, {:cursor => cursor})
				friends += result[:users]
				cursor = result[:next_cursor]
				puts "Next Cursor for #{username} is #{cursor}"
				counter += 1
			rescue 
				puts "Couldn't get friends for #{username}"
				break
			end
		end
		File.open("/data/" + username + "_friends","w") {|file| file.puts(friends.to_yaml)}
		return friends
	else
		return friends
	end
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

#Gets the Content for a given url using the readability project
def get_content_for(tweets)
	tweets.each do |tweet|
		begin
			file = YAML.load_file("/data/" + Digest::SHA1.hexdigest(tweet[:uri]) + "_content")
			tweet[:content] = file[:content]
			tweet[:title] = file[:title]
			tweet[:image] = file[:image]
		rescue
			puts "Have to obtain content for this url #{tweet[:uri]} first"
		end
		if file == nil
		    # We are using Pismo Gem instead now
			#text = open(tweet[:uri]).read rescue ""
			#tweet[:content] = Readability::Document.new(text).content(remove_unlikely_candidates=true) rescue ""
	    	#tweet[:title] = Nokogiri::HTML(text).at_css("title").text  rescue ""
		    #tweet[:image] = ""
		    begin 
		    	Timeout::timeout(5){
		    		doc = Pismo::Document.new(tweet[:uri])
		    		tweet[:content] = doc.html_body
		    		tweet[:title] = doc.html_title
		    		tweet[:image] = doc.images.first rescue ""
		    		tweet[:icon] = doc.favicon rescue ""
		    	}
		    rescue Timeout::Error
		    	tweet[:content] = tweet[:uri]
		    	tweet[:title] = tweet[:uri]
		    	tweet[:image] = ""
		    	tweet[:icon] = ""
		    rescue 
		    	tweet[:content] = tweet[:uri]
		    	tweet[:title] = tweet[:uri]
		    	tweet[:image] = ""
		    	tweet[:icon] = ""
		    rescue 
		    end
		    File.open("/data/" + Digest::SHA1.hexdigest(tweet[:uri]) + "_content","w"){|file| file.puts(tweet.to_yaml)}
		end
	end
	return tweets
end

# Returns all retweets for a given tweet
# This operation takes quite long
#TODO The cached version of retweets is not up to date there might have been more changes but we dont know about them untill we recompute
def get_retweets_for(tweets)
	i = 0
	tweets.each do |tweet|
		begin
			tweet[:retweet_ids] = YAML.load_file("/data/" + tweet.id.to_s + "_retweets")
		rescue
		end
		if tweet[:retweet_ids] == nil
			puts "Have to calculate Retweets for #{i} of #{tweets.count}"		
			i += 1
			tweet[:retweet_ids] = []
			Twitter.retweeters_of(tweet.id, {:count => 100}).each do |retweet|
				tweet[:retweet_ids] << { :id => retweet.id, :person => retweet.screen_name, :published_at => retweet.created_at}
			end
			File.open("/data/" + tweet.id.to_s + "_retweets","w") {|file| file.puts(tweet[:retweet_ids].to_yaml)}
		end
	end
	return tweets
end

# Gets the link of a tweet
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

# Gets enough relevant tweets for a user
# This operation takes quite long
#TODO the cached version needs to be updated every couple of hours etc... maybe individually based on the rate of each tweeter
def get_tweets_for(username)
	friends = get_friends_for(username)
	tweets = []
	friends.each do |friend|
	    # We will get 20 most recent tweets from each person we follow
		begin 
			result = YAML.load_file("/data/" + friend.screen_name + "_tweets")
		rescue
			puts "Collecting tweets of #{friend.screen_name}"
		end
		if result == nil
			begin
				result = Twitter.user_timeline(friend.screen_name)
			rescue
				result = []
			end
			File.open("/data/" + friend.screen_name + "_tweets","w") {|file| file.puts(result.to_yaml)}
		end
		tweets += result 
	end
	return tweets
end

# Calculates a recency value for a set of tweets. Basically a value between 0 and 1 depending how old the tweet is
def get_news_value_for(tweets)
	#News value is only based on recency so far
	tweets.each do |tweet|
		tweet[:news_value] = 1/((Time.now - Time.parse(tweet.created_at))/3600+1)
	end
end

# Calculates all the Values for the newspaper
def calculate_newspaper(tweets,strong_ties,centralities, additive = true)
	 max_retweets = 0
	 max_centrality = 0
	 max_strong = 0
	 max_news = 0
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
     	if tweet[:news_value] > max_news
     		max_news = tweet[:news_value]
     	end
     end
     strong_ties.each do |tie|
     	if tie[1] > max_strong
     		max_strong = tie[1]
     	end
     end
     tweets.each do |tweet|
        rt_score = (tweet[:retweet_ids].count.to_f / max_retweets)
        st_score = (strong_ties[tweet.user.id].to_f/ max_strong)
        ct_score = (centralities[tweet.user.screen_name].to_f / max_centrality)
        nw_score = (tweet[:news_value].to_f / max_news)
        tweet[:rt_score] = rt_score
        tweet[:st_score] = st_score
        tweet[:ct_score] = ct_score
        tweet[:nw_score] = nw_score
		if additive
			score = rt_score + st_score + ct_score + nw_score
		else
			score = rt_score * st_score * ct_score * nw_score
		end
		tweet[:score] = score
		tweet[:score_string] = "Total Score: #{score} RT: #{rt_score} ST: #{st_score} CT: #{ct_score} NW: #{nw_score}"
     end
     return tweets
end
