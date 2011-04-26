require 'twitter'
require 'chimps'

CONFIG = YAML.load_file("config.yaml")
Twitter.configure do |config|
            config.consumer_key = CONFIG["consumer_key"]
            config.consumer_secret = CONFIG["consumer_secret"]
            config.oauth_token = CONFIG["oauth_token"]
            config.oauth_token_secret = CONFIG["oauth_token_secret"]
end

Chimps.config[:catalog][:key] = CONFIG["infochimps_key"]
Chimps.config[:catalog][:secret] = ""
Chimps.config[:query][:key] = CONFIG["infochimps_key"]

MAX_FRIENDS = CONFIG["max_friends"]
