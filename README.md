# TwitterZeit

Is a very tiny proof of concept of a twittertimes or paperli clone.
Looking for someone to participate on the project.

## Definitions:
Friends = People a user follows on twitter
Followers = People that follow a user on twitter
Ties = Friends or Follower connections on twitter
Strong Ties = Users that interacted with the @ sign a lot have stronger ties.
Retweets = People forwarding a tweet to their readers

## How does it work?

1. Get all the strong ties [see granovetter] a user has on twitter.
2. Get the users friends and their friends and compute a so called egonetwork for a user.
   That is the connection between the user and his friends, but also inbetween the friends
3. Get all the tweets of the people a user is following on twitter.
4. Filter out only the tweets that contain a link.
5. Get all the retweets for the remaining tweets
6. Calculate the total values for the Tweets:
   a)Calculate a recency value for the remaining tweets
   	 The more recent a tweet is in comparison to the other tweets the higher the value Max = 1
   b)Calculate a retweet value 
     The more often a tweet has been retweeted the higher the value Max = 1
   c)Calculate the friendship value
     If the connection to the person the tweet is coming from is strong then it has a higher value Max = 1
   d)Calculate the authority value
     The more central the person is in your egonetwork (opinion leader) the higher the value Max = 1
7. Add up all scores (Alternatively multiply them) 
8. Take the top 20 Tweets with the highest scores.
9. Extract the content [Title, Body, Images..] from the websites behind the links and present it in a nice way
    
## What is it using?

* I am using the infochimps API to get the strong connections between users
* I am using the Twitter API to get the tweets and the retweets for a user, also the friends connections
* The framework to offer the newspaper is Sinatra.
* The gem to pull the content out of the links is Pismo.

## Author

* THomas Plotkowiak a Social Media Researcher at the MCM Institute 
* Contact me under: plotti@gmx.net

