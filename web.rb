require 'rubygems'
require 'sinatra'
require 'news'

def manufacture_newspaper_for(username)
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
	File.open("/data/" + username + "_results","w") {|file| file.puts(result.to_yaml)}
	return result
end

get '/show/:username' do |username|
	@username = username
	begin
		puts "Serving precomputed newspaper"
		result = YAML.load_file("/data/" + username + "_results")
	rescue
		puts "Have to manufacture the  Newspaper first. "
	end
	if result == nil
		result = manufacture_newspaper_for(username)
	end
	@news = get_content_for(result)
	haml :show
end

__END__
@@layout
%html
  <?xml version="1.0" encoding="UTF-8"?>
  %header
    %link{ :rel => "stylesheet", :type => "text/css", :href => "/reset.css"}
    %link{ :rel => "stylesheet", :type => "text/css", :href => "/style.css"}
    %link{ :rel => "stylesheet", :type => "text/css", :href => "/typography.css"}
    %meta{ "http-equiv" => "Content-Type", :content => "text/html; charset=utf-8"}
  %title="The #{@username} Times"
  %body
    .main
      %h1="The #{@username} Times"
      =yield


@@ show
- @news.each do |item|
  #separator
  %p
    %h2
      -if item[:icon].to_s.lstrip.rstrip != ""
        %img{:src => item[:icon], :width => 50, :height => 50}
      %a{:href => item[:uri]}
        =item[:title]
    %blockquote
      ="Tweet: #{item[:text]} (#{item[:created_at]}). "
    
    %h3
      Tweeted by:
      %a{:href => "http://twitter.com/#{item[:user][:screen_name]}/status/#{item[:id_str]}"}
        =item[:user][:screen_name]
    %h4="Retweeted by #{item[:retweet_ids].count}:"
    %h6="#{item[:retweet_ids].collect{|r| r[:person]}.join(' ')}"    
    - total_score_string = "http://chart.apis.google.com/chart?chxr=0,0,4&chxt=y&chs=300x150&cht=gm&chd=t:#{item[:score]}&chds=0,4&chtt=Total+Value"
    %img{ :src => total_score_string, :width => "300", :height => "150", :alt => "Tweet Value"}
    - pre = "http://chart.apis.google.com/chart?chbh=a,6,20&chs=300x150&cht=bhg&chco=FF0000,00FF00,FF9900,0000FF&chds=0,1,0,1,0,1,0,1&chd="
    - val = "t:#{item[:nw_score]}|#{item[:rt_score]}|#{item[:ct_score]}|#{item[:st_score]}"
    - suff = "&chm=tRecency,000000,0,0,13|tRetweets,000000,1,1,13,-1|tAuthority,000000,2,0,13|tFriend+Value,000000,3,1,13"
    %img{ :src => "#{pre+val+suff}", :width => "300", :height => "150", :alt => "" }
  %p
    =item[:content]
  %hr
