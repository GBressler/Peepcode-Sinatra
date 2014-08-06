$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'sinatra'

require 'dm-migrations'
require 'dm-core'
require 'dm-timestamps'
require 'lib/authorization'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/adserver.db")

class Ad
	include DataMapper::Resource

	property :id,			Serial
	property :title,		String
	property :content,		Text
	property :width,		Integer
	property :height,		Integer
	property :filename,		String
	property :url,			String
	property :is_active,	Boolean
	property :created_at,	DateTime
	property :updated_at,	DateTime
	property :size,			Integer
	property :content_type,	String

	has n, :clicks

	def handle_upload( file )# figures out file size, type and putting it into place.  Best to keep all of this in the model. See how it ties into the /create method.
		self.content_type = [:type]
		self.size = File.size(file[:tempfile])	
		path = File.join(Dir.pwd, "/public/ads", self.filename)
		File.open(path, "wb") do |f|
			f.write(file[:tempfile].read)
		end
	end

end


class Click
include DataMapper::Resource

	property :id,			Serial
	property :ip_address,	String
	property :created_at,	DateTime

belongs_to :ad

end
 
configure :development do  #automigrate only runs in dev environment
#Create or upgrade all tables at once, like magic
#DO NOT USE auto_migrate.  It will wipe out the database.
DataMapper.auto_upgrade!
end


helpers do #this makes sure to include the Authorization/password screen
	include Sinatra::Authorization
end

before do #specify this before adding other methods
	headers "Content-Type" => "text/html; charset=utf-8"
end

get '/' do  #Hompage?
	@title = "Welcome to my Adserver"
	erb :welcome #embedded Ruby Template for a welcome page (see views folder) /A link to homepage?
end

get '/ad' do
  id = repository(:default).adapter.query(
  	'SELECT id FROM ads ORDER BY random() LIMIT 1;'
  	)
 @ad = Ad.get(id)

  erb :ad, :layout => false
end


get '/list' do
	require_admin
	@title = "List Ads"
	@ads = Ad.all(:order => [:created_at.desc]) #add all ads in process of creation in a descending order NOTE that Datamapper is differenct from active record with Ad.all
	erb :list  #process the list template
end

get '/new' do
	require_admin
	@title = "Create a new Ad"
	erb :new
	
end

=begin
post '/create' do 	
	require_admin	
	@ad = Ad.new(params[:ad])  #we are making a new ad instance and taking the info from what the user input
	@ad.content_type = params[:image][:type]  #we are taking info from the file itself, the user isn't worried with this info
	@ad.size = File.size(params[:image][:tempfile])
	if @ad.save  #if this works the info/ad gets saved, if it fails we redirect to the list of existing ads
		path = File.join(Dir.pwd, "/public/ads", @ad.filename)
		File.open(path, "wb") do |f|
			f.write(params[:image][:tempfile].read)
		end
		redirect "/show/#{@ad.id}"
	else
		redirect('/list')
	end
end
=end

post '/create' do 	
	require_admin	
	@ad = Ad.new(params[:ad])  #we are making a new ad instance and taking the info from what the user input
	@ad.handle_upload = (params[:image])  #we are taking info from the file itself, the user isn't worried with this info
	if @ad.save  #if this works the info/ad gets saved, if it fails we redirect to the list of existing ads
		redirect "/show/#{@ad.id}"
	else
		redirect('/list')
	end
end

get '/delete/:id' do 
require_admin
ad = Ad.get(params[:id])
unless ad.nil?
	path = File.join(Dir.pwd, "/public/ads", ad.filename)
	File.delete(path) if File.exists?(path)
	ad.delete
  end
  redirect('/list')
end

get '/show/:id' do 
	require_admin
  @ad = Ad.get(params[:id]) #ad.get is Datamapper/ Ad.find is for Rails
  if @ad  # if the ad exists we show it in a page if not, page gets redirected to existing ads
  	erb :show
  else
  	redirect('/list')
  end
end

get '/click/:id' do
 ad = Ad.get(params[:id])
 ad.clicks.create(:ip_address => env["REMOTE_ADDR"])
 redirect(ad.url)
end