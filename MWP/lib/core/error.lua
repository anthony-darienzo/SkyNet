Exception = Class {
    constructor = function(self,message,ex_type)
        -- The default type of Exception is a generic Exception
        ex_type = ex_type or 'Exception'

        assert(type(message) == 'string', 'The message of an Exception must be a string!')
        assert(type(ex_type) == 'string', 'The type of an Exception must be a string!')

        -- We parse together a formatted string since the built-in error function only supports strings.
        local exceptionData = '[BEGIN ERROR TYPE]' .. ex_type .. '[BEGIN ERROR MESSAGE]' .. message

        local obj = {
            data = exceptionData,
            message = message,
            type = ex_type,
            traceback = {}
        }

        return obj
    end,

    metatable = {
        __tostring = function(self)
            return self:serialize(false)
        end
    },

    serialize = function(self,human_readable)

        local serializeTraceback = function(line_prefix)
            line_prefix = line_prefix or ''
            local traceback = self.traceback
            local traceback_string = ''
            for _,level in ipairs(traceback) do
                local s = line_prefix .. level.file .. ':' .. level.line .. ': '
                traceback_string = traceback_string .. s
            end
            return traceback_string
        end

        if human_readable then
            local traceback_string = serializeTraceback('\n')
            return traceback_string .. '\n' .. self.type .. ': ' .. self.message
        else
            local traceback_string = serializeTraceback()
            return traceback_string .. self.data
        end
    end,

    string = function(self)
        return self:serialize(true)
    end,

    unserialize = function(self,s)
        -- Takes a string and returns an Exception with the corresponding metadata. If the string is not formatted, return a new Exception.

        -- Check if string is formatted by seeing if it has the [BEGIN ERROR TYPE] and [BEGIN ERROR MESSAGE] tags:

        if string.find(s,'[BEGIN ERROR TYPE]',1,true) and string.find(s,'[BEGIN ERROR MESSAGE]',1,true) then

            local tb_data = nym.split(s,'%[BEGIN ERROR TYPE%]')
            local traceback_string,data = tb_data[1],tb_data[2]

            local ex_type_message = nym.split(data,'%[BEGIN ERROR MESSAGE%]')
            local ex_type,message = ex_type_message[1],ex_type_message[2]

            local e = self:new(message,ex_type)

            local unserializeTraceback = function()
                local traceback_arr = nym.split(traceback_string,':')
                -- Collapse any empty entries:
                for i,v in ipairs(traceback_arr) do
                    if not v or v == ' ' then
                        table.remove(traceback_arr,i)
                    end
                end
                local traceback = {}
                for i=1,#traceback_arr,2 do -- Since the splitString will split the traceback_string into both
                    local _file = traceback_arr[i]
                    local _line = traceback_arr[i+1]
                    -- line numbers and files, we have to count every second index.
                    local data = {file = _file, line = _line}
                    table.insert(traceback,data) -- We have to insert the element to the end of the array.
                end
                return traceback
            end

            e.traceback = unserializeTraceback()
            return e
        else
            -- The string is not formatted, so we create a generic Exception:
            return Exception:new(s)
        end
    end,

    throw = function(self,layer)
        layer = layer or 2
        error(self:serialize(),layer)
    end
}

function try(block,catch,finally,...)
    -- Tries to run block. If there is an error, pass it to catch. At the end, call finally.
    -- Will pass vararg to block, if there is an exception, will return what is returned by
    -- catch.

    if not catch then
        catch = function(...) return ... end
    end

    if not finally then
        finally = function() end
    end

    assert(type(block) == 'function','Function try requires function arguments!')
    assert(type(catch) == 'function','Function try requires function arguments!')
    assert(type(finally) == 'function','Function try requires function arguments!')

    local ok, returned_data = pcall(block,...)
    if ok then
        return returned_data
    else
        -- In this case, returned_data is the Exception we caught.

        local ex = Exception:unserialize(returned_data)
        local ok, return_caught = pcall(catch,ex)
        if ok then
            finally()
            return return_caught
        else
            -- In this case, return_caught is an Exception
            local ex = Exception:unserialize(return_caught)
            finally()
            ex:throw(3)
        end
    end
end
