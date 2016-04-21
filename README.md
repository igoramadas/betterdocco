# Better Docco

Better Docco is a not quick-and-dirty, hundred-line-long, literate-programming-style
documentation generator based on Docco. For more information, see:

https://github.com/igoramadas/betterdocco

### What's different compared to the original Docco?

Better Docco will use the full path of source files on the menu and filenames. So you can
have for instance a index.coffee under /mymodule and another index.coffee under /anothermodule
and have both documented at the same batch.

### Installation:

    $ sudo npm install -g betterdocco
    
### Usage

    $ betterdocco [options] FILES

Options:

    -h, --help             output usage information
    -V, --version          output the version number
    -l, --layout [layout]  choose a built-in layouts (parallel, linear)
    -c, --css [file]       use a custom css file
    -o, --output [path]    use a custom output path
    -t, --template [file]  use a custom .jst template
    -e, --extension [ext]  use the given file extension for all inputs
    -L, --languages [file] use a custom languages.json
    -m, --marked [file]    use custom marked options
    
