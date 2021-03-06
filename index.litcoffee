Better Docco
=====

**Beter Docco** is a quick-and-dirty documentation generator, written in
[Literate CoffeeScript](http://coffeescript.org/#literate), forked from the
infamous [Docco](http://ashkenas.com/docco). It generates HTML documents that
displays your comments intermingled with your code. All prose is passed through
[Markdown](http://daringfireball.net/projects/markdown/syntax), and code is
passed through [Highlight.js](http://highlightjs.org/) syntax highlighting.

This page is the result of running Better Docco against its own
[source file](https://github.com/igoramadas/betterdocco/blob/master/index.litcoffee).

1. Install Docco with **npm**: `sudo npm install -g betterdocco`

2. Run it against your code: `betterdocco src/*.coffee`

There is no "Step 3". This will generate an HTML page for each of the named
source files, with a menu linking to the other pages, saving the whole thing
into a `docs` folder (configurable).

The [source code](http://github.com/igoramadas/betterdocco) is available on GitHub,
and is released under the [MIT license](http://opensource.org/licenses/MIT).

Better Docco can be used to process code written in any programming language. If it
doesn't handle your favorite yet, feel free to
[add it to the list](https://github.com/igoramadas/betterdocco/blob/master/resources/languages.json).
Finally, the ["literate" style](http://coffeescript.org/#literate) of *any*
language is also supported — just tack an `.md` extension on the end:
`.coffee.md`, `.py.md`, and so on.

Partners in Crime:
------------------

* The original [Docco](https://github.com/jashkenas/docco),
from [Jeremy Ashkenas](https://github.com/jashkenas).

* If Node.js doesn't run on your platform, or you'd prefer a more
convenient package, get [Ryan Tomayko](http://github.com/rtomayko)'s
[Rocco](http://rtomayko.github.io/rocco/rocco.html), the **Ruby** port that's
available as a gem.

* If you're writing shell scripts, try
[Shocco](http://rtomayko.github.io/shocco/), a port for the **POSIX shell**,
also by Mr. Tomayko.

* If **Python** is more your speed, take a look at
[Nick Fitzgerald](http://github.com/fitzgen)'s [Pycco](http://fitzgen.github.io/pycco/).

* For **Clojure** fans, [Fogus](http://blog.fogus.me/)'s
[Marginalia](http://fogus.me/fun/marginalia/) is a bit of a departure from
"quick-and-dirty", but it'll get the job done.

* There's a **Go** port called [Gocco](http://nikhilm.github.io/gocco/),
written by [Nikhil Marathe](https://github.com/nikhilm).

* For all you **PHP** buffs out there, Fredi Bach's
[sourceMakeup](http://jquery-jkit.com/sourcemakeup/) (we'll let the faux pas
with respect to our naming scheme slide), should do the trick nicely.

* **Lua** enthusiasts can get their fix with
[Robert Gieseke](https://github.com/rgieseke)'s [Locco](http://rgieseke.github.io/locco/).

* And if you happen to be a **.NET**
aficionado, check out [Don Wilson](https://github.com/dontangg)'s
[Nocco](http://dontangg.github.io/nocco/).

* Going further afield from the quick-and-dirty, [Groc](http://nevir.github.io/groc/)
is a **CoffeeScript** fork of Docco that adds a searchable table of contents,
and aims to gracefully handle large projects with complex hierarchies of code.

Note that not all ports will support all Better Docco features ... yet.

Main Documentation Generation Functions
---------------------------------------

Generate the documentation for our configured source file by copying over static
assets, reading all the source files in, splitting them up into prose+code
sections, highlighting each file in the appropriate language, and printing them
out in an HTML template.

    document = (options = {}, callback) ->
        config = configure options

        fs.mkdirs config.output, ->
            callback or= (error) -> throw error if error
            copyAsset = (file, callback) ->
                return callback() unless fs.existsSync file
                fs.copy file, path.join(config.output, path.basename(file)), callback
            complete = ->
                copyAsset config.css, (error) ->
                    return callback error if error
                    return copyAsset config.public, callback if fs.existsSync config.public
                    callback()

            files = config.sources.slice()

            nextFile = ->
                source = files.shift()
                fs.readFile source, (error, buffer) ->
                    return callback error if error

                    code = buffer.toString()
                    sections = parse source, code, config
                    format source, sections, config
                    write source, sections, config
                    if files.length then nextFile() else complete()

            nextFile()

Given a string of source code, **parse** out each block of prose and the code that
follows it — by detecting which is which, line by line — and then create an
individual **section** for it. Each section is an object with `docsText` and
`codeText` properties, and eventually `docsHtml` and `codeHtml` as well.

    parse = (source, code, config = {}) ->
        lines = code.split '\n'
        sections = []
        lang = getLanguage source, config
        hasCode = docsText = codeText = ''

        save = ->
            sections.push {docsText, codeText}
            hasCode = docsText = codeText = ''

Our quick-and-dirty implementation of the literate programming style. Simply
invert the prose and code relationship on a per-line basis, and then continue as
normal below.

        if lang.literate
            isText = maybeCode = yes
            for line, i in lines
                lines[i] = if maybeCode and match = /^([ ]{4}|[ ]{0,3}\t)/.exec line
                    isText = no
                    line[match[0].length..]
                else if maybeCode = /^\s*$/.test line
                    if isText then lang.symbol else ''
                else
                    isText = yes
                    lang.symbol + ' ' + line

        for line in lines
            if line.match(lang.commentMatcher) and not line.match(lang.commentFilter)
                save() if hasCode
                docsText += (line = line.replace(lang.commentMatcher, '')) + '\n'
                save() if /^(---+|===+)$/.test line
            else
                hasCode = yes
                codeText += line + '\n'
        save()

        sections

To **format** and highlight the now-parsed sections of code, we use **Highlight.js**
over stdio, and run the text of their corresponding comments through
**Markdown**, using [Marked](https://github.com/chjj/marked).

    format = (source, sections, config) ->
        language = getLanguage source, config

Pass any user defined options to Marked if specified via command line option

        markedOptions =
            smartypants: true

        if config.marked
            markedOptions = config.marked

        marked.setOptions markedOptions

Tell Marked how to highlight code blocks within comments, treating that code
as either the language specified in the code block or the language of the file
if not specified.

        marked.setOptions {
            highlight: (code, lang) ->
                lang or= language.name

                if highlightjs.getLanguage(lang)
                    highlightjs.highlight(lang, code).value
                else
                    console.warn "betterdocco: couldn't highlight code block with unknown language '#{lang}' in #{source}"
                    code
        }

        for section, i in sections
            code = highlightjs.highlight(language.name, section.codeText).value
            code = code.replace(/\s+$/, '')
            section.codeHtml = "<div class='highlight'><pre>#{code}</pre></div>"
            section.docsHtml = marked(section.docsText)

Once all of the code has finished highlighting, we can **write** the resulting
documentation file by passing the completed HTML sections into the template,
and rendering it to the specified output path. Here we improved the original
docco so it uses the full path of the file on the filename and on the menu
text, to better handle documentation of files within multiple folders.

    write = (source, sections, config) ->
        destination = (file) ->
            filename = path.basename(file, path.extname(file)) + '.html'
            dirname = file.replace path.basename(file), ''
            dirname = dirname.replace path.resolve(config.output), ''
            dirname = dirname.replace path.resolve(__dirname), ''
            dirname = dirname.split('/').join('.')
            result = path.join(config.output, dirname + filename)
            result.replace(/\.\./g,'')

        menuText = (file) ->
            filename = path.basename(file)
            dirname = file.replace path.basename(file), ''
            dirname = dirname.replace path.resolve(config.output), ''
            dirname = dirname.replace path.resolve(__dirname), ''

            path.join(dirname + filename)

The **title** of the file is either the first heading in the prose, or the
name of the source file.

        firstSection = _.find sections, (section) ->
            section.docsText.length > 0
        first = marked.lexer(firstSection.docsText)[0] if firstSection
        hasTitle = first and first.type is 'heading' and first.depth is 1
        title = if hasTitle then first.text else path.basename source

        html = config.template {
            sources: config.sources, css: path.basename(config.css),
            title, hasTitle, sections, path, destination, menuText
        }

        console.log "betterdocco: #{source} -> #{destination source}"
        fs.writeFileSync destination(source), html

Configuration
-------------

Default configuration **options**. All of these may be extended by
user-specified options.

    defaults =
        layout: 'betterdocco'
        output: 'docs'
        template: null
        css: null
        extension: null
        languages: {}
        marked: null

**Configure** this particular run of Docco. We might use a passed-in external
template, or one of the built-in **layouts**. We only attempt to process
source files for languages for which we have definitions.

    configure = (options) ->
        config = _.extend {}, defaults, _.pick(options, _.keys(defaults)...)

        config.languages = buildMatchers config.languages

The user is able to override the layout file used with the `--template` parameter.
In this case, it is also neccessary to explicitly specify a stylesheet file.
These custom templates are compiled exactly like the predefined ones, but the `public` folder
is only copied for the latter. Filenames stays as docco.xxx for compatibility reasons.

        if options.template
            unless options.css
                console.warn "betterdocco: no stylesheet file specified"
            config.layout = null
        else
            dir = config.layout = path.join __dirname, 'resources', config.layout
            config.public = path.join dir, 'public' if fs.existsSync path.join dir, 'public'
            config.template = path.join dir, 'docco.jst'
            config.css = options.css or path.join dir, 'docco.css'
        config.template = _.template fs.readFileSync(config.template).toString()

        if options.marked
            config.marked = JSON.parse fs.readFileSync(options.marked)

        config.sources = options.args.filter((source) ->
            lang = getLanguage source, config
            console.warn "betterdocco: skipped unknown type (#{path.basename source})" unless lang
            lang
        ).sort()

        config

Helpers & Initial Setup
-----------------------

Require our external dependencies.

    _ = require 'underscore'
    fs = require 'fs-extra'
    path = require 'path'
    marked = require 'marked'
    commander = require 'commander'
    highlightjs = require 'highlight.js'

Languages are stored in JSON in the file `resources/languages.json`.
Each item maps the file extension to the name of the language and the
`symbol` that indicates a line comment. To add support for a new programming
language to Better Docco, just add it to the file.

    languages = JSON.parse fs.readFileSync(path.join(__dirname, 'resources', 'languages.json'))

Build out the appropriate matchers and delimiters for each language.

    buildMatchers = (languages) ->
        for ext, l of languages

Does the line begin with a comment?

            l.commentMatcher = ///^\s*#{l.symbol}\s?///

Ignore [hashbangs](http://en.wikipedia.org/wiki/Shebang_%28Unix%29) and interpolations...

            l.commentFilter = /(^#![/]|^\s*#\{)/
        languages
    languages = buildMatchers languages

A function to get the current language we're documenting, based on the
file extension. Detect and tag "literate" `.ext.md` variants.

    getLanguage = (source, config) ->
        ext = config.extension or path.extname(source) or path.basename(source)
        lang = config.languages?[ext] or languages[ext]
        if lang and lang.name is 'markdown'
            codeExt = path.extname(path.basename(source, ext))
            if codeExt and codeLang = languages[codeExt]
                lang = _.extend {}, codeLang, {literate: yes}
        lang

Keep it DRY. Extract the betterdocco **version** from `package.json`

    version = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'))).version

Command Line Interface
----------------------

Finally, let's define the interface to run Better Docco from the command line.
Parse options using [Commander](https://github.com/visionmedia/commander.js).
Default template is the new "betterdocco".

    run = (args = process.argv) ->
        c = defaults
        commander.version(version)
        .usage('[options] files')
        .option('-L, --languages [file]', 'use a custom languages.json', _.compose JSON.parse, fs.readFileSync)
        .option('-l, --layout [name]', 'choose a layout (parallel, linear, classic or betterdocco)', c.layout)
        .option('-o, --output [path]', 'output to a given folder', c.output)
        .option('-c, --css [file]', 'use a custom css file', c.css)
        .option('-t, --template [file]', 'use a custom .jst template', c.template)
        .option('-e, --extension [ext]', 'assume a file extension for all inputs', c.extension)
        .option('-m, --marked [file]', 'use custom marked options', c.marked)
        .parse(args)
        .name = "betterdocco"

        if commander.args.length
            document commander
        else
            console.log commander.helpInformation()

Public API
----------

    Docco = module.exports = {run, document, parse, format, version}
