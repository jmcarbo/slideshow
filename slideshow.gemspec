# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{slideshow}
  s.version = "0.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["FIXME full name"]
  s.date = %q{2009-02-01}
  s.default_executable = %q{slideshow}
  s.description = %q{FIX (describe your package)}
  s.email = ["FIXME email"]
  s.executables = ["slideshow"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "website/index.txt"]
  s.files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc", "Rakefile", "bin/slideshow", "config/website.yml.sample", "lib/slideshow.rb", "lib/slideshow/cli.rb", "lib/templates/style.css.erb", "lib/templates/footer.html.erb", "lib/templates/gradient.svg.erb", "lib/templates/header.html.erb", "lib/templates/s5/footer.html.erb", "lib/templates/s5/header.html.erb", "lib/templates/s5/opera.css", "lib/templates/s5/outline.css", "lib/templates/s5/print.css", "lib/templates/s5/s5-core.css", "lib/templates/s5/slides.js", "lib/templates/s5/style.css.erb", "lib/templates/s6/footer.html.erb", "lib/templates/s6/header.html.erb", "lib/templates/s6/jquery.js", "lib/templates/s6/outline.css", "lib/templates/s6/print.css", "lib/templates/s6/slides.css", "lib/templates/s6/slides.js", "lib/templates/s6/style.css.erb", "script/console", "script/destroy", "script/generate", "script/txt2html", "spec/slideshow_cli_spec.rb", "spec/slideshow_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/rspec.rake", "website/index.html", "website/index.txt", "website/javascripts/rounded_corners_lite.inc.js", "website/stylesheets/screen.css", "website/template.html.erb"]
  s.has_rdoc = true
  s.homepage = %q{Please }
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{slideshow}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{FIX (describe your package)}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.2.3"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
