# LineML

[![Dub version](https://img.shields.io/dub/v/lineml.svg)](https://code.dlang.org/packages/lineml)
[![Build Status](https://travis-ci.org/georgy7/lineml.svg?branch=master)](https://travis-ci.org/georgy7/lineml)
[![Coverage Status](https://coveralls.io/repos/github/georgy7/lineml/badge.svg?branch=master)](https://coveralls.io/github/georgy7/lineml?branch=master)

## 1. As the shortened HTML/XML

This is just a side effect of the main functionality (see the section #2).

For example, you can parse this:

```
#d(#z, #f(.item, .item, .item, .item, .item))
```

or this:

```
#d(#z, #f(.item:5))
```

and transform

```d
auto result = lmlToHtml(input, LmlHtmlFormat.SPACES_4);
```

into this:

```html
<div id="d">
    <div id="z"></div>
    <div id="f">
        <div class="item"></div>
        <div class="item"></div>
        <div class="item"></div>
        <div class="item"></div>
        <div class="item"></div>
    </div>
</div>
```

So, the language does not support

* tag content,
* custom attributes.

### More examples

LineML:

```
#d(#z, #f(.qw, .item:2, #ds, .sdsdfs))
```

XML:

```html
<div id="d">
    <div id="z"></div>
    <div id="f">
        <div class="qw"></div>
        <div class="item"></div>
        <div class="item"></div>
        <div id="ds"></div>
        <div class="sdsdfs"></div>
    </div>
</div>
```

LineML:

```
#d(#z, #f(.qw, .item:3(.asd)))
```

XML:

```html
<div id="d">
    <div id="z"></div>
    <div id="f">
        <div class="qw"></div>
        <div class="item">
            <div class="asd"></div>
        </div>
        <div class="item">
            <div class="asd"></div>
        </div>
        <div class="item">
            <div class="asd"></div>
        </div>
    </div>
</div>
```

## 2. Generating custom trees

You can parse your markup without making HTML.

```d
LineMLNode result = lmlToNode!LineMLNode(input);
```

But the main purpose of the package is to subclass `LineMLNode`, then generate the trees of the objects
of this custom class. Then, populate the objects as you want,
and then to use the tree programmatically anyway you want it.

## License

Boost

* [Pegged](http://code.dlang.org/packages/pegged) - Boost 
* [fluent-asserts:core](http://code.dlang.org/packages/fluent-asserts%3Acore) (for unit tests) - MIT
