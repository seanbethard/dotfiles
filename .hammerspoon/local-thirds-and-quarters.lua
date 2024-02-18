local windowSizes = {2, 3, 3/2}
local pressed = {
  up = false,
  down = false,
  left = false,
  right = false
}
local GRID = {w = 24, h = 24}
hs.grid.setGrid(GRID.w .. 'x' .. GRID.h)
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

-- step through window sizes

hs.hotkey.bind(hyper_uppercut, "up", function ()
  pressed.up = true
  if pressed.down then 
      windowDimension('h')
  else
    stepWindow('h', false, function (cell, nextSize)
      cell.y = 0
      cell.h = GRID.h / nextSize
    end)
  end
end, function () 
  pressed.up = false
end)

hs.hotkey.bind(hyper_uppercut, "down", function ()
  pressed.down = true
  if pressed.up then 
    windowDimension('h')
  else
    stepWindow('h', true, function (cell, nextSize)
      cell.y = GRID.h - GRID.h / nextSize
      cell.h = GRID.h / nextSize
    end)
  end
end, function () 
  pressed.down = false
end)

hs.hotkey.bind(hyper_uppercut, "right", function ()
  pressed.right = true
  if pressed.left then 
    windowDimension('w')
  else
    stepWindow('w', true, function (cell, nextSize)
      cell.x = GRID.w - GRID.w / nextSize
      cell.w = GRID.w / nextSize
    end)
  end
end, function () 
  pressed.right = false
end)

hs.hotkey.bind(hyper_uppercut, "left", function ()
  pressed.left = true
  if pressed.right then 
    windowDimension('w')
  else
    stepWindow('w', false, function (cell, nextSize)
      cell.x = 0
      cell.w = GRID.w / nextSize
    end)
  end
end, function () 
  pressed.left = false
end)

function windowDimension(dim)
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()
    cell = hs.grid.get(win, screen)
    if (dim == 'x') then
      cell = '0,0 ' .. GRID.w .. 'x' .. GRID.h
    else  
      cell[dim] = GRID[dim]
      cell[dim == 'w' and 'x' or 'y'] = 0
    end
    hs.grid.set(win, cell, screen)
  end
end

function stepWindow(dim, offs, cb)
  if hs.window.focusedWindow() then
    local axis = dim == 'w' and 'x' or 'y'
    local oppDim = dim == 'w' and 'h' or 'w'
    local oppAxis = dim == 'w' and 'y' or 'x'
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()
    local nextSize = windowSizes[1]
    cell = hs.grid.get(win, screen)
    for i=1,#windowSizes do
      if cell[dim] == GRID[dim] / windowSizes[i] and
        (cell[axis] + (offs and cell[dim] or 0)) == (offs and GRID[dim] or 0)
        then
          nextSize = windowSizes[(i % #windowSizes) + 1]
        break
      end
    end
    cb(cell, nextSize)
    if cell[oppAxis] ~= 0 and cell[oppAxis] + cell[oppDim] ~= GRID[oppDim] then
      cell[oppDim] = GRID[oppDim]
      cell[oppAxis] = 0
    end
    hs.grid.set(win, cell, screen)
  end
end
