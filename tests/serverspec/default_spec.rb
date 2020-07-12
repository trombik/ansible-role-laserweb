require "spec_helper"
require "serverspec"
require "shellwords"

backend_service = "lw.comm-server"
backend_repo_path = "/home/lw.comm-server"
services = %w[nginx] << backend_service
user    = "laserweb"
group   = "laserweb"
groups  = %w[dialout]
ports   = [80, 8000]

repos = [
  {
    path: backend_repo_path,
    version: "test-ci"
  },
  {
    path: "/home/LaserWeb4",
    version: "sync-package-json"
  }
]

describe user(user) do
  it { should exist }
  it { should belong_to_primary_group group }
  groups.each do |g|
    it { should belong_to_group g }
  end
end

repos.each do |repo|
  describe file repo[:path] do
    it { should be_directory }
  end
  describe command "cd #{repo[:path].shellescape} && git status --short" do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) { should_not match(/^\s+M\s+.*/) }
  end

  describe command "cd #{repo[:path].shellescape} && git branch --list --color=never" do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) { should match(/^\*\s+#{repo[:version]}$/) }
  end
end

describe command "cd #{backend_repo_path.shellescape} && node ./node_modules/serialport/build/Release/serialport.node" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should eq "" }
end

case os[:family]
when "ubuntu"
  describe file "/etc/systemd/system/#{backend_service}.service" do
    it { should be_file }
    its(:content) { should match(/Managed by ansible/) }
  end
end

services.each do |service|
  describe service(service) do
    it { should be_running }
    it { should be_enabled }
  end
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
