module.exports = (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'
        project:
            source: 'src/webapp'
            transient: 'target/.generated'
            distribution: 'target/release_build'
            target: 'target'
        clean:
            target: '<%= project.target %>'
        coffee:
            compile:
                options:
                    sourceMap: true
                files: [
                    expand: true,
                    cwd: '<%= project.source %>/scripts',
                    src: ['**/*.coffee'],
                    dest: '<%= project.transient %>/scripts'
                    rename: (dest, filename) ->
                        return "#{dest}/#{filename.substring(0, filename.lastIndexOf('.'))}.js"
                ]
        coffeelint:
            options:
                indentation:
                    value: 4
                max_line_length:
                    value: 120
                line_endings:
                    value: 'unix'
            everything: ['gruntfile.coffee', '<%= project.source %>/scripts/*.coffee']
        stylus:
            compile:
                options:
                    compress: false
                files: [
                    expand: true,
                    cwd: '<%= project.source %>/stylesheets',
                    src: ['**/*.styl'],
                    dest: '<%= project.transient %>/stylesheets'
                    rename: (dest, filename) ->
                        return "#{dest}/#{filename.substring(0, filename.lastIndexOf('.'))}.css"
                ]
        jade:
            index:
                options:
                    pretty: true
                    data:
                        debug: false
                files:
                    '<%= project.transient %>/index.html': '<%= project.source %>/index.jade'
            jst:
                options:
                    client: true
                    compileDebug: false
                    processName: (filename) ->
                        return filename.substring(filename.lastIndexOf('/') + 1, filename.lastIndexOf('.'))
                files:
                    '<%= project.transient %>/scripts/jst.js': '<%= project.source %>/templates/*.jade'
        manifest:
            options:
                cache: [
                    'index.html'
                    'favicon.ico'
                    'thirdparty/jquery/jquery.js'
                    'thirdparty/jquery-tipsy/jquery.tipsy.js'
                    'thirdparty/microplugin/microplugin.js'
                    'thirdparty/fontello.font/fontello.ttf?57755967'
                    'http://themes.googleusercontent.com/static/fonts/
raleway/v6/UAnF6lSK1JNc1tqTiG8pNALUuEpTyoUstqEm5AMlJo4.ttf'
                    'http://themes.googleusercontent.com/static/fonts/
lato/v6/0DeoTBMnW4sOpD0Zb8OQSALUuEpTyoUstqEm5AMlJo4.ttf'
                ]
                network: ['*']
            transient:
                options:
                    basePath: '<%= project.transient %>'
                src: ['scripts/*.js', 'stylesheets/*.css']
                dest: '<%= project.transient %>/cache.manifest'
            release:
                options:
                    basePath: '<%= project.distribution %>'
                src: ['scripts/*.js', 'stylesheets/*.css', ]
                dest: '<%= project.distribution %>/cache.manifest'
        watch:
            options:
                spawn: false # sacrificing stability for the performance
            coffee:
                files: '<%= project.source %>/scripts/*.coffee'
                tasks: ['coffee:compile', 'manifest:transient', 'coffeelint']
            stylus:
                files: '<%= project.source %>/stylesheets/*.styl'
                tasks: ['stylus:compile', 'manifest:transient']
            'jade/index':
                files: '<%= project.source %>/index.jade'
                tasks: ['jade:index', 'manifest:transient']
            'jade/jst':
                files: '<%= project.source %>/templates/*.jade'
                tasks: ['jade:jst', 'manifest:transient']
        connect:
            server:
                options:
                    # hostname: "*"
                    port: 8000
                    middleware: (connect) ->
                        path = require 'path'
                        project = grunt.config.get 'project'
                        result = []
                        if grunt.config.get('watch.options.livereload')
                            result.push require('connect-livereload')() # takes care of livereload script injection
                        result.push connect['static'](path.resolve(dir)) for dir in [project.source, project.transient]
                        return result
            'server@release':
                options:
                    port: 9000
                    base: '<%= project.distribution %>'
        useminPrepare:
            html: '<%= project.transient %>/index.html'
            options:
                dest: '<%= project.distribution %>'
        usemin:
            html: '<%= project.distribution %>/index.html'
        uglify:
            thirdparty:
                files: [
                    expand: true
                    cwd: '<%= project.distribution %>/thirdparty'
                    src: '**/*.js'
                    dest: '<%= project.distribution %>/thirdparty'
                ]
        cssmin:
            thirdparty:
                expand: true
                cwd: '<%= project.distribution %>/thirdparty'
                src: '**/*.css'
                dest: '<%= project.distribution %>/thirdparty'
        htmlmin:
            distribution:
                options:
                    useShortDoctype: true,
                    collapseWhitespace: true
                    collapseBooleanAttributes: true
                    removeComments: true
                    removeAttributeQuotes: true
                    removeRedundantAttributes: true
                    removeEmptyAttributes: true
                    removeOptionalTags: true
                files: [
                    expand: true
                    cwd: '<%= project.distribution %>'
                    src: '*.html'
                    dest: '<%= project.distribution %>'
                ]
        copy:
            distribution:
                files: [
                    expand: true
                    cwd: '<%= project.source %>'
                    src: ['favicon.ico', 'thirdparty/**', '!**/component.json']
                    dest: '<%= project.distribution %>'
                   ,
                    expand: true
                    cwd: '<%= project.transient %>'
                    src: ['*.html']
                    dest: '<%= project.distribution %>'
                ]
        open:
            server:
                url: 'http://localhost:<%= connect.server.options.port %>'
        bump:
            options:
                commitMessage: 'v%VERSION%'
                tagMessage: 'v%VERSION%'
        deploy:
            options:
                sourceDirectory: '<%= project.distribution %>'
                repositoryURL: '<%= grunt.config.get("pkg").repository.url %>'
                commitMessage: ->
                    shell = require('shelljs')
                    packageVersion = grunt.config.get('pkg').version
                    gitBranch = shell.exec('git rev-parse --abbrev-ref HEAD', silent: true).output.trim()
                    gitRevision = shell.exec('git rev-list HEAD --max-count=1', silent: true).output.trim()
                    "#{packageVersion} of #{gitBranch}/#{gitRevision}"

    # load all grunt tasks defined in package.json
    grunt.loadNpmTasks task for own task of grunt.config.
        get('pkg').devDependencies when task.indexOf('grunt-') is 0

    grunt.registerTask 'lint', ['coffeelint']
    grunt.registerTask 'compile', ['coffee:compile', 'stylus:compile', 'jade']
    grunt.registerTask 'min', ['copy', 'useminPrepare', 'concat', 'uglify', 'cssmin', 'usemin', 'htmlmin']

    grunt.registerTask 'default', ['clean', 'lint', 'compile', 'manifest:transient', 'connect:server', 'watch']
    grunt.registerTask 'with-livereload', ->
        grunt.config.set('watch.options.livereload', true)
        grunt.task.run('default')

    grunt.registerTask 'release', ['clean', 'lint', 'compile', 'min', 'manifest:release']
    grunt.registerTask 'server@release', ['connect:server@release', 'watch']

    grunt.registerTask 'deploy', 'Deploy to the GitHub', ->
        [shell, tmp, path] = [require('shelljs'), require('temporary'), require('path')]
        return grunt.fatal '"git" needs to be available on the PATH in order to proceed.' unless shell.which 'git'
        options = this.options()
        sourceDirectory = path.resolve options.sourceDirectory
        checkoutDirectory = options.checkoutDirectory || (new tmp.Dir()).path
        shell.config.fatal = true
        grunt.log.writeln "Preparing #{checkoutDirectory} to be used as a checkout directory"
        shell.rm '-rf', checkoutDirectory
        grunt.log.writeln "Cloning #{options.repositoryURL}"
        # todo: how about "--single-branch"?
        shell.exec "git clone -b master #{options.repositoryURL} #{checkoutDirectory}", silent: true
        shell.cd checkoutDirectory
        shell.exec 'git rm -rq ./*'
        grunt.log.writeln "Overlaying with #{sourceDirectory}"
        shell.cp '-r', "#{sourceDirectory}/*", './'
        shell.exec 'git add --all'
        message = options.commitMessage
        message = message() if typeof(message) is 'function'
        shell.exec "git commit -m '#{message}'"
        if grunt.option('push') is true
            grunt.log.writeln "Performing push to #{options.repositoryURL}"
            shell.exec 'git push'
        else
            grunt.log.writeln '"git push" skipped due to unspecified --push=true'
