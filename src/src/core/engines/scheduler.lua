--[[
  Task scheduler module
  Manages asynchronous task execution in FIFO queue order.
  Ensures tasks complete before the next one starts, with error recovery.
]]

local TAG = "Scheduler"
local scheduler = {}

---@type table Queue of pending tasks
local queue = {}
---@type boolean True if a task is currently being processed
local is_processing = false

---Adds a task function to the queue.
---The task receives a finish_task callback that it must call to complete execution.
---@param task_func fun(finish_task: fun()) The task function to queue
---@return nil
function scheduler:add(task_func)
    table.insert(queue, task_func)
    LOG.dbg(TAG, "Task queued. Queue size: " .. tostring(#queue))
    if not is_processing then
        self:_next()
    end
end

---Processes the next task in the queue.
---Automatically called recursively until queue is empty.
---Handles task errors gracefully by logging and continuing.
---@return nil
function scheduler:_next()
    if #queue == 0 then
        is_processing = false
        LOG.dbg(TAG, "Queue empty. Scheduler idle.")
        return
    end

    is_processing = true
    local current_task = table.remove(queue, 1)
    LOG.dbg(TAG, "Starting task. Remaining in queue: " .. tostring(#queue))

    local tb
    local ok, err = xpcall(function()
        current_task(function()
            scheduler:_next()
        end)
    end, function(e)
        tb = (debug and debug.traceback) and debug.traceback(tostring(e), 2) or tostring(e)
        return e
    end)

    if not ok then
        -- Capture with traceback for the Console tab; fall back to a plain log
        -- if the crash handler hasn't loaded yet.
        if CrashHandler then
            CrashHandler.capture(TAG, err, tb)
        else
            LOG.error(TAG, "Task crashed: " .. tostring(err))
        end
        gg.alert(T("scheduler.task_crashed", tostring(err)))
        self:_next()
    end
end

---Gets the number of pending tasks in the queue.
---@return number Number of tasks waiting to be processed
function scheduler:get_queue_count()
    return #queue
end

---Checks if a task is currently being processed.
---@return boolean True if processing, false otherwise
function scheduler:is_processing()
    return is_processing
end

return scheduler
