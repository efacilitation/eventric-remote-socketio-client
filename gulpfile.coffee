gulp = require 'gulp'
runSequence = require 'run-sequence'

gulp.on 'err', (error) ->
gulp.on 'task_err', (error) ->
  if process.env.CI
    gutil.log error
    process.exit 1

gulp.task 'watch', ->
  gulp.watch [
    'src/*.coffee'
  ], ->
   runSequence 'build', 'specs'


require('./gulp/build')(gulp)
require('./gulp/specs')(gulp)