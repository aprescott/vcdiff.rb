Gem::Specification.new do |gem|
  gem.name          = "vcdiff.rb"
  gem.version       = "0.0.3"
  gem.authors       = ["Adam Prescott"]
  gem.email         = ["adam@aprescott.com"]
  gem.description   = "Pure-Ruby VCDIFF encoder/decoder."
  gem.summary       = "Pure-Ruby encoder and decoder for the VCDIFF format."
  gem.homepage      = "https://github.com/aprescott/vcdiff.rb"

  gem.files         = Dir["{lib/**/*,test/**/*,*.gemspec}"] + %w[rakefile LICENSE Gemfile README.md]
  gem.require_path  = "lib"
  gem.license       = "MIT"

  [
    "bindata", "~> 1.6.0",
    "bentley_mcilroy", ">= 0"
  ].each_slice(2) do |name, version|
    gem.add_runtime_dependency(name, version)
  end

  [
    "rake", "~> 10.0.0",
    "rspec", "~> 2.5"
  ].each_slice(2) do |name, version|
    gem.add_runtime_dependency(name, version)
  end
end