require 'rubygems'
require 'active_record'
require 'twitter'
require 'chimps'
require 'logger'
require 'lib/delayed_job'
require 'pony'

CONFIG = YAML.load_file("config/config.yaml")
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

#ActiveRecord 
dbconfig = YAML::load(File.open('config/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Base.logger = Logger.new(STDERR)

#Pony for Emails
Pony.options = {:from => "noreply@twitterzeit", :via => :smtp, :via_options => {
					:address => CONFIG["critsend_server"], 
					:port => CONFIG["critsend_port"], 
					:user_name => CONFIG["critsend_username"], 
					:password => CONFIG["critsend_password"]}
				}
