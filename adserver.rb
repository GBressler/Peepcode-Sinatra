require 'rubygems'
require 'sinatra'

require 'dm-migrations'
require 'dm-core'
require 'dm-timestamps'

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

end

#Create or upgrade all tables at once, like magic
#DO NOT USE auto_migrate.  It will wipe out the database.
DataMapper.auto_upgrade!

before do
	headers "Content-Type" => "text/html; charset=utf-8"
end

get '/' do
	@title = "Welcome to my Adserver"
	erb :welcome
end

get '/ad' do

end

get '/list' do
	@title = "List Ads"
	@ads = Ad.all(:order => [:created_at.desc]) #add all ads in process of creation in a decending order NOTE that Datamapper is differenct from active record with Ad.all
	erb :list  #process the list template
end

get '/new' do
	@title = "Create a new Ad"
	erb :new
	
end

post '/create' do 		
	@ad = Ad.new(params[:ad])  #we are making a new ad instance and taking the info from what the user input
	@ad.content_type = params[:image][:type]  #we are taking info from the file itself, the user isn't worried with this info
	@ad.size = File.size(params[:image][:tempfile])
	if @ad.save
		path = File.join(Dir.pwd, "/public/ads", @ad.filename)
		File.open(path, "wb") do |f|
			f.write(params[:image][:tempfile].read)
		end
		redirect "/show/#{@ad.id}"
	else
		redirect('/list')
	end
end

get '/delete/:id' do

end

get '/show/:id' do
  @ad = Ad.get(params[:id])
  if @ad
  	erb :show
  else
  	redirect('/list')
  end
end

get '/click/:id' do

end