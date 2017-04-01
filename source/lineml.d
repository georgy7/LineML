module lineml;

import pegged.grammar;
import std.exception;
import std.algorithm.searching;
import std.string;

mixin(grammar(`
    LineML:
        MARKUP      <- SPACES? TAG SPACES? eoi
        TAG         <- SELECTOR BODY?
        BODY        <- "(" ANYTAGS ")"
        ANYTAGS     <- (SPACES? ANYTAG "," SPACES?)* ANYTAG SPACES?
        ANYTAG      <- REPEATER / TAG
        REPEATER    <- RSELECTOR ":" COUNT RBODY?

        RBODY       <- "(" RTAGS ")"
        RTAGS       <- (SPACES? RTAG "," SPACES?)* RTAG SPACES?
        RTAG        <- REPEATER / (RSELECTOR RBODY?)

        SPACES      <- ~(SPACE*)
        SPACE       <- " " / "\t" / "\n" / "\r"
        SELECTOR    <- (TAGNAME CLASS* ID? CLASS*) / (CLASS* ID CLASS*) / CLASS+
        RSELECTOR   <- (TAGNAME CLASS*) / CLASS+
        TAGNAME     <- ~([a-z]+)
        ID          <- ~("#" [a-zA-Z]+)
        CLASS       <- ~("." [a-zA-Z]+)
        COUNT       <- ~([0-9]+)
`));

class LineMLParseException : Exception {
    private const ParseTree _ptree;
    this(ParseTree ptree, string file = __FILE__, size_t line = __LINE__) pure nothrow @safe {
        super("Parsing failure.", file, line);
        this._ptree = ptree;
    }
    @property const(ParseTree) parseTree() { return _ptree; }
}

/// Note, the class is NOT final!
class LineMLNode {
    private string _tagName, _id;
    private string[] _classes = [];
    private LineMLNode[] _children = [];

    @property string tagName() @safe pure nothrow {
        return _tagName;
    }
    @property void tagName(string v) @safe pure nothrow {
        _tagName = v;
    }
    @property string id() @safe pure nothrow {
        return _id;
    }
    @property void id(string v) @safe pure nothrow {
        _id = v;
    }
    @property ref string[] classes() @safe pure nothrow {
        return _classes;
    }
    @property ref LineMLNode[] children() @safe pure nothrow {
        return _children;
    }

    override string toString() @safe pure nothrow {
        auto r = "";
        r ~= ((_tagName is null) ? "" : _tagName);
        r ~= ((_id is null) ? "" : ("#" ~ _id));
        if (_classes !is null) {
            foreach(ref c; _classes) {
                r ~= ".";
                r ~= c;
            }
        }
        if (_children !is null && _children.length > 0) {
            r ~= "(";
            bool first = true;
            foreach(ref c; _children) {
                if (!first) {
                    r ~= ", ";
                }
                r ~= c.toString();
                first = false;
            }
            r ~= ")";
        }
        return r;
    }
}

enum LmlHtmlFormat {
    LINE
}

unittest {
    enum p = LineML("html");
    assert(p.children.length == 1);
    assert(p.children[0].name.endsWith(".MARKUP"));
    assert(p.children[0].children.length == 1);
    assert(p.children[0].children[0].name.endsWith(".TAG"));
    assert(p.children[0].children[0].children.length == 1);
    assert(p.children[0].children[0].children[0].name.endsWith(".SELECTOR"));
    assert(p.children[0].children[0].children[0].children.length == 1);
    assert(p.children[0].children[0].children[0].children[0].name.endsWith(".TAGNAME"));
    assert(p.children[0].children[0].children[0].children[0].matches.length == 1);
    assert(p.children[0].children[0].children[0].children[0].matches[0] == "html");
}

unittest {
    enum p = LineML("#myId");
    assert(p.children.length == 1);
    assert(p.children[0].name.endsWith(".MARKUP"));
    assert(p.children[0].children.length == 1);
    assert(p.children[0].children[0].name.endsWith(".TAG"));
    assert(p.children[0].children[0].children.length == 1);
    assert(p.children[0].children[0].children[0].name.endsWith(".SELECTOR"));
    assert(p.children[0].children[0].children[0].children.length == 1);
    assert(p.children[0].children[0].children[0].children[0].name.endsWith(".ID"));
    assert(p.children[0].children[0].children[0].children[0].matches.length == 1);
    assert(p.children[0].children[0].children[0].children[0].matches[0] == "#myId");
}

