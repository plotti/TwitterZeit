require "news"

describe "sna measures" do 
	it "should get up to 100 strong ties for a person" do
		result = get_strong_ties_for("plotti")
		#I should get some results
		result.count.should > 80
		result[39520560].should == 1
	end
	
	it "should calculate the indegree for the egonetwork of a user" do 
		result = get_centralities_for("plotti")
		result["marc_smith"].should == 27
	end
end
