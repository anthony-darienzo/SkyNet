print('Advancing to module loading...')
local tasklib = module.require('/MWP/lib/yielding')
print('Loading the movement library now')
local movelib = module.require('/MWP/lib/movement')

print('Creating tasks...')
local testTask1 = tasklib.Task:new {
    name = 'Test1',
    procedure = function()
        print('Entered task1 ...')
        print(thisTask.name)

        promise = thisTask:requestPromise {
            questionData = {
                exampleDatum = 'potato'
            },
            kind = 'example_promise'
        }

        thisTask:yieldUntilResolved {promise}

        if promise:resolved() then
            print('Promise is resolved!')
        else
            print('Promise is NOT resolved!')
        end
        answer = promise.answerData
        promise.dataWasAccessed = true
        print(answer.exampleAnswer)

        print('Waiting for a key press [f]')
        repeat
            local event, key = os.pullEvent('key')
        until key == keys.f

        promise2 = thisTask:requestPromise {
            questionData = {
                exampleDatum = 'kiwi'
            },
            kind = 'example_promise'
        }

        promise3 = thisTask:requestPromise {
            questionData = {
                exampleDatum = 'mango'
            },
            kind = 'example2_promise'
        }

        thisTask:yieldUntilResolved {promise2,promise3}

        print('Promise2 is resolved!')
        answer = promise2.answerData
        promise2.dataWasAccessed = true
        print(answer.exampleAnswer)

        print('Promise3 is resolved!')
        answer = promise3.answerData
        promise3.dataWasAccessed = true
        print(answer.exampleAnswer)

        print('Waiting for a key press [e]')
        repeat
            local event, key = os.pullEvent('key')
            print(' ------> Received event ' .. event)
        until key == keys.e
        print('Done waiting')


        local response = vector.new(gps.locate())
        local original_location = movelib.Waypoint:new('Home', response)
        print('Just resumed from yield. Received: ' .. response:tostring())

        movelib.move.goTo(response + vector.new(0,10,0))
        local dest = movelib.Waypoint:new('Dest', vector.new(gps.locate()))

        original_location:go()
        dest:go()

        movelib.Waypoint.previous_location:go()

        return thisTask:terminate("We're done buddy.")
    end
}

local testTask2 = tasklib.Task:new {
    name = 'Test2',
    registeredOutcome = 'example_promise',
    procedure = function()
        while true do
            print('Entered task2 ...')
            promisesToResolve = thisTask:findPromisesToResolve()

            for _,promise in pairs(promisesToResolve) do
                promise.answerData = {
                    exampleAnswer = 'Answered ' .. promise.questionData.exampleDatum
                }
                promise:resolve()
            end

            print('Resolved the promises')
            thisTask:unqueueFromTaskSequence()
            thisTask:yield()
        end
    end
}

local testTask3 = tasklib.Task:new {
    name = 'Test3',
    registeredOutcome = 'example2_promise',
    procedure = function()
        while true do
            print('Entered task3 ...')
            promisesToResolve = thisTask:findPromisesToResolve()

            for _,promise in pairs(promisesToResolve) do
                promise.answerData = {
                    exampleAnswer = 'Also answered ' .. promise.questionData.exampleDatum
                }
                promise:resolve()
            end

            print('Resolved the promises')
            thisTask:unqueueFromTaskSequence()
            thisTask:yield()
        end
    end
}

print('Generating the legacy event handler now')
local test_os_task = tasklib.LegacyEventHandler:new()

local testTaskSequence = tasklib.TaskSequence:new {
    name = 'TestTaskSequence'
}

local otherTaskSequence = tasklib.TaskSequence:new {
    name = 'OtherTaskSequence'
}

print('Registering to taskSequences...')
testTask2:registerToTaskSequence(testTaskSequence)
testTaskSequence:registerToRegisteredTasks(testTask2)
otherTaskSequence:registerToRegisteredTasks(test_os_task)
otherTaskSequence:registerToRegisteredTasks(testTask3)

testTaskSequence:queueTask(testTask1)

otherTaskSequence:queueTask(testTaskSequence)

print('Preparing to run')
repeat
    status = otherTaskSequence:run()
until not otherTaskSequence.enabled