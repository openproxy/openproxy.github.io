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
            compile:
                options:
                    pretty: true
                    data:
                        debug: false
                files:
                    '<%= project.transient %>/index.html': '<%= project.source %>/index.jade'
        watch:
            options:
                spawn: false # sacrificing stability for the performance
            coffee:
                files: '<%= project.source %>/scripts/*.coffee'
                tasks: ['coffeelint', 'coffee:compile']
            stylus:
                files: '<%= project.source %>/stylesheets/*.styl'
                tasks: ['stylus:compile']
            jade:
                files: '<%= project.source %>/*.jade'
                tasks: ['jade:compile']
        connect:
            server:
                options:
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
                options:
                    mangle: false
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

    # load all grunt tasks defined in package.json
    grunt.loadNpmTasks task for own task of grunt.config.
        get('pkg').devDependencies when task.indexOf('grunt-') is 0

    grunt.registerTask 'lint', ['coffeelint']
    grunt.registerTask 'compile', ['coffee:compile', 'stylus:compile', 'jade:compile']
    grunt.registerTask 'min', ['copy', 'useminPrepare', 'concat', 'uglify', 'cssmin', 'usemin', 'htmlmin']

    grunt.registerTask 'default', ['clean', 'lint', 'compile', 'connect:server', 'watch']
    grunt.registerTask 'with-livereload', ->
        grunt.config.set('watch.options.livereload', true)
        grunt.task.run('default')

    grunt.registerTask 'release', ['clean', 'lint', 'compile', 'min']
    grunt.registerTask 'server@release', ['connect:server@release', 'watch']

    grunt.registerTask 'deploy', 'Deploy to GitHub Pages', ->
        [shell, path] = [require('shelljs'), require('path')]
        return grunt.fatal '"git" needs to be available on the PATH in order to proceed.' unless shell.which 'git'
        checkoutURL = 'https://github.com/openproxy/openproxy.github.io.git'
        checkoutDirectory = 'target/master'
        releaseBuild = path.resolve 'target/release_build'
        packageVersion = grunt.config.get('pkg').version
        gitBranch = shell.exec('git rev-parse --abbrev-ref HEAD', silent: true).output.trim()
        gitRevision = shell.exec('git rev-list HEAD --max-count=1', silent: true).output.trim()
        shell.config.fatal = true
        shell.rm '-rf', checkoutDirectory
        shell.exec "git clone -b master #{checkoutURL} #{checkoutDirectory}", silent: true
        shell.cd checkoutDirectory
        shell.exec 'git rm -rq ./*'
        shell.cp '-r', "#{releaseBuild}/*", './'
        shell.exec 'git add --all'
        shell.exec "git commit -m '#{packageVersion} of #{gitBranch}/#{gitRevision}'"
        if grunt.option('push') is true
            shell.exec 'git push'
        else
            grunt.log.writeln '"git push" skipped due to unspecified --push=true'
