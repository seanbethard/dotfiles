local focusedSizes = {1,2,3,4,5}
local GRID = {w = 24, h = 24}
hs.grid.setGrid(GRID.w .. 'x' .. GRID.h)
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

-- step through focused window sizes

hs.hotkey.bind(hyper, "return", function ()
  stepFocused()
end)

function stepFocused()
  if hs.window.focusedWindow() then
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local screen = win:screen()
    local nextSize = focusedSizes[1]
    cell = hs.grid.get(win, screen)
    for i=1,#focusedSizes do
      if cell.w == GRID.w / focusedSizes[i] and 
         cell.h == GRID.h / focusedSizes[i] and
         cell.x == (GRID.w - GRID.w / focusedSizes[i]) / 2 and
         cell.y == (GRID.h - GRID.h / focusedSizes[i]) / 2 then
        nextSize = focusedSizes[(i % #focusedSizes) + 1]
        break
      end
    end
    cell.w = GRID.w / nextSize
    cell.h = GRID.h / nextSize
    cell.x = (GRID.w - GRID.w / nextSize) / 2
    cell.y = (GRID.h - GRID.h / nextSize) / 2
    hs.grid.set(win, cell, screen)
  end
end
