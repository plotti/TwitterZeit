require 'rubygems'
require 'chimps'
require 'twitter'
require 'open-uri'
require 'readability'
require 'sinatra'

Twitter.configure do |config|
			config.consumer_key = "lPeEtUCou8uFFOBt94h3Q"
			config.consumer_secret = "iBFQqoV9a5qKCiAfitEXFzvkD7jcpSFupG8FBGWE"
			config.oauth_token = "15533871-abkroGVmE7m1oJGzZ38L29c7o7vDyGGSevx6X25kA"
			config.oauth_token_secret = "pAoyFeGQlHr53BiRSxpTUpVtQW0B0zMRKBHC3hm3s"
end

Chimps.config[:catalog][:key] = "plotti-zUTHy7q2WmihzHpwi9UtwJZws69"
Chimps.config[:catalog][:secret] = ""
Chimps.config[:query][:key] = "plotti-zUTHy7q2WmihzHpwi9UtwJZws69"

def get_strong_links_for_person(username)
	request = Chimps::QueryRequest.new("social/network/tw/graph/strong_links.json", 
										:query_params =>{:screen_name => "plotti"})
	response = request.get
	response.parse!
	strong_links = Hash[response.data["strong_links"]]
end

def get_content_title_and_images(uri)
	text = open(uri.first).read rescue ""
	content = Readability::Document.new(text).content(remove_unlikely_candidates=true) rescue ""
    title = Nokogiri::HTML(text).at_css("title").text  rescue ""
    return {:content => content, :title => title, :image => image}
end

def get_retweets_for_tweets(tweets)
	Twitter.
end

def get_tweets_with_links(tweets)
	url_regexp = /http:\/\/\w/
	result = []
	tweets.each do |item|
		url = item.text.split.grep(url_regexp)
		if url != []
			result << item
		end
	end
	return result
end

def get_tweets(username)
	tweets = Twitter.home_timeline(:count => 500)
end

def calculate_newspaper(tweets,strong_ties,central_persons)
     @news << { :created_at => item.created_at, :text => item.text, 
                :person => item.user.screen_name, :content => content, :title => title,
                :strength => strong_links[item.user.id], :image => img}
end

get '/show' do 
	strong_ties = get_strong_ties_for(username)
	central_persons = get_central_persons_for(username)
	
	result = get_tweets_for(username)
	result = filter_tweets_with_links_for(result)
	result = get_retweets_for(result)
	
	@news = calculate_newspaper(result,strong_ties,central_persons)
	
	haml :show
end

__END__
%html
  %title="The #{USERNAME} Times"
  %body
    %h1="The #{USERNAME} Times"
    %content=yield


@@ show
- @news.each do |item|
  %p
    %h1
      %a{:href => item[:uri]}
        =item[:title]
    ="Tweet: #{item[:text]} (#{item[:created_at]}). "
    %b="Tweeted by: #{item[:person]} Strength: #{item[:strength]}."
  %p
    %p
      %img{:src => item[:image]}
    =item[:content]
  %hr

