require 'bundler'
Bundler.require
require 'rss'
require_relative 'models/user'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)


class Url <ActiveRecord::Base
    validates_presence_of :name
    validates_presence_of :url
    belongs_to :user
end

class Server < Sinatra::Base
  enable :sessions
  set :session_secret, "My session secret"
end

user_id = nil

get '/' do
  @parse_list = []
  @@current_user = User.where(id: user_id).first

  if @@current_user == nil
      redirect '/log_in'
  else
      @urls = Url.where(user_id: @@current_user).order("created_at DESC").limit(20)
      @urls.each do |url|
         @rss = RSS::Parser.parse(url.url)
         @parse_list << @rss
      end
  end
  erb :index
end

get '/new' do
    erb :new
end

get '/edit' do
    if @@current_user == nil
        redirect '/log_in'
    else
      @urls = Url.where(user_id: @@current_user).order("created_at DESC").limit(20);
    end
    erb :edit
end

post '/new' do
    url = Url.new
    url.name = params[:name]
    url.description = params[:description]
    url.url = params[:url]
    url.user_id = user_id
    url.save
    redirect '/'
    erb :new
end

post "/delete" do
    
end 

get '/sign_up' do
  session[:user_id] ||= nil
  if session[:user_id]
    redirect '/log_out' #logout form
  end

  erb :sign_up
end

#signup action
post '/users' do
  if params[:password] != params[:confirm_password]
    redirect "/sign_up"
  end

  user = User.new(email: params[:email], name: params[:name])
  user.encrypt_password(params[:password])
  if user.save!
    session[:user_id] = user.id
    redirect "/" #user dashboard page
  else
    redirect "/sign_up"
  end
end

#login form
get '/log_in' do
  if session[:user_id]
    redirect '/log_out'
  end

  erb :log_in
end

#login action
post '/session' do
  if session[:user_id]
    redirect "/"
  end

  user = User.authenticate(params[:email], params[:password])
  if user
    session[:user_id] = user.id
    user_id = session[:user_id]
    redirect '/'
  else
    redirect "/log_in"
  end
end


#logout form
get '/log_out' do
  unless session[:user_id]
    redirect '/log_in'
  end 

  erb :log_out
end

#logout action
delete '/session' do
  session[:user_id] = nil
  user_id = session[:user_id]
  redirect '/log_in'
end
