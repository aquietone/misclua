local mq = require 'mq'
require 'ImGui'

-- Import the file dialog
local filedialog = require('imguifiledialog')

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true

-- ImGui main function for rendering the UI window
local ifdsample = function()
    openGUI, shouldDrawGUI = ImGui.Begin('ImGuiFileDialog Sample', openGUI)
    if shouldDrawGUI then
        -- open the file picker dialog
        if ImGui.Button('Select file...') then
            filedialog.set_file_selector_open(true)
        end
        -- draw the file picker dialog if it is open
        if filedialog.is_file_selector_open() then
            filedialog.draw_file_selector(mq.configDir, '.ini')
        end
        -- if file dialog window is closed, and filename is set, a file was selected
        if not filedialog.is_file_selector_open() and filedialog.get_filename() ~= '' then
            ImGui.Text('Selected file: '..filedialog.get_filename())
        end
    end
    ImGui.End()
end

mq.imgui.init('ifdsample', ifdsample)

while openGUI do
    mq.delay(1000)
end
