local helpers = require('test.functional.helpers')(after_each)
local Screen = require('test.functional.ui.screen')

local clear, feed, insert = helpers.clear, helpers.feed, helpers.insert
local command = helpers.command
local retry = helpers.retry

describe('ui mode_change event', function()
  local screen

  before_each(function()
    clear()
    screen = Screen.new(25, 4)
    screen:attach({rgb= true})
    screen:set_default_attr_ids( {
      [0] = {bold=true, foreground=255},
      [1] = {bold=true, reverse=true},
      [2] = {bold=true},
      [3] = {reverse=true},
      [4] = {background=Screen.colors.Red, foreground=Screen.colors.White},  -- ErrorMsg
    })
  end)

  it('works in normal mode', function()
    screen:expect{grid=[[
      ^                         |
      {0:~                        }|*2
                               |
    ]], mode="normal"}

    feed('d')
    screen:expect{grid=[[
      ^                         |
      {0:~                        }|*2
                               |
    ]], mode="operator"}

    feed('<esc>')
    screen:expect{grid=[[
      ^                         |
      {0:~                        }|*2
                               |
    ]], mode="normal"}
  end)

  -- oldtest: Test_mouse_shape_after_failed_change()
  it('is restored to Normal mode after failed "c"', function()
    screen:try_resize(50, 4)
    command('set nomodifiable')

    feed('c')
    screen:expect{grid=[[
      ^                                                  |
      {0:~                                                 }|*2
                                                        |
    ]], mode="operator"}

    feed('c')
    screen:expect{grid=[[
      ^                                                  |
      {0:~                                                 }|*2
      {4:E21: Cannot make changes, 'modifiable' is off}     |
    ]], mode="normal"}
  end)

  -- oldtest: Test_mouse_shape_after_cancelling_gr()
  it('is restored to Normal mode after cancelling "gr"', function()
    feed('gr')
    screen:expect{grid=[[
      ^                         |
      {0:~                        }|*2
                               |
    ]], mode="replace"}

    feed('<Esc>')
    screen:expect{grid=[[
      ^                         |
      {0:~                        }|*2
                               |
    ]], mode="normal"}
  end)

  it('works in insert mode', function()
    feed('i')
    screen:expect{grid=[[
      ^                         |
      {0:~                        }|*2
      {2:-- INSERT --}             |
    ]], mode="insert"}

    feed('word<esc>')
    screen:expect{grid=[[
      wor^d                     |
      {0:~                        }|*2
                               |
    ]], mode="normal"}

    local matchtime = 0
    command("set showmatch")
    retry(nil, nil, function()
      matchtime = matchtime + 1
      local screen_timeout = 1000 * matchtime  -- fail faster for retry.

      command("set matchtime=" .. matchtime) -- tenths of seconds
      feed('a(stuff')
      screen:expect{grid=[[
        word(stuff^               |
        {0:~                        }|*2
        {2:-- INSERT --}             |
      ]], mode="insert", timeout=screen_timeout}

      feed(')')
      screen:expect{grid=[[
        word^(stuff)              |
        {0:~                        }|*2
        {2:-- INSERT --}             |
      ]], mode="showmatch", timeout=screen_timeout}

      screen:expect{grid=[[
        word(stuff)^              |
        {0:~                        }|*2
        {2:-- INSERT --}             |
      ]], mode="insert", timeout=screen_timeout}
    end)
  end)

  it('works in replace mode', function()
    feed('R')
    screen:expect{grid=[[
      ^                         |
      {0:~                        }|*2
      {2:-- REPLACE --}            |
    ]], mode="replace"}

    feed('word<esc>')
    screen:expect{grid=[[
      wor^d                     |
      {0:~                        }|*2
                               |
    ]], mode="normal"}
  end)

  it('works in cmdline mode', function()
    feed(':')
    screen:expect{grid=[[
                               |
      {0:~                        }|*2
      :^                        |
    ]], mode="cmdline_normal"}

    feed('x<left>')
    screen:expect{grid=[[
                               |
      {0:~                        }|*2
      :^x                       |
    ]], mode="cmdline_insert"}

    feed('<insert>')
    screen:expect{grid=[[
                               |
      {0:~                        }|*2
      :^x                       |
    ]], mode="cmdline_replace"}


    feed('<right>')
    screen:expect{grid=[[
                               |
      {0:~                        }|*2
      :x^                       |
    ]], mode="cmdline_normal"}

    feed('<esc>')
    screen:expect{grid=[[
      ^                         |
      {0:~                        }|*2
                               |
    ]], mode="normal"}
  end)

  it('works in visual mode', function()
    insert("text")
    feed('v')
    screen:expect{grid=[[
      tex^t                     |
      {0:~                        }|*2
      {2:-- VISUAL --}             |
    ]], mode="visual"}

    feed('<esc>')
    screen:expect{grid=[[
      tex^t                     |
      {0:~                        }|*2
                               |
    ]], mode="normal"}

    command('set selection=exclusive')
    feed('v')
    screen:expect{grid=[[
      tex^t                     |
      {0:~                        }|*2
      {2:-- VISUAL --}             |
    ]], mode="visual_select"}

    feed('<esc>')
    screen:expect{grid=[[
      tex^t                     |
      {0:~                        }|*2
                               |
    ]], mode="normal"}
  end)
end)