unittest {
    enum p = LineML(".myClass");
    assert(p.children.length == 1);
    assert(p.children[0].name.endsWith(".MARKUP"));
    assert(p.children[0].children.length == 1);
    assert(p.children[0].children[0].name.endsWith(".TAG"));
    assert(p.children[0].children[0].children.length == 1);
    assert(p.children[0].children[0].children[0].name.endsWith(".SELECTOR"));
    assert(p.children[0].children[0].children[0].children.length == 1);
    assert(p.children[0].children[0].children[0].children[0].name.endsWith(".CLASS"));
    assert(p.children[0].children[0].children[0].children[0].matches.length == 1);
    assert(p.children[0].children[0].children[0].children[0].matches[0] == ".myClass");
}

unittest {
    enum p = LineML("p.myClass");
    assert(p.children.length == 1);
    assert(p.children[0].name.endsWith(".MARKUP"));
    assert(p.children[0].children.length == 1);
    assert(p.children[0].children[0].name.endsWith(".TAG"));
    assert(p.children[0].children[0].children.length == 1);
    assert(p.children[0].children[0].children[0].name.endsWith(".SELECTOR"));
    assert(p.children[0].children[0].children[0].children.length == 2);
    assert(p.children[0].children[0].children[0].children[0].name.endsWith(".TAGNAME"));
    assert(p.children[0].children[0].children[0].children[0].matches.length == 1);
    assert(p.children[0].children[0].children[0].children[0].matches[0] == "p");
    assert(p.children[0].children[0].children[0].children[1].name.endsWith(".CLASS"));
    assert(p.children[0].children[0].children[0].children[1].matches.length == 1);
    assert(p.children[0].children[0].children[0].children[1].matches[0] == ".myClass");
}

unittest {
    enum p = LineML("p#asd");
    assert(p.children.length == 1);
    assert(p.children[0].name.endsWith(".MARKUP"));
    assert(p.children[0].children.length == 1);
    assert(p.children[0].children[0].name.endsWith(".TAG"));
    assert(p.children[0].children[0].children.length == 1);
    assert(p.children[0].children[0].children[0].name.endsWith(".SELECTOR"));
    assert(p.children[0].children[0].children[0].children.length == 2);
    assert(p.children[0].children[0].children[0].children[0].name.endsWith(".TAGNAME"));
    assert(p.children[0].children[0].children[0].children[0].matches.length == 1);
    assert(p.children[0].children[0].children[0].children[0].matches[0] == "p");
    assert(p.children[0].children[0].children[0].children[1].name.endsWith(".ID"));
    assert(p.children[0].children[0].children[0].children[1].matches.length == 1);
    assert(p.children[0].children[0].children[0].children[1].matches[0] == "#asd");
}

