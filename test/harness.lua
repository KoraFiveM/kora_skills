local Harness = { failures = 0 }

function Harness.test(name, fn)
    local ok, err = pcall(fn)
    if ok then print('ok - ' .. name) else
        Harness.failures = Harness.failures + 1
        print('not ok - ' .. name .. ': ' .. tostring(err))
    end
end

function Harness.equal(actual, expected, message)
    if actual ~= expected then error((message or 'values differ') .. (': expected %s, got %s'):format(tostring(expected), tostring(actual)), 2) end
end

function Harness.truthy(value, message)
    if not value then error(message or 'expected truthy value', 2) end
end

return Harness
