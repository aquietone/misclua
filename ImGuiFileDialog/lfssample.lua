local mq = require 'mq'
require 'ImGui'

local filedialog = require('imguifiledialog')

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true
local terminate = false

--local open_file_dialog = false
-- ImGui main function for rendering the UI window
local ifdsample = function()
    openGUI, shouldDrawGUI = ImGui.Begin('ImGuiFileDialog Sample', openGUI)
    if shouldDrawGUI then
        if ImGui.Button('Select file...') then
            filedialog.set_file_selector_open(true)
        end
        if filedialog.is_file_selector_open() then
            filedialog.draw_file_selector(mq.configDir, '.ini')
        end
        if not filedialog.is_file_selector_open() and filedialog.get_filename() ~= '' then
            ImGui.Text('Selected file: '..filedialog.get_filename())
        end
    end
    ImGui.End()
    if not openGUI then
        terminate = true
    end
end

mq.imgui.init('ifdsample', ifdsample)

while not terminate do
    mq.delay(1000)
end
