Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.6'

  s.name = 'ernicorn'
  s.version = '1.0.0'
  s.date = '2012-06-23'

  s.summary     = "Ernicorn is a BERT-RPC server implementation based on unicorn."
  s.description = "Ernicorn is a BERT-RPC server packaged as a gem."

  s.authors  = ["Tom Preston-Werner", "tmm1", "rtomayko"]
  s.email    = 'tmm1@github.com'
  s.homepage = 'https://github.com/github/ernicorn'

  s.add_runtime_dependency('bert', ">= 1.1.0")
  s.add_runtime_dependency('bertrpc', ">= 1.0.0")
  s.add_runtime_dependency('unicorn', "~> 4.1.1")

  s.add_development_dependency('shoulda', "~> 2.11.3")

  s.files         = `git ls-files`.split("\n") - %w[Gemfile Gemfile.lock]
  s.test_files    = `git ls-files -- test`.split("\n").select { |f| f =~ /_test.rb$/ }

  s.bindir        = "script"
  s.executables   = %w[ernicorn ernicorn-ctrl]
  s.require_paths = %w[lib]
  s.extra_rdoc_files = %w[LICENSE README.md]
end