unittest {
    assert(!LineML("").successful);
    assert(!LineML("    ").successful);
    assert(LineML("foo").successful);
    assert(LineML("#bar").successful);
    assert(LineML(".bar").successful);
    assert(LineML("p#asd").successful);
    assert(LineML("p.asd").successful);
    assert(LineML("p.asd.foo.bar").successful);
    assert(LineML("p#asd.foo.bar").successful);
    assert(LineML("p.asd#foo.bar").successful);
    assert(LineML("p.asd.foo#bar").successful);

    assert(LineML("  p#asd").successful);
    assert(LineML("  p.asd").successful);
    assert(LineML("  p.asd.foo.bar").successful);
    assert(LineML("  p#asd.foo.bar").successful);
    assert(LineML("  p.asd#foo.bar").successful);
    assert(LineML("  p.asd.foo#bar").successful);

    assert(LineML("  p#asd  ").successful);
    assert(LineML("  p.asd  ").successful);
    assert(LineML("  p.asd.foo.bar  ").successful);
    assert(LineML("  p#asd.foo.bar  ").successful);
    assert(LineML("  p.asd#foo.bar  ").successful);
    assert(LineML("  p.asd.foo#bar  ").successful);

    assert(LineML("p#asd  ").successful);
    assert(LineML("p.asd  ").successful);
    assert(LineML("p.asd.foo.bar  ").successful);
    assert(LineML("p#asd.foo.bar  ").successful);
    assert(LineML("p.asd#foo.bar  ").successful);
    assert(LineML("p.asd.foo#bar  ").successful);

    assert(LineML("foo(bar)").successful);
    assert(!LineML("foo()").successful); // empty parentheses - illegal

    assert(!LineML("p #asd").successful); // multiple selectors, even without comma
    assert(!LineML("#asd p").successful);
    assert(!LineML("#asd .sdsf").successful);
    assert(!LineML("#asd .sdsf.zxc.sdf").successful);
    assert(!LineML(".sdsf.zxc #asd.sdf").successful);
    assert(!LineML(".sdsf.zxc p#asd.sdf").successful);
    assert(!LineML(".sdsf.zxc div.sdf").successful);
    assert(LineML(".sdsf.zxc#asd.sdf").successful);
    assert(LineML(".sdsf#zxc.asd.sdf").successful);
    assert(LineML("#sdsf.zxc.asd.sdf").successful);
    assert(!LineML("#sdsf.zxc#asd.sdf").successful); // multiple ids - illegal
    assert(!LineML("#sdsf#zxc").successful);
    assert(!LineML("p#sdsf#zxc").successful);
    assert(!LineML(".ssd#sdsf#zxc").successful);
    assert(!LineML("#sdsf#zxc.ssd").successful);
}

unittest {
    assert(!LineML("#z, #f, .item,  .item").successful); // multiple top-level tags - illegal
    enum p = LineML("sometag(#z, #f, .item,  .item)");
    assert(p.successful);

    assert(p.children.length == 1);
    assert(p.children[0].name.endsWith(".MARKUP"));
    assert(p.children[0].children.length == 1);
    assert(p.children[0].children[0].name.endsWith(".TAG"));
    enum topTagChildren = p.children[0].children[0].children;
    assert(topTagChildren.length == 2);
    assert(topTagChildren[0].name.endsWith(".SELECTOR"));
    assert(topTagChildren[0].children.length == 1);
    assert(topTagChildren[0].children[0].name.endsWith(".TAGNAME"));
    assert(topTagChildren[0].children[0].matches == ["sometag"]);

    assert(topTagChildren[1].name.endsWith(".BODY"));
    assert(topTagChildren[1].children.length == 1);
    assert(topTagChildren[1].children[0].name.endsWith(".ANYTAGS"));
    enum myTags = topTagChildren[1].children[0].children;
    assert(myTags.length == 7);

    assert(myTags[0].name.endsWith(".ANYTAG"));
    assert(myTags[1].name.endsWith(".SPACES"));
    assert(myTags[2].name.endsWith(".ANYTAG"));
    assert(myTags[3].name.endsWith(".SPACES"));
    assert(myTags[4].name.endsWith(".ANYTAG"));
    assert(myTags[5].name.endsWith(".SPACES"));
    assert(myTags[6].name.endsWith(".ANYTAG"));

    foreach(ref child; myTags[0].children[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            assert(child.children.length == 1);
            assert(child.children[0].name.endsWith(".ID"));
            assert(child.children[0].matches == ["#z"]);
        }
        assert(1 == found);
    }

    foreach(ref child; myTags[2].children[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            assert(child.children.length == 1);
            assert(child.children[0].name.endsWith(".ID"));
            assert(child.children[0].matches == ["#f"]);
        }
        assert(1 == found);
    }

    foreach(ref child; myTags[4].children[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            assert(child.children.length == 1);
            assert(child.children[0].name.endsWith(".CLASS"));
            assert(child.children[0].matches == [".item"]);
        }
        assert(1 == found);
    }

    foreach(ref child; myTags[6].children[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            assert(child.children.length == 1);
            assert(child.children[0].name.endsWith(".CLASS"));
            assert(child.children[0].matches == [".item"]);
        }
        assert(1 == found);
    }
}

