print('>> Running log test...')
log.print('Running log test. Time: ' .. tostring(os.time()))
log.createLogFile('test','log_test.lua/test.log')
log.print('Running log test on auxilliary log. Time: ' .. tostring(os.time()),'test')
print('>> Log test is complete. Check /MWP/sys/log.')