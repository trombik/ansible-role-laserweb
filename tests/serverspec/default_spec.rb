require "spec_helper"
require "serverspec"

service = "lw.comm-server"
user    = "laserweb"
group   = "laserweb"
groups  = %w[dialout]
ports   = [80, 8000]
branch_backend = "test-ci"
branch_frontend = "sync-package-json"
repo_dir_backend = "/home/lw.comm-server"
repo_dir_frontend = "/home/LaserWeb4"

describe user(user) do
  it { should exist }
  it { should belong_to_primary_group group }
  groups.each do |g|
    it { should belong_to_group g }
  end
end

describe file repo_dir_backend do
  it { should be_directory }
end

describe file repo_dir_frontend do
  it { should be_directory }
end

describe command "cd #{repo_dir_backend} && git branch --list --color=never" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/\*\s+#{branch_backend}$/) }
end

describe command "cd #{repo_dir_frontend} && git branch --list --color=never" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/\*\s+#{branch_frontend}$/) }
end

case os[:family]
when "ubuntu"
  describe file "/etc/systemd/system/#{service}.service" do
    it { should be_file }
    its(:content) { should match(/Managed by ansible/) }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
