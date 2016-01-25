WHAT?
====================

- Run the test/spec your cursor is currently on
- Run the context your cursor is currently in
- Run the entire test/spec you are working in
- Streaming output to tmux via vimux

This plugin currently supports
  - test/unit
  - dust
  - rspec
  - shoulda

HOW?
====================

Use any of the commands below. Map them to shortcuts
in your .vimrc for easy access.

  - RunRubyFocusedTest - run focused test/spec
  - RunRailsFocusedTest - run focused test (no spec support) in a Rails app
  - RunRubyFocusedContext - run current context (rspec, shoulda)
  - RunAllRubyTests - run all the tests/specs in the current file

You can also use the following settings in .vimrc to configure the command used to run ruby tests:

```vim
let g:vimux_ruby_cmd_unit_test = "bundle exec ruby"
let g:vimux_ruby_cmd_all_tests = "testdrb"
let g:vimux_ruby_cmd_context = "FOO=bar ruby"
```

By default, vim-ruby-test clears the tmux pane in which the command is run. You can configure
this behavior:

```vim
let g:vimux_ruby_clear_console_on_run = 0
```

By default, vim-ruby-test uses the absolute path for file arguments. You can configure it to instead use relative paths with:

```vim
let g:vimux_ruby_file_relative_paths = 1
```

INSTALL
====================

Put the contents of this directory into your pathogen bundle. That's it!

REQUIREMENTS
====================

- vim with ruby support (compiled +ruby)
- [vimux](https://github.com/benmills/vimux) >= 0.3.0

CONTRIBUTORS:
====================

- [Drew Olson](https://github.com/drewolson)
- [Paul Gross](https://github.com/pgr0ss)
- [Kendall Buchanan](https://github.com/kendagriff)
- [Thomas Mayfield](https://github.com/thegreatape)
