gutil    = require 'gulp-util'
grep     = require 'gulp-grep-stream'
watch    = require 'gulp-watch'
commonjs = require 'gulp-wrap-commonjs'


module.exports = (gulp) ->

  gulp.task 'watch', ->
    gulp.src("src/*.coffee",
      read: false
    ).pipe watch(
      emit: "all"
    , (files) ->
      files
        .pipe(grep("**/*.spec.*"))
        .pipe(mocha(reporter: "spec")
          .on "error", (err) ->
            console.log err.stack  unless /tests? failed/.test(err.stack)
            return
        )
      return
    )
    return