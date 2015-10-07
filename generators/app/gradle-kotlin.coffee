'use strict'
yeoman = require('yeoman-generator')
chalk = require('chalk')
yosay = require('yosay')
os = require('os')
Promise = require('promise')
request = Promise.denodeify(require('request'))
exec = Promise.denodeify(require('child_process').exec)

DEFAULT_GRADLE_VERSION = '2.7'
DEFAULT_KOTLIN_VERSION = '0.14.451'
MVNCNTRL_KOTLIN_SEARCH = 'http://search.maven.org/solrsearch/select?q=g:org.jetbrains.kotlin%20AND%20a:kotlin-stdlib&wt=json'

class GradleKotlinGenerator extends yeoman.generators.Base
  constructor: (args, options, config) ->
    super(args, options, config)

  prompts: [{
    type: 'input',
    name: 'gradleVersion',
    message: 'What Gradle version would you like to use?'
  }, {
    type: 'input',
    name: 'kotlinVersion',
    message: 'What Kotlin version would you like to use?'
  }, {
    type: 'input',
    name: 'projectName',
    message: "What's your project name?"
  }, {
    type: 'confirm',
    name: 'ideaPlugin',
    message: 'Would you like to use IDEA Gradle plugin?',
    default: true
  }]

  initializing: ->
    @log yosay "Welcome to the incredible #{chalk.bgGreen 'Gradle'}+#{chalk.bgBlue 'Kotlin'} generator!"

    done = @async()
    defaultValues = [@_fetchGradleVersion(), @_fetchKotlinVersion(), @appname]
    Promise.all(defaultValues).then (defaultValues) =>
      @prompts[i].default = defaultValue for defaultValue, i in defaultValues
      done()


  prompting: ->
    done = @async()
    @prompt @prompts, (props) =>
      @props = props
      done()

  writing:
    app: ->
      @fs.copy(@templatePath('gitignore'), @destinationPath('.gitignore'))
      @fs.copy(@templatePath('gitkeep'), @destinationPath('src/main/kotlin/.gitkeep'))
      @fs.copy(@templatePath('gitkeep'), @destinationPath('src/test/kotlin/.gitkeep'))
      @template(@templatePath('build.gradle.ejs'), @destinationPath('build.gradle'))
      @template(@templatePath('gradle.properties.ejs'), @destinationPath('gradle.properties'))
      @template(@templatePath('settings.gradle.ejs'), @destinationPath('settings.gradle'))

  install: ->
    return if @gradleNotInstalled
    done = @async()

    gradlewCommand = "./gradlew#{if @_isWindows() then '.bat' else ''}"

    @log chalk.gray "  Executing 'gradle wrapper' command..."
    @spawnCommand('gradle', ['wrapper'], {stdio: 'ignore'}).on 'exit', =>
      @log.ok chalk.green "Done executing 'gradle wrapper' command."

      gradleTasks = ['build']
      gradleTasks.unshift('idea') if @props.ideaPlugin

      @log chalk.gray "  Executing Gradle tasks: #{gradleTasks.join(' ')}"
      @spawnCommand(gradlewCommand, gradleTasks, {stdio: 'ignore'}).on 'exit', =>
        @log.ok chalk.green "Done executing Gradle tasks: #{gradleTasks.join(' ')}"
        done()

  _isWindows: ->
    os.platform().toLowerCase().indexOf('win') > -1

  _fetchGradleVersion: =>
    @log chalk.gray '  Detecting installed Gradle version...'

    exec('gradle --version')
      .then (stdout) =>
        gradleVersion = stdout.match(/^Gradle (\d+\.\d+)$/m)[1]
        @log.ok chalk.green "Detected installed Gradle version: #{gradleVersion}"
        Promise.resolve(gradleVersion)
      .catch =>
        @gradleNotInstalled = true
        @log.error chalk.bgRed 'Could not detect Gradle installation. Please check the PATH variable.'
        Promise.resolve(DEFAULT_GRADLE_VERSION)

  _fetchKotlinVersion: =>
    @log chalk.gray '  Fetching latest Kotlin version from Maven Central...'

    request(MVNCNTRL_KOTLIN_SEARCH)
      .then (response) =>
        kotlinVersion = JSON.parse(response.body).response.docs[0].latestVersion
        @log.ok chalk.green "Fetched latest Kotlin version: #{kotlinVersion}"
        Promise.resolve(kotlinVersion)
      .catch =>
        @log.error chalk.bgRed 'Could not fetch latest Kotlin version from Maven Central.'
        Promise.resolve(DEFAULT_KOTLIN_VERSION)

module.exports = GradleKotlinGenerator
