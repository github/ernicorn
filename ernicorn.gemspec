Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.6'

  s.name = 'ernicorn'
  s.version = '1.0.0'
  s.date = '2012-06-21'

  s.summary     = "Ernicorn is a BERT-RPC server implementation based on unicorn."
  s.description = "Ernicorn is a BERT-RPC server packaged as a gem."

  s.authors  = ["Tom Preston-Werner", "tmm1"]
  s.email    = 'tmm1@github.com'
  s.homepage = 'http://github.com/github/ernicorn'

  s.require_paths = %w[lib]

  s.executables = ["ernicorn"]
  s.extra_rdoc_files = %w[LICENSE README.md]

  s.add_dependency('bert', [">= 1.1.0"])
  s.add_dependency('bertrpc', [">= 1.0.0"])
  s.add_dependency('unicorn', ["~> 4.1.1"])

  s.add_development_dependency('shoulda', [">= 2.11.3", "< 3.0.0"])

  # = MANIFEST =
  s.files = %w[
    History.txt
    LICENSE
    README.md
    Rakefile
    bin/ernicorn
    contrib/ebench.erl
    ernicorn.gemspec
    lib/ernie.rb
    lib/ernicorn.rb
    test/helper.rb
    test/load.rb
    test/test_ernie.rb
    test/test_ernie_server.rb
  ]
  # = MANIFEST =

  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
