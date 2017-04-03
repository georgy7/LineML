# LineML

HTML-like templates in single line.
Inspired by HAML, shpaml, DIET templates.

The main idea is to parse this:

```
#d(#z, #f(.item, .item, .item, .item, .item))
```

or this:

```
#d(#z, #f(.item:5))
```

and transform into this (or a structure, representing this):

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

So, it will not support

* tag content,
* custom attributes.

### Example #2

```
#d(#z, #f(.qw, .item:2, #ds, .sdsdfs))
```

will be transformed into

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


### Example #3

```
#d(#z, #f(.qw, .item:3(.asd)))
```

Result:

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
