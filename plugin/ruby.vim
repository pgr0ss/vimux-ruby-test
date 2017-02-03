if exists("g:loaded_vimux_ruby_test") || &cp
  finish
endif
let g:loaded_vimux_ruby_test = 1

if !has("ruby")
  finish
end

if !exists("g:vimux_ruby_cmd_unit_test")
  let g:vimux_ruby_cmd_unit_test = "ruby"
endif
if !exists("g:vimux_ruby_cmd_all_tests")
  let g:vimux_ruby_cmd_all_tests = "ruby"
endif
if !exists("g:vimux_ruby_cmd_context")
  let g:vimux_ruby_cmd_context = "ruby"
endif
if !exists("g:vimux_ruby_clear_console_on_run")
  let g:vimux_ruby_clear_console_on_run = 1
endif
if !exists("g:vimux_ruby_file_relative_paths")
  let g:vimux_ruby_file_relative_paths = 0
endif

command RunAllRubyTests :call s:RunAllRubyTests()
command RunAllRailsTests :call s:RunAllRailsTests()
command RunRubyFocusedTest :call s:RunRubyFocusedTest()
command RunRailsFocusedTest :call s:RunRailsFocusedTest()
command RunRubyFocusedContext :call s:RunRubyFocusedContext()

function s:RunAllRubyTests()
  ruby RubyTest.create_from_settings.run_all
endfunction

function s:RunAllRailsTests()
  ruby RubyTest.create_from_settings.run_all(true)
endfunction

function s:RunRubyFocusedTest()
  ruby RubyTest.create_from_settings.run_test
endfunction

function s:RunRailsFocusedTest()
  ruby RubyTest.create_from_settings.run_test(true)
endfunction

function s:RunRubyFocusedContext()
  ruby RubyTest.create_from_settings.run_context
endfunction

ruby << EOF
module VIM
  class Buffer
    def method_missing(method, *args, &block)
      VIM.command "#{method} #{self.name}"
    end
  end
end

class RubyTest
  RSPEC_VERSION_REGEX = /(\d+\.\d+\.\d+)/

  attr_reader :ruby_command
  attr_reader :use_relative_path

  def self.create_from_settings
    self.new(Vim.evaluate('g:vimux_ruby_cmd_all_tests'), Vim.evaluate('g:vimux_ruby_file_relative_paths'))
  end

  def initialize(ruby_command, use_relative_path)
    @ruby_command = ruby_command
    @use_relative_path = use_relative_path
  end

  def current_file
    use_relative_path == 0 ? VIM::Buffer.current.name : Vim.evaluate('expand("%")')
  end

  def rails_test_dir
    current_file.split('/')[0..-current_file.split('/').reverse.index('test')-1].join('/')
  end

  def spec_file?
    current_file =~ /spec_|_spec/
  end

  def line_number
    VIM::Buffer.current.line_number
  end

  def run_spec
    send_to_vimux("#{spec_command} #{current_file}:#{line_number}")
  end

  def run_unit_test(rails=false)
    method_name = nil

    (line_number + 1).downto(1) do |line_number|
      if VIM::Buffer.current[line_number] =~ /def (test_\w+)/
        method_name = $1
        break
      elsif VIM::Buffer.current[line_number] =~ /test "([^"]+)"/ ||
            VIM::Buffer.current[line_number] =~ /test '([^']+)'/
        method_name = "test_" + $1.split(" ").join("_")
        break
      elsif VIM::Buffer.current[line_number] =~ /should "([^"]+)"/ ||
            VIM::Buffer.current[line_number] =~ /should '([^']+)'/
        method_name = "\"/#{Regexp.escape($1)}/\""
        break
      end
    end

    send_to_vimux("#{ruby_command} #{"-I #{rails_test_dir} " if rails}#{current_file} -n #{method_name}") if method_name
  end

  def run_test(rails=false)
    if spec_file?
      run_spec
    else
      run_unit_test(rails)
    end
  end

  def run_context
    method_name = nil
    context_line_number = nil

    (line_number + 1).downto(1) do |line_number|
      if VIM::Buffer.current[line_number] =~ /(context|describe) "([^"]+)"/ ||
         VIM::Buffer.current[line_number] =~ /(context|describe) '([^']+)'/
        method_name = $2
        context_line_number = line_number
        break
      end
    end

    if method_name
      if spec_file?
        send_to_vimux("#{spec_command} #{current_file}:#{context_line_number}")
      else
        method_name = Regexp.escape(method_name)
        send_to_vimux("#{ruby_command} #{current_file} -n /'#{method_name}'/")
      end
    end
  end

  def run_all(rails=false)
    if spec_file?
      send_to_vimux("#{spec_command} '#{current_file}'")
    else
      send_to_vimux("#{ruby_command} #{"-I #{rails_test_dir} " if rails}#{current_file}")
    end
  end

  def spec_command
    if File.exists?('./.zeus.sock')
      'zeus rspec'
    elsif File.exists?('./bin/rspec')
      './bin/rspec'
    elsif File.exists?("Gemfile.lock") && rspec_version = get_locked_rspec_version
      rspec_version.to_f < 2 ? "bundle exec spec" : "bundle exec rspec"
    elsif File.exists?("Gemfile") && (match = `bundle show rspec-core`.scan(RSPEC_VERSION_REGEX) || match = `bundle show rspec`.scan(RSPEC_VERSION_REGEX))
      match.flatten.last.to_f < 2 ? "bundle exec spec" : "bundle exec rspec"
    else
      system("rspec -v > /dev/null 2>&1") ? "rspec --no-color" : "spec"
    end
  end

  def send_to_vimux(test_command)
    cmd = if VIM::evaluate("g:vimux_ruby_clear_console_on_run") != 0
      "clear && "
    else
      ''
    end
    cmd += test_command
    Vim.command("call VimuxRunCommand(\"#{cmd}\")")
  end

  private

  def get_locked_rspec_version
    matches = get_locked_gem_version('rspec-core').scan(RSPEC_VERSION_REGEX) || get_locked_gem_version('rspec').scan(RSPEC_VERSION_REGEX)
    matches.flatten.last
  end

  def get_locked_gem_version(gem_name)
    `cat Gemfile.lock | grep '#{gem_name} (' | grep -v '[~,<,>,=]' | awk -F'[()]' '{print $2}'`
  end
end
EOF
