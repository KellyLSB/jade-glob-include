# Jade Glob Include
## (Globbing Include Directive for Jade)

**Author: Kelly Becker**  
**Website: http://kellybecker.me**  
**GitHub: http://github.com/KellyLSB**  
**License: [MIT](./LICENSE)**

Like many other engineers I love Jade. I stumbled upon it the other day and was very pleased with it's syntax and feature sets, but with every piece of software there is always something we dislike. Thankfully, due to mutable states, we have monkey patching!

~~There was one issue that stood out like a Bumble Bee buzzing around my head while I'm not wearing a sweater or gloves. I wanted to swat it away but I was afraid of the aftermath. So... of course this meant that I had to get over my fear.~~

~~The problem was I knew if I swatted this one Bumble Bee and then brushed it off... I more than likely would face more again in the future. So I went to war.~~

I did not want to manually include all of the items in my resume manually into my template. 10 include directives in a row... I mean that's a whole lot! It could take days to write those ten measly lines. I had to come up with a plan and by happenstance it meant writing 122 lines of Coffee. Now, I've seen "The Venture Brothers" and I learned from Hank's experience that maybe 122 lines of ground coffee is not the best idea... so I did it anyway. **So emerging from my laziness I present to you: Globbing Include Directive for Jade!**

## Requirements

I do not generally write Node much, I have not tested this with many versions. In the past I know Node has been known to change a lot. Because of this, here are the versions I developed with.

- [Node](http://nodejs.org) ~ v0.10.28
- [Jade](https://github.com/visionmedia/jade) ~ 1.3.1
- [Glob](https://github.com/isaacs/node-glob) ~ 3.2.9
- [Colors](https://github.com/Marak/colors.js) ~ ^0.6.2 `For informational output`

## Installing

**To install globally**

`npm install -g jade-glob-include`

**To include in a project**

`npm install jade-glob-include --save-dev`

**Code modifications**

All you need to do to add glob support is send jade as the only argument to `.Patch(jade_object)`. Please reference the following  code.

```js
var jade = require('jade');

// Patch in Globbing Include!
require('jade-glob-include').Patch(jade);

var fn = jade.compile(jadeTemplate);
var htmlOutput = fn({
  maintainer: {
    name: 'Forbes Lindesay',
    twitter: '@ForbesLindesay',
    blog: 'forbeslindesay.co.uk'
  }
});
```

## Using Grunt

This was a painpoint for me to figure out the best way to implement this library with Grunt, especially considering the goal of this was to create a library you could install and include with little to no modification of external libraries.

Please view [grunt-contrib-jade](https://github.com/gruntjs/grunt-contrib-jad e) for additional reference beyond the scope of what I will display here.

**Code Modifications**

This may seem a little weird, but we are going to Hijack the data input for jade in your Gruntfile! Please consider the following `Gruntfile.js`

```js
// Load in Jade Glob Include
JadeGlobInclude = require('jade-glob-include');

module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    jade: {
      options: {
        pretty: true,
        data: function() {
          // Patch in Globbing Include!
          JadeGlobInclude.Patch(this.jade);

          return {
            debug: true,
            timestamp: "<%= grunt.template.today() %>",
          }
        }
      },
      dist: {
        files: {'index.html': 'jade/index.jade'}
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-jade');
  grunt.registerTask('default', ['jade']);
}
```

## How does this change `include`?

Because Jade Glob Include uses [node-glob](https://github.com/isaacs/node-glob) you can use any of the formats that are allowed there as well. Please consider the following.

```jade
h1 Welcome
  //- Include all files in includes
  include includes/*

  //- Include from multiple sources
  include {~/jade/mixins/**/*, includes/*}
```

This allows for additional flexibility when naming files and folders and compiling items such as static page blogs, etc...

*Note: If you load includes from outside your project directory you will need to set the basedir option for Jade to a higher level in your file system tree.*

## Todo

1. Get back up to date on Jasmine
2. Write proper specs.

## Priority Todo

1. Drink More Coffee (Hell Yeah, Four Barrel)!
2. TBD

![Coffee Time](http://www.tshirtvortex.net/wp-content/uploads/Coffee-Time-A.gif)
