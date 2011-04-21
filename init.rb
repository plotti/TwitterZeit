require 'twitter'
require 'chimps'

ONFIG = YAML.load_file("config.yaml")
Twitter.configure do |config|
            config.consumer_key = "lPeEtUCou8uFFOBt94h3Q"
            config.consumer_secret = "iBFQqoV9a5qKCiAfitEXFzvkD7jcpSFupG8FBGWE"
            config.oauth_token = "15533871-abkroGVmE7m1oJGzZ38L29c7o7vDyGGSevx6X25kA"
            config.oauth_token_secret = "pAoyFeGQlHr53BiRSxpTUpVtQW0B0zMRKBHC3hm3s"
end

Chimps.config[:catalog][:key] = "plotti-zUTHy7q2WmihzHpwi9UtwJZws69"
Chimps.config[:catalog][:secret] = ""
Chimps.config[:query][:key] = "plotti-zUTHy7q2WmihzHpwi9UtwJZws69"