unittest {
    assert(!LineML("foo:5").successful); // multiple top-level tags - illegal
    assert(!LineML("#foo:5").successful);
    assert(!LineML(".foo:5").successful);
    assert(!LineML("foo#bar:5").successful); // multiple top-level tags & id with the repeating tag - both illegal
    assert(!LineML("foo.bar:5").successful);
    assert(!LineML("foo(.sdf):5").successful);

    assert(LineML("#d(#z, #f(.item, .item, .item, .item, .item))").successful);
    assert(LineML("#d(#z, #f(.item:5))").successful);
    assert(!LineML("#d(#z, #f(#item:5))").successful); // repeating ID - illegal
    assert(LineML("#d(#z, #f(.item:5(.zzz)))").successful);
    assert(LineML("#d(#z, #f(.item:5(.zzz:5)))").successful);
    assert(LineML("#d(#z, #f(.qw, .item:2, #ds, .sdsdfs))").successful);
    assert(LineML("#d(#z, #f(.qw, .thing:45(.asd)))").successful);
    assert(LineML("#d(#z, #f(.qw, .thing:45(.asd, p, .sd)))").successful);
    assert(LineML("#d(#z, #f(.qw, p:45(.asd, p, .sd)))").successful);
    assert(!LineML("#d(#z, #f(.qw, .thing:45(.asd, p, #x)))").successful); // ID inside the repeating tag - illegal
    assert(LineML("#d(#z, #f(.qw, .thing:45(.asd, p:8, .sd)))").successful);
    assert(!LineML("#d(#z, #f(.qw, .thing:45(.asd, p:8(), .sd)))").successful); // empty parentheses - illegal
    assert(LineML("#d(#z, #f(.qw, .thing:45(.asd, p:8(.sdf), .sd)))").successful);
    assert(!LineML("#d(#z, #f(.qw, .thing:45(.asd, p:8(#sdf), .sd)))").successful); // ID inside the repeating tag - illegal
}

private ParseTree lmlTrusted(string markup) @trusted {
    return LineML(markup);
}

private ParseTree lmlParse(string markup) @safe {
    ParseTree tree = lmlTrusted(markup);
    if (!tree.successful) {
        throw new LineMLParseException(tree);
    }
    return tree;
}

private T selectorToNode(T : LineMLNode)(ParseTree a) @safe {
    T result = new T();
    foreach(ref c; a.children) {
        if (c.name.endsWith(".TAGNAME")) {
            result.tagName = c.matches[0];
        } else if (c.name.endsWith(".CLASS")) {
            result.classes ~= removechars(c.matches[0], "\\.");
        } if (c.name.endsWith(".ID")) {
            result.id = removechars(c.matches[0], "#");
        }
    }
    return result;
}

private T createNodeFromSelector(T : LineMLNode)(ParseTree a) @safe {
    assert(a.children.length >= 1);
    if (a.name.endsWith(".TAG")) {
        assert(a.children[0].name.endsWith(".SELECTOR"));
        return selectorToNode!T(a.children[0]);
    }
    return null;
}
private ParseTree[] childrenTags(ParseTree a) @safe {
    ParseTree[] result = [];
    if (a.name.endsWith(".TAG") && a.children.length >= 2) {
        assert(a.children[1].name.endsWith(".BODY"));
        assert(a.children[1].children[0].name.endsWith(".ANYTAGS"));
        auto anytags = a.children[1].children[0];
        foreach(ref c; anytags.children) {
            if (c.name.endsWith(".ANYTAG")) {
                auto t = c.children[0];
                if (t.name.endsWith(".TAG")) {
                    result ~= t;
                }
            }
        }
    }
    return result;
}

