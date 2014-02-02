# openproxy.github.io

World of open proxies on Google Maps.

## Related projects

* [openproxy-chrome-extension](https://github.com/openproxy/openproxy-chrome-extension) - Google Chrome extension which allows to switch proxies directly through the OpenProxy web page.

## External dependencies

Currently OpenProxy depends on a number of external services, namely:

1. xroxy.com - provides list of proxies
2. freegeoip.net - contacted for current geolocation (limited to 10,000 queries/hour)
3. query.yahooapis.com - used to retrieve information from xroxy.com (limited to 2,000 requests/hour per IP)
4. maps.googleapis.com - Google Maps API v3 (limited to 25,000 map loads per day)

## Development

> PREREQUISITES: [GIT](http://git-scm.com/downloads), [Node.js and NPM](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager), [Grunt](https://github.com/gruntjs/grunt-cli)

    git clone https://github.com/openproxy/openproxy.github.io.git
    cd openproxy.github.io
    npm install # install all required dependencies

    grunt # start "development" server (on port 8000)
    grunt with-livereload # start "development" server (on port 8000) with livereload turned on
    grunt release server@release # build a "release" and start server directed at it (on port 9000)

## Deployment

    grunt bump --setversion=X.X.X # bump version
    grunt release # build a "release"
    grunt deploy # deploy release build to openproxy.github.io/master

## License

[MIT License](http://opensource.org/licenses/mit-license.php)