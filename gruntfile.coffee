module.exports = (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'
        project:
            source: 'src/webapp'
            transient: 'target/.tmp'
            target: 'target'
        clean:
            target: '<%= project.target %>'
        coffee:
            compile:
                files:
                    '<%= project.transient %>/scripts/index.js': '<%= project.source %>/scripts/*.coffee'
        stylus:
            compile:
                options:
                    compress: false
                files:
                    '<%= project.transient %>/stylesheets/index.css': '<%= project.source %>/stylesheets/*.styl'
        jade:
            compile:
                options:
                    pretty: true
                    data:
                        debug: false
                files:
                    '<%= project.transient %>/index.html': '<%= project.source %>/index.jade'
        regarde:
            coffee:
                files: '<%= project.source %>/scripts/*.coffee'
                tasks: ['coffee:compile', 'livereload']
            stylus:
                files: '<%= project.source %>/stylesheets/*.styl'
                tasks: ['stylus:compile', 'livereload']
            jade:
                files: '<%= project.source %>/*.jade'
                tasks: ['jade:compile', 'livereload']
        connect:
            server:
                options:
                    port: 8000
                    middleware: (connect) ->
                        path = require 'path'
                        project = grunt.config.get 'project'
                        connect['static'] path.resolve dir for dir in [project.source, project.transient]
        uglify:
            target:
                options:
                    mangle: false
                files: [
                    expand: true
                    cwd: '<%= project.transient %>'
                    src: '**/*.js'
                    dest: '<%= project.transient %>'
                ]
        cssmin:
            target:
                expand: true
                cwd: '<%= project.transient %>'
                src: '**/*.css'
                dest: '<%= project.transient %>'
        htmlmin:
            target:
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
                    cwd: '<%= project.transient %>'
                    src: '*.html'
                    dest: '<%= project.transient %>'
                ]
        copy:
            resources:
                files: [
                    expand: true
                    cwd: '<%= project.source %>'
                    src: ['favicon.ico', 'thirdparty/**', '!**/component.json']
                    dest: '<%= project.transient %>'
                ]
        open:
            server:
                url: 'http://localhost:<%= connect.server.options.port %>'

    # load all grunt tasks defined in package.json
    grunt.loadNpmTasks task for own task of grunt.config.
        get('pkg').devDependencies when task.indexOf('grunt-') is 0

    grunt.registerTask 'compile', ['coffee:compile', 'stylus:compile', 'jade:compile']
    grunt.registerTask 'min', ['uglify', 'cssmin', 'htmlmin']

    grunt.registerTask 'default', ['clean', 'compile', 'connect:server', 'regarde']
    grunt.registerTask 'with-livereload', ['livereload-start', 'default']

    grunt.registerTask 'release', ['clean', 'compile', 'copy', 'min']

    grunt.registerTask 'deploy', 'Deploy to GitHub Pages', ->
        [shell, path] = [require('shelljs'), require('path')]
        return grunt.fatal '"git" needs to be available on the PATH in order to proceed.' unless shell.which 'git'
        releaseBuild = path.resolve 'target/.tmp'
        shell.config.fatal = true
        shell.rm '-rf', 'target/master'
        shell.exec 'git clone -b master https://github.com/openproxy/openproxy.github.io.git target/master', silent: true
        shell.cd 'target/master'
        shell.exec 'git rm -rq ./*'
        shell.cp '-r', "#{releaseBuild}/*", './'
        shell.exec 'git add --all'
        packageVersion = grunt.config.get('pkg').version
        gitBranch = shell.exec('git rev-parse --abbrev-ref HEAD', silent: true).output.trim()
        gitRevision = shell.exec('git rev-list HEAD --max-count=1', silent: true).output.trim()
        shell.exec "git commit -m '#{packageVersion} of #{gitBranch}/#{gitRevision}'"
        if grunt.option('push') is 'true'
            shell.exec 'git push'
        else
            grunt.log.writeln '"git push" skipped due to unspecified --push=true'
