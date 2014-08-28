require 'io/console'
require 'json'
require 'pp'
require 'vagrant'
require 'settings'
require 'dropbox_store'

settings = Settings.load('settings.json')

store = DropboxStore.new(settings)

def prompt_vm
  vm_path = File.join(Dir.home, 'VirtualBox VMs')
  vms = Dir.entries(vm_path).reject { |d| d == '.' || d == '..' }

  vms.each_with_index do |vm, i|
    puts "#{i + 1}. #{vm}"
  end

  begin
    print 'Image: '
    index = gets.to_i

    if index <= 0 || index >= vms.length
      puts 'Not a valid option.'
      raise
    end
  rescue
    retry
  end

  return vms[index - 1]
end

def prompt_box(user)
  box_names = user.box_names
  box_names.each_with_index do |name, i|
    puts "#{i + 1}. #{name[:tag]}"
  end

  begin
    print 'Vagrant Cloud box: '
    index = gets.to_i

    if index <= 0 || index >= box_names.length
      puts 'Not a valid option.'
      raise
    end
  rescue
    retry
  end

  return box_names[index - 1][:name]
end

vagrant_user = settings.vagrant.username
if vagrant_user.empty?
  print 'Vagrant Cloud username: '
  vagrant_user = gets.strip
  settings.vagrant.username = vagrant_user 
end

vagrant_token = settings.vagrant.token
if vagrant_token.empty?
  print 'Vagrant Cloud API token: '
  vagrant_token = gets.strip
  settings.vagrant.token = vagrant_token
end

settings.save!

user = VagrantUser.new(vagrant_user, vagrant_token)
vagrant_box = prompt_box(user)

box = user.box(vagrant_box)
exit 1 if !box
default_version = VagrantVersion.increment_version(box.current_version.version)

puts 'Choose an image to upload:'
image = prompt_vm.strip

print "Image version (default #{default_version}): "
version = gets.strip
image_version = version.empty? ? default_version : version

tmp_dir = Dir.mktmpdir
Dir.chdir(tmp_dir)

box_file_name = "#{image}-#{image_version}.box"
box_path = File.join(tmp_dir, box_file_name)
puts "Packaging image into #{box_path}..."

success = system("vagrant package --base \"#{image}\" --output \"#{box_file_name}\"")
if success
  puts 'Packaging complete.'
else
  puts 'Packaging failed.'
  exit 1
end

puts 'Uploading image to Dropbox...'
public_url = store.upload(box_path)
puts 'Upload complete.'

puts 'Creating box version.'
new_version = box.create_version(image_version)

puts 'Adding image provider.'
new_version.add_provider('virtualbox', public_url)

puts 'Releasing version.'
new_version.release

puts 'Fin.'
