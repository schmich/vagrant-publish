require 'dropbox_sdk'

class DropboxStore
  def initialize(settings)
    access_token = settings.dropbox.token

    if access_token.empty?
      flow = DropboxOAuth2FlowNoRedirect.new(APP_KEY, APP_SECRET)
      authorize_url = flow.start()

      # TODO: Externalize this dependency.
      puts "Visit #{authorize_url} for authorization."
      print "Authorization code: "
      code = gets.strip

      access_token, _ = flow.finish(code)

      settings.dropbox.token = access_token
      settings.save!
    end

    @client = DropboxClient.new(access_token)
  end

  def upload(file, name = nil)
    dropbox_path = name
    dropbox_path ||= '/' + File.basename(file)

    response = @client.put_file(dropbox_path, open(file))
    path = response['path']
    response = @client.media(path)
    share_url = response['url']

    return share_url
  end

  # TODO: Handle these better.
  APP_KEY = ENV['DROPBOX_APP_KEY']
  APP_SECRET = ENV['DROPBOX_APP_SECRET']
end
