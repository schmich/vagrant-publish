require 'rest_client'

class VagrantBox
  def initialize(user, name, versions, current_version)
    @user = user
    @name = name
    @versions = versions
    @current_version = current_version
  end

  def create_version(version)
    begin
      response = RestClient.post "https://vagrantcloud.com/api/v1/box/#{@user.name}/#{@name}/versions",
        'version[version]' => version,
        'access_token' => @user.token
    rescue RestClient::BadRequest => e
      puts 'Could not create version. Ensure that it does not already exist.'
      return nil
    end

    return VagrantVersion.from_json(self, response)
  end

  def self.from_json(user, json)
    obj = JSON.parse(json)
    versions = []
    obj['versions'].each do |version|
      versions << VagrantVersion.from_hash(self, version)
    end

    VagrantBox.new(
      user,
      obj['name'],
      versions,
      VagrantVersion.from_hash(self, obj['current_version'])
    )
  end

  attr_reader :name, :versions, :current_version, :user
end

class VagrantVersion
  def initialize(box, version, number)
    @box = box
    @version = version
    @number = number
  end

  def add_provider(name, url)
    response = RestClient.post "https://vagrantcloud.com/api/v1/box/#{@box.user.name}/#{@box.name}/version/#{@number}/providers",
      'provider[name]' => name,
      'provider[url]' => url,
      'access_token' => @box.user.token

    return response
  end

  def release
    response = RestClient.put "https://vagrantcloud.com/api/v1/box/#{@box.user.name}/#{@box.name}/version/#{@number}/release",
      'access_token' => @box.user.token

    return response
  end

  def self.from_json(box, json)
    obj = JSON.parse(json)
    self.from_hash(box, obj)
  end

  def self.from_hash(box, hash)
    VagrantVersion.new(box, hash['version'], hash['number'].to_i)
  end

  def self.increment_version(version)
    parts = version.split('.')
    parts[-1] = (parts[-1].to_i + 1).to_s
    return parts.join('.')
  end

  attr_reader :box, :version, :number
end

class VagrantUser
  def initialize(username, token)
    @name = username
    @token = token
  end

  def box(box_name)
    begin
      response = RestClient.get "https://vagrantcloud.com/api/v1/box/#{@name}/#{box_name}"
      return VagrantBox.from_json(self, response)
    rescue RestClient::ResourceNotFound => e
      puts "Box not found: #{@name}/#{box_name}."
      return nil
    end
  end

  # TODO: Expose as just 'boxes', move code into VagrantBox
  def box_names
    response = RestClient.get "https://vagrantcloud.com/api/v1/user/#{@name}",
      'access_token' => @token

    names = []
    obj = JSON.parse(response)
    for box in obj['boxes']
      names << { name: box['name'], tag: box['tag'] }
    end

    return names
  end

  attr_reader :name, :token
end
