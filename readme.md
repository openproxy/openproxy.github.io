# openproxy.github.io

World of open proxies on Google Maps

## Dependencies

Currently openproxy depends on a number of external services, namely:

1. xroxy.com - provides list of proxies
2. freegeoip.net - contacted for current geolocation (limited to 10,000 queries/hour)
3. query.yahooapis.com - used to retrieve information from xroxy.com (limited to 2,000 requests/hour per IP)
4. maps.googleapis.com - Google Maps API v3 (limited to 25,000 map loads per day)

## Development

> PREREQUISITES: [GIT](http://git-scm.com/downloads), [Node.js and NPM](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager), [Grunt](https://github.com/gruntjs/grunt-cli)

    git clone https://github.com/openproxy/openproxy.github.io.git
    cd openproxy.github.io
    npm install # this will install all required dependencies

    grunt # for a "live" server running on port 8000
    grunt release # for the release build
    grunt deploy # used to synchronize openproxy.github.io/master branch with the release build

## License

[MIT License](http://opensource.org/licenses/mit-license.php)