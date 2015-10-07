'use strict'

path = require('path')
assert = require('yeoman-generator').assert
helpers = require('yeoman-generator').test
os = require('os')

describe 'gradle-kotlin:app', ->
  before (done) ->
    helpers.run(path.join(__dirname, '../generators/app'))
      .withOptions(skipInstall: true)
      .on('end', done)

  it 'creates Gradle files', ->
    assert.file [
      'build.gradle'
      'settings.gradle'
      'gradle.properties'
    ]

  it "creates 'src' and the subdirs", ->
    assert.file [
      'src/main/kotlin/.gitkeep'
      'src/test/kotlin/.gitkeep'
    ]
