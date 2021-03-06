# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "qrpc"
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Martin Koz\u{e1}k"]
  s.date = "2012-02-19"
  s.email = "martinkozak@martinkozak.net"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    "CHANGES.txt",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "TODO.md",
    "VERSION",
    "lib/qrpc/client.rb",
    "lib/qrpc/client/dispatcher.rb",
    "lib/qrpc/client/exception.rb",
    "lib/qrpc/client/job.rb",
    "lib/qrpc/general.rb",
    "lib/qrpc/locator.rb",
    "lib/qrpc/protocol/exception-data.rb",
    "lib/qrpc/protocol/qrpc-object.rb",
    "lib/qrpc/protocol/request.rb",
    "lib/qrpc/server.rb",
    "lib/qrpc/server/dispatcher.rb",
    "lib/qrpc/server/job.rb",
    "qrpc.gemspec",
    "test-client.rb",
    "test-server.rb"
  ]
  s.homepage = "http://github.com/martinkozak/qrpc"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.17"
  s.summary = "Queued JSON-RPC client and server. Works as normal RPC server, but through queue interface, so allows highly scalable, distributed and asynchronous remote API implementation and fast data processing. It's based on eventmachine and beanstalkd, so it's fast and thread safe."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json-rpc-objects>, [">= 0.3.3"])
      s.add_runtime_dependency(%q<depq>, [">= 0.4"])
      s.add_runtime_dependency(%q<em-jack>, [">= 0.1.3"])
      s.add_runtime_dependency(%q<eventmachine>, [">= 0"])
      s.add_runtime_dependency(%q<uuid>, [">= 2.3.2"])
      s.add_development_dependency(%q<bundler>, [">= 1.0.0"])
      s.add_development_dependency(%q<jeweler2>, [">= 2.0.0"])
    else
      s.add_dependency(%q<json-rpc-objects>, [">= 0.3.3"])
      s.add_dependency(%q<depq>, [">= 0.4"])
      s.add_dependency(%q<em-jack>, [">= 0.1.3"])
      s.add_dependency(%q<eventmachine>, [">= 0"])
      s.add_dependency(%q<uuid>, [">= 2.3.2"])
      s.add_dependency(%q<bundler>, [">= 1.0.0"])
      s.add_dependency(%q<jeweler2>, [">= 2.0.0"])
    end
  else
    s.add_dependency(%q<json-rpc-objects>, [">= 0.3.3"])
    s.add_dependency(%q<depq>, [">= 0.4"])
    s.add_dependency(%q<em-jack>, [">= 0.1.3"])
    s.add_dependency(%q<eventmachine>, [">= 0"])
    s.add_dependency(%q<uuid>, [">= 2.3.2"])
    s.add_dependency(%q<bundler>, [">= 1.0.0"])
    s.add_dependency(%q<jeweler2>, [">= 2.0.0"])
  end
end

