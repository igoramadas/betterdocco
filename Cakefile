{spawn, exec} = require 'child_process'
fs            = require 'fs'
path          = require 'path'

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'
option '-w', '--watch', 'continually build the betterdocco library'
option '-l', '--layout [LAYOUT]', 'specify the layout for Docco\'s docs'

task 'build', 'build the betterdocco library', (options) ->
  coffee = spawn 'coffee', ['-c' + (if options.watch then 'w' else ''), '.']
  coffee.stdout.on 'data', (data) -> console.log data.toString().trim()
  coffee.stderr.on 'data', (data) -> console.log data.toString().trim()

task 'install', 'install the `betterdocco` command into /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'
  lib  = base + '/lib/betterdocco'
  exec([
    'mkdir -p ' + lib + ' ' + base + '/bin'
    'cp -rf bin README resources index.js betterdocco.litcoffee package.json node_modules ' + lib
    'ln -sf ' + lib + '/bin/betterdocco ' + base + '/bin/betterdocco'
  ].join(' && '), (err, stdout, stderr) ->
   if err then console.error stderr
  )

task 'doc', 'rebuild the Docco documentation', (options) ->
  layout = options.layout or 'linear'
  exec([
    "bin/betterdocco --layout #{layout} betterdocco.litcoffee"
    "sed \"s/docco.css/resources\\/#{layout}\\/docco.css/\" < docs/betterdocco.html > index.html"
    'rm -r docs'
  ].join(' && '), (err) ->
    throw err if err
  )

task 'loc', 'count the lines of code in Docco', ->
  code = fs.readFileSync('betterdocco.litcoffee').toString()
  lines = code.split('\n').filter (line) -> /^    /.test line
  console.log "Docco LOC: #{lines.length}"
