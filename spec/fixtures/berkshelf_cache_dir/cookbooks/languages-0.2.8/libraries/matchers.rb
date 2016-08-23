if defined?(ChefSpec)
  ChefSpec.define_matcher :erlang_install
  def install_erlang_install(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:erlang_install, :install, resource_name)
  end
  ChefSpec.define_matcher :erlang_execute
  def run_erlang_execute(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:erlang_execute, :run, resource_name)
  end

  ChefSpec.define_matcher :node_install
  def install_node_install(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:node_install, :install, resource_name)
  end
  ChefSpec.define_matcher :node_execute
  def run_node_execute(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:node_execute, :run, resource_name)
  end

  ChefSpec.define_matcher :ruby_install
  def install_ruby_install(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ruby_install, :install, resource_name)
  end
  ChefSpec.define_matcher :ruby_execute
  def run_ruby_execute(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ruby_execute, :run, resource_name)
  end

  ChefSpec.define_matcher :rust_install
  def install_rust_install(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:rust_install, :install, resource_name)
  end
  ChefSpec.define_matcher :rust_execute
  def run_rust_execute(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:rust_execute, :run, resource_name)
  end
end
