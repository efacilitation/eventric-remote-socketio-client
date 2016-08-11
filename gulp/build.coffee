runSequence = require 'run-sequence'
webpack = require 'webpack-stream'

module.exports = (gulp) ->

  gulp.task 'build', (done) ->
    runSequence 'build:release', done


  gulp.task 'build:release', ->
    webpackConfig = require('./webpack_config').getDefaultConfiguration()
    webpackConfig.output =
      libraryTarget: 'umd'
      library: 'eventric-remote-socketio-client'
      filename: 'eventric_remote_socketio_client.js'

    gulp.src ['src/client.coffee']
    .pipe webpack webpackConfig
    .pipe gulp.dest 'dist/release'
