require "news"

describe "sna measures" do 
	it "should get up to 100 strong ties for a person" do
		result = get_strong_ties_for("plotti")
		#I should get some results
		result.count.should > 80
		result[39520560].should == 1
	end
	
	it "should calculate the out_degree for the egonetwork of a user" do 
		result = get_centralities_for("plotti")
		#Indegree of Marc Should be somewhat bigger than 20
		result["marc_smith"].should > 20 
	end
	
	it "should get the content for the tweets provided" do 
		tweets = []
		tweets << Twitter.status(62841348641927169)
		tweets[0][:uri] = "http://www.spiegel.de/politik/ausland/0,1518,758922,00.html"
		result = get_content_for(tweets)
		result.first[:title].should match("Guantanamo")
		result.first[:content].should match("Aufzeichnungen")
	end	
	
	it "should get the retweets for a given tweet" do 
		tweets = []
		tweets << Twitter.status(15312085189)
		result = get_retweets_for(tweets)
		result.first[:retweet_ids].count.should be 6
	end
	
end
