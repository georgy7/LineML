# stringplate

HTML-like templates in single line.
Inspired by HAML, shpaml, DIET templates.

The main idea is to parse this:

```
#d(#z, #f(.item, .item, .item, .item, .item))
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
* custom attributes,
* maybe even tag names.
