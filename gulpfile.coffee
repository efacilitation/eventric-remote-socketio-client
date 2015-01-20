gulp = require 'gulp'
runSequence = require 'run-sequence'

gulp.on 'err', (e) ->
gulp.on 'task_err', (e) ->
  if process.env.CI
    gutil.log e
    process.exit 1

gulp.task 'watch', ->
  gulp.watch [
    'src/*.coffee'
  ], ->
   runSequence 'build', 'spec'


require('./gulp/build')(gulp)
require('./gulp/spec')(gulp)
require('./gulp/bump')(gulp)