T lmlToNode(T : LineMLNode)(string markup) @safe {
    auto t = lmlParse(markup);

    assert(t.children.length == 1);
    assert(t.children[0].name.endsWith(".MARKUP"));
    assert(t.children[0].children.length == 1);
    assert(t.children[0].children[0].name.endsWith(".TAG"));

    ParseTree[] parentStack = [];
    T[] resultParentStack = [];
    int[] childIndex = [];
    T result = null;

    parentStack ~= t.children[0].children[0];
    childIndex ~= -1;

    while (parentStack.length > 0) {
        auto currentTag = parentStack[$-1];
        auto chTags = currentTag.childrenTags;
        if (childIndex[$-1] == -1) {
            T r = createNodeFromSelector!T(currentTag);
            resultParentStack ~= r;
            if (result is null) {
                result = resultParentStack[0];
            }
            if (chTags.length < 1) {
                parentStack.length--;
                childIndex.length--;
                resultParentStack.length--;
                if (childIndex.length > 0 && childIndex[$-1] >= 0) {
                    childIndex[$-1]++;
                }
            } else {
                childIndex[$-1] = 0;
            }
        } else if (childIndex[$-1] > chTags.length - 1) {
            parentStack.length--;
            childIndex.length--;
            resultParentStack.length--;
            if (childIndex.length > 0 && childIndex[$-1] >= 0) {
                childIndex[$-1]++;
            }
        } else {
            auto iTag = chTags[childIndex[$-1]];
            currentTag.children ~= iTag;
            childIndex[$-1]++;
        }
    }
    return result;
}

unittest {
    auto input = "#d";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id == "d");
    assert(result.children.length == 0);
    assert(result.classes.length == 0);
    assert(result.tagName is null);
}

unittest {
    auto input = ".d";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id is null);
    assert(result.children.length == 0);
    assert(result.classes.length == 1);
    assert(result.classes[0] == "d");
    assert(result.tagName is null);
}

unittest {
    auto input = "d";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id is null);
    assert(result.children.length == 0);
    assert(result.classes.length == 0);
    assert(result.tagName == "d");
}

unittest {
    auto input = ".foo.bar.zxcv";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id is null);
    assert(result.children.length == 0);
    assert(result.classes.length == 3);
    assert(result.classes.count("foo") > 0);
    assert(result.classes.count("bar") > 0);
    assert(result.classes.count("zxcv") > 0);
    assert(result.tagName is null);
}

unittest {
    import std.stdio;
    writeln("--------- THIS");
    auto input = "#d(#z, #f(.item, .item, .item, .item, .item))";
    auto result = lmlToNode!LineMLNode(input);
    writeln(result);
    assert(result.id == "d");
    assert(result.children.length == 2);
    assert(result.children[0].id == "z");
    assert(result.children[0].children.length == 0);
    assert(result.children[1].id == "f");
    assert(result.children[1].children.length == 5);
    auto items = result.children[1].children;
    assert(items.length == 5);
    assert(items[0].classes == ["item"]);
    assert(items[1].classes == ["item"]);
    assert(items[2].classes == ["item"]);
    assert(items[3].classes == ["item"]);
    assert(items[4].classes == ["item"]);
    writeln("--- /THIS");
}

unittest {
    auto input = "#d(#z, #f(.item:5))";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id == "d");
    assert(result.children.length == 2);
    assert(result.children[0].id == "z");
    assert(result.children[0].children.length == 0);
    assert(result.children[1].id == "f");
    assert(result.children[1].children.length == 5);
    auto items = result.children[1].children;
    assert(items.length == 5);
    assert(items[0].classes == ["item"]);
    assert(items[1].classes == ["item"]);
    assert(items[2].classes == ["item"]);
    assert(items[3].classes == ["item"]);
    assert(items[4].classes == ["item"]);
}

/*
private string parseTreeToHtml() {
    return "";
}

auto lmlToHtml(string markup, LmlHtmlFormat format) {
    return parseTreeToHtml(tree);
}

unittest {
    auto input = "#d(#z, #f(.item, .item, .item, .item, .item))";
    auto expected = "<div id=\"d\"><div id=\"z\"></div><div id=\"f\">" ~
            "<div class=\"item\"></div><div class=\"item\"></div>" ~
            "<div class=\"item\"></div><div class=\"item\"></div>" ~
            "<div class=\"item\"></div></div></div>";
    assert(lmlToHtml(input, LmlHtmlFormat.LINE) == expected);
}
*/
