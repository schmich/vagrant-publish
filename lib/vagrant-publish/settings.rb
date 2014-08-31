require 'json'
require 'hashery/open_cascade'

class Settings
  def initialize(settings_file)
    @settings_file = settings_file

    if !File.exist?(settings_file)
      @settings = Hashery::OpenCascade.new
    else
      json = File.read(settings_file)
      @settings = Hashery::OpenCascade[JSON.parse(json, symbolize_names: true)]
    end
  end

  def method_missing(sym, *args, &block)
    @settings.send(sym, *args, &block)
  end

  def self.load(settings_file = 'settings.json')
    Settings.new(settings_file)
  end

  def save!
    File.write(@settings_file, JSON.pretty_generate(@settings))
  end
end

