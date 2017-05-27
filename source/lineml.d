module lineml;

import pegged.grammar;
import std.exception;
import std.algorithm.searching;
import std.string;

mixin(grammar(`
    LineML:
        MARKUP      <- SPACES? TAG SPACES? eoi
        TAG         <- SELECTOR BODY?
        BODY        <- "(" WITHOUTWHITESPACES? ANYTAGS WITHOUTWHITESPACES? ")"
        ANYTAGS     <- (SPACES? ANYTAG NEXTSEPARATOR SPACES?)* ANYTAG SPACES?
        ANYTAG      <- REPEATER / TAG / TEXTNODE
        REPEATER    <- RSELECTOR ":" COUNT RBODY?

        RBODY       <- "(" WITHOUTWHITESPACES? RTAGS WITHOUTWHITESPACES? ")"
        RTAGS       <- (SPACES? RTAG NEXTSEPARATOR SPACES?)* RTAG SPACES?
        RTAG        <- REPEATER / (RSELECTOR RBODY?) / TEXTNODE

        SPACES      <- ~(SPACE*)
        SPACE       <- " " / "\t" / "\n" / "\r"
        SELECTOR    <- (TAGNAME CLASS* ID? CLASS*) / (CLASS* ID CLASS*) / CLASS+
        RSELECTOR   <- (TAGNAME CLASS*) / CLASS+
        TAGNAME     <- ~([a-z]+ ("-"*[a-z0-9]+)*)
        ID          <- ~("#" [a-zA-Z]+ ("_"*[a-zA-Z0-9]+)*)
        CLASS       <- ~("." [a-zA-Z]+ ("-"*[a-zA-Z0-9]+)*)
        COUNT       <- ~([0-9]+)

        NEXTSEPARATOR   <- (SPACES? INLINENEXT) / FORMATTEDNEXT
        FORMATTEDNEXT   <- ","
        INLINENEXT      <- "~"
        WITHOUTWHITESPACES  <- "!"
        TEXTNODE        <- ~(STEXTNODE / DTEXTNODE)
        STEXTNODE       <- SQUOTE (!SQUOTE SCHAR)* SQUOTE
        DTEXTNODE       <- DQUOTE (!DQUOTE DCHAR)* DQUOTE
        SCHAR           <- (backslash SQUOTE) / (backslash backslash) / (backslash [tnr]) / .
        DCHAR           <- (backslash DQUOTE) / (backslash backslash) / (backslash [tnr]) / .
        SQUOTE          <- "'"
        DQUOTE          <- "\""
`));

class LineMLParseException : Exception {
    private const ParseTree _ptree;
    this(ParseTree ptree, string file = __FILE__, size_t line = __LINE__) @trusted {
        super("Parsing failure.\n" ~ ptree.toString(), file, line);
        this._ptree = ptree;
    }
    this(string mgs, ParseTree ptree, string file = __FILE__, size_t line = __LINE__) pure nothrow @safe {
        super(mgs, file, line);
        this._ptree = ptree;
    }
    @property const(ParseTree) parseTree() { return _ptree; }
}

/// Note, the class is NOT final!
class LineMLNode {
    private string _tagName, _id;
    private string[] _classes = [];
    private LineMLNode[] _children = [];
    private string _content;

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

    @property string textContent() @safe pure nothrow {
        return _content;
    }
    @property void textContent(string v) @safe pure nothrow {
        _content = v;
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
    LINE,
    SPACES_4
}

private string spaces4Indent = "    ";

unittest {
    import std.stdio;
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
    writeln("Test - selector #1: Ok.");
}

unittest {
    import std.stdio;
    import fluent.asserts;
    enum p = LineML("my-custom-tag");
    p.children.length.should.equal(1);
    p.children[0].name.should.endWith(".MARKUP");
    p.children[0].children.length.should.equal(1);
    p.children[0].children[0].name.should.endWith(".TAG");
    p.children[0].children[0].children.length.should.equal(1);
    p.children[0].children[0].children[0].name.should.endWith(".SELECTOR");
    p.children[0].children[0].children[0].children.length.should.equal(1);
    p.children[0].children[0].children[0].children[0].name.should.endWith(".TAGNAME");
    p.children[0].children[0].children[0].children[0].matches.length.should.equal(1);
    p.children[0].children[0].children[0].children[0].matches[0].should.equal("my-custom-tag");
    writeln("Test - selector #2: Ok.");
}

unittest {
    import std.stdio;
    import fluent.asserts;
    enum p = LineML("mycustomtag3434");
    p.children.length.should.equal(1);
    p.children[0].name.should.endWith(".MARKUP");
    p.children[0].children.length.should.equal(1);
    p.children[0].children[0].name.should.endWith(".TAG");
    p.children[0].children[0].children.length.should.equal(1);
    p.children[0].children[0].children[0].name.should.endWith(".SELECTOR");
    p.children[0].children[0].children[0].children.length.should.equal(1);
    p.children[0].children[0].children[0].children[0].name.should.endWith(".TAGNAME");
    p.children[0].children[0].children[0].children[0].matches.length.should.equal(1);
    p.children[0].children[0].children[0].children[0].matches[0].should.equal("mycustomtag3434");
    writeln("Test - selector #3: Ok.");
}

unittest {
    import std.stdio;
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
    writeln("Test - selector #4: Ok.");
}

unittest {
    import std.stdio;
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
    writeln("Test - selector #5: Ok.");
}

unittest {
    import std.stdio;
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
    writeln("Test - selector #6: Ok.");
}

unittest {
    import std.stdio;
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
    writeln("Test - selector #7: Ok.");
}

unittest {
    import std.stdio;

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

    writeln("Test - complex selectors: Ok.");
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    assert(!LineML("#z, #f, .item,  .item").successful); // multiple top-level tags - illegal
    enum p = LineML("sometag(#z, #f, .item,  .item)");
    p.successful.should.equal(true);

    p.children.length.should.equal(1);
    assert(p.children[0].name.endsWith(".MARKUP"));
    p.children[0].children.length.should.equal(1);
    assert(p.children[0].children[0].name.endsWith(".TAG"));
    enum topTagChildren = p.children[0].children[0].children;
    topTagChildren.length.should.equal(2); // Selector and Body.
    assert(topTagChildren[0].name.endsWith(".SELECTOR"));
    topTagChildren[0].children.length.should.equal(1);
    assert(topTagChildren[0].children[0].name.endsWith(".TAGNAME"));
    topTagChildren[0].children[0].matches.should.equal(["sometag"]);

    assert(topTagChildren[1].name.endsWith(".BODY"));
    topTagChildren[1].children.length.should.equal(1);
    enum anytags = topTagChildren[1].children[0];
    assert(anytags.name.endsWith(".ANYTAGS"));
    enum myTags = anytags.children;
    myTags.length.should.equal(10);

    assert(myTags[0].name.endsWith(".ANYTAG"));
    assert(myTags[1].name.endsWith(".NEXTSEPARATOR"));
    assert(myTags[2].name.endsWith(".SPACES"));
    assert(myTags[3].name.endsWith(".ANYTAG"));
    assert(myTags[4].name.endsWith(".NEXTSEPARATOR"));
    assert(myTags[5].name.endsWith(".SPACES"));
    assert(myTags[6].name.endsWith(".ANYTAG"));
    assert(myTags[7].name.endsWith(".NEXTSEPARATOR"));
    assert(myTags[8].name.endsWith(".SPACES"));
    assert(myTags[9].name.endsWith(".ANYTAG"));

    foreach(ref child; myTags[0].children[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            child.children.length.should.equal(1);
            assert(child.children[0].name.endsWith(".ID"));
            child.children[0].matches.should.equal(["#z"]);
        }
        1.should.equal(found);
    }

    foreach(ref child; myTags[3].children[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            child.children.length.should.equal(1);
            assert(child.children[0].name.endsWith(".ID"));
            child.children[0].matches.should.equal(["#f"]);
        }
        1.should.equal(found);
    }

    foreach(ref child; myTags[6].children[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            child.children.length.should.equal(1);
            assert(child.children[0].name.endsWith(".CLASS"));
            child.children[0].matches.should.equal([".item"]);
        }
        1.should.equal(found);
    }

    foreach(ref child; myTags[9].children[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            child.children.length.should.equal(1);
            assert(child.children[0].name.endsWith(".CLASS"));
            child.children[0].matches.should.equal([".item"]);
        }
        1.should.equal(found);
    }
    writeln("Test - inner tags: Ok.");
}

unittest {
    import std.stdio;
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
    writeln("Test - repeaters: Ok.");
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

private string unescapeTextNode(string raw) @safe {
    assert (raw.length >= 2);
    auto mainPart = raw[1..($-1)];
    dchar[] source = to!(dchar[])(mainPart);
    dchar[] result = [];

    for (int i = 0; i < source.length; i++) {
        if (source[i] != '\\') {
            result ~= source[i];
        } else if (source[i+1] == '\'' || source[i+1] == '"') {
            result ~= source[i+1];
            i++;
        } else if (source[i+1] == 't') {
            result ~= '\t';
            i++;
        } else if (source[i+1] == 'n') {
            result ~= '\n';
            i++;
        } else if (source[i+1] == 'r') {
            result ~= '\r';
            i++;
        } else {
            assert(0);
        }
    }

    return to!string(result);
}

private T createNodeFromSelector(T : LineMLNode)(ParseTree a) @safe {
    if (a.name.endsWith(".TAG")) {
        assert(a.children.length >= 1);
        assert(a.children[0].name.endsWith(".SELECTOR"));
        return selectorToNode!T(a.children[0]);
    } else if (a.name.endsWith(".REPEATER")) {
        assert(a.children.length >= 1);
        assert(a.children[0].name.endsWith(".RSELECTOR"));
        return selectorToNode!T(a.children[0]);
    } else if (a.name.endsWith(".TEXTNODE")) {
        auto r = new T();
        r.textContent = a.matches[0].unescapeTextNode;
        return r;
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
                } else if (t.name.endsWith(".REPEATER")) {
                    auto count = 1;
                    if (t.children.length >= 2) {
                        assert(t.children[1].name.endsWith(".COUNT"));
                        count = to!int(t.children[1].matches[0]);
                        if (count < 1) {
                            throw new LineMLParseException("Repeater must have the count >= 1.", t);
                        }
                        foreach (i; 0 .. count) {
                            result ~= t;
                        }
                    }
                } else if (t.name.endsWith(".TEXTNODE")) {
                    result ~= t;
                }
            }
        }
    }
    return result;
}

T lmlToNode(T : LineMLNode)(string markup) @trusted {
//    import std.stdio;
    auto t = lmlParse(markup);

    assert(t.children.length == 1);
    assert(t.children[0].name.endsWith(".MARKUP"));
    assert(t.children[0].children.length == 1);
    assert(t.children[0].children[0].name.endsWith(".TAG"));

    class StackItem {
        ParseTree tag;
        T result;
        int childIndex;

        this() {
        }

        this(ParseTree tag, T result, int childIndex) {
            this.tag = tag;
            this.result = result;
            this.childIndex = childIndex;
        }
    }

    StackItem[] stack = [];
    T result = null;

    // Our start point.
    stack ~= new StackItem(t.children[0].children[0], null, -1);

    while (stack.length > 0) {
        auto current = stack[$-1];
        auto chTags = childrenTags(current.tag);
        if (current.childIndex == -1) {
//            writeln("mode1: chTags.len = ", chTags.length);
            assert(current.result is null);
            current.result = createNodeFromSelector!T(current.tag);
            if (result is null) { // We are at the top-level.
                result = current.result;
            }
            if (chTags.length < 1) {
                stack.length--;
                if (stack.length > 0) {
                    assert(stack[$-1].childIndex != -1);
                    assert(stack[$-1].result !is null);
                    stack[$-1].result.children ~= current.result;
                    stack[$-1].childIndex++;
                }
            } else {
                current.childIndex = 0;
            }
        } else if (current.childIndex < chTags.length) {
//            writeln("mode2 ", current.childIndex);
            StackItem nextLevel = new StackItem();
            nextLevel.tag = chTags[current.childIndex];
            nextLevel.childIndex = -1;
            stack ~= nextLevel;
        } else {
//            writeln("mode3");
            stack.length--;
            if (stack.length > 0) {
                assert(stack[$-1].childIndex != -1);
                assert(stack[$-1].result !is null);
                stack[$-1].result.children ~= current.result;
                stack[$-1].childIndex++;
            }
        }
    }
    return result;
}

unittest {
    import std.stdio;
    auto input = "#d";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id == "d");
    assert(result.children.length == 0);
    assert(result.classes.length == 0);
    assert(result.tagName is null);
    writeln("Test - id selector has tagName==null: Ok.");
}

unittest {
    import std.stdio;
    auto input = ".d";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id is null);
    assert(result.children.length == 0);
    assert(result.classes.length == 1);
    assert(result.classes[0] == "d");
    assert(result.tagName is null);
    writeln("Test - class selector has tagName==null: Ok.");
}

unittest {
    import std.stdio;
    auto input = "d";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id is null);
    assert(result.children.length == 0);
    assert(result.classes.length == 0);
    assert(result.tagName == "d");
    writeln("Test - simple selector has non-null tagName: Ok.");
}

unittest {
    import std.stdio;
    auto input = ".foo.bar.zxcv";
    auto result = lmlToNode!LineMLNode(input);
    assert(result.id is null);
    assert(result.children.length == 0);
    assert(result.classes.length == 3);
    assert(result.classes.count("foo") > 0);
    assert(result.classes.count("bar") > 0);
    assert(result.classes.count("zxcv") > 0);
    assert(result.tagName is null);
    writeln("Test - complex selector with classes only has tagName==null: Ok.");
}

unittest {
    import std.stdio;
    auto input = "#d(#z, #f(.item, .item, .item, .item, .item))";
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
    writeln("Test - five items: Ok.");
}

unittest {
    import std.stdio;
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
    writeln("Test - five items, made with repeater: Ok.");
}

private class MyTestNode : LineMLNode {
    private string _f;

    @property string myField() @safe pure nothrow {
        return _f;
    }
    @property void myField(string v) @safe pure nothrow {
        _f = v;
    }
}

unittest {
    import std.stdio;
    auto input = "#d(#z, #f(.item:5))";
    auto result = lmlToNode!MyTestNode(input);

    assert((cast(MyTestNode) result) !is null);
    assert((cast(Exception) result) is null);

    assert(result.id == "d");
    assert(result.children.length == 2);

    (cast(MyTestNode) result.children[0]).myField = "123";
    assert("123" == (cast(MyTestNode) result.children[0]).myField);

    assert((cast(MyTestNode) (result.children[0])) !is null);
    assert(result.children[0].id == "z");
    assert(result.children[0].children.length == 0);

    assert((cast(MyTestNode) (result.children[1])) !is null);
    assert(result.children[1].id == "f");
    assert(result.children[1].children.length == 5);
    auto items = result.children[1].children;
    assert(items.length == 5);

    assert((cast(MyTestNode) (items[0])) !is null);
    assert(items[0].classes == ["item"]);
    assert((cast(MyTestNode) (items[1])) !is null);
    assert(items[1].classes == ["item"]);
    assert((cast(MyTestNode) (items[2])) !is null);
    assert(items[2].classes == ["item"]);
    assert((cast(MyTestNode) (items[3])) !is null);
    assert(items[3].classes == ["item"]);
    assert((cast(MyTestNode) (items[4])) !is null);
    assert(items[4].classes == ["item"]);

    (cast(MyTestNode) items[4]).myField = "Some text";
    assert("Some text" == (cast(MyTestNode) items[4]).myField);
    writeln("Test - using LineMLNode subclass: Ok.");
}

private string openTag(LineMLNode node) {

    if (node.textContent) {     // text node
        return node.textContent;
    }

    string result = "<";
    if (node.tagName is null) {
        result ~= "div";
    } else {
        result ~= node.tagName;
    }
    if (node.id !is null) {
        result ~= " id=\"" ~ node.id ~ "\"";
    }
    assert(node.classes !is null);
    if (node.classes.length > 0) {
        result ~= " class=\"";
        result ~= join(node.classes, " ");
        result ~= "\"";
    }
    result ~= ">";
    return result;
}

private string closeTag(LineMLNode node) {

    if (node.textContent) { // text node
        return "";
    }

    string result = "</";
    if (node.tagName is null) {
        result ~= "div";
    } else {
        result ~= node.tagName;
    }
    result ~= ">";
    return result;
}

private string parseTreeToHtml(LineMLNode rootNode, LmlHtmlFormat format) {
    string result = "";

    class HtmlStackItem {
        LineMLNode node;

        /++
         + Index of the child being processed right now.
         + (-1) means the initial state.
         + (-2) means the tag has no children.
         +/
        int childIndex = -1;

        this(LineMLNode n) {
            node = n;
        }
    }
    HtmlStackItem[] stack = [new HtmlStackItem(rootNode)];

    while (stack.length > 0) {
        auto current = stack[$-1];
        if (current.childIndex == -1) {
            if (format == LmlHtmlFormat.SPACES_4 &&
                    !(stack.length >= 2 && stack[$-2].node.children.length == 1 && stack[$-1].node.textContent)) {
                foreach (i; 0 .. (stack.length - 1)) {
                    result ~= spaces4Indent;
                }
            }
            result ~= openTag(current.node);
            if (stack[$-1].node.children.length > 0) {
                if (format == LmlHtmlFormat.SPACES_4 &&
                        !(stack[$-1].node.children.length == 1 && stack[$-1].node.children[0].textContent)) {
                    result ~= "\n";
                }
                stack[$-1].childIndex++;
            } else {
                stack[$-1].childIndex = -2;
            }
        } else if (current.childIndex <= -2) {
            if (format == LmlHtmlFormat.SPACES_4 && current.childIndex == -3 &&
                    !(stack[$-1].node.children.length == 1 && stack[$-1].node.children[0].textContent)) {
                foreach (i; 0 .. (stack.length - 1)) {
                    result ~= spaces4Indent;
                }
            }
            result ~= closeTag(current.node);
            if (format == LmlHtmlFormat.SPACES_4 &&
                    !(stack.length >= 2 && stack[$-2].node.children.length == 1 && stack[$-1].node.textContent)) {
                result ~= "\n";
            }
            stack.length--;
            if (stack.length > 0) {
                assert(stack[$-1].childIndex != -1);
                assert(stack[$-1].childIndex != -2);
                stack[$-1].childIndex++;
                if (stack[$-1].childIndex >= stack[$-1].node.children.length) {
                    stack[$-1].childIndex = -3;
                }
            }
        } else {
            stack ~= new HtmlStackItem(stack[$-1].node.children[stack[$-1].childIndex]);
        }
    }
    return result;
}

auto lmlToHtml(string markup, LmlHtmlFormat format) {
    LineMLNode tree = lmlToNode!LineMLNode(markup);
    return parseTreeToHtml(tree, format);
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    auto input = "#d(#z, #f(.item, .item, .item, .item, .item))";
    auto expected = "<div id=\"d\"><div id=\"z\"></div><div id=\"f\">" ~
            "<div class=\"item\"></div><div class=\"item\"></div>" ~
            "<div class=\"item\"></div><div class=\"item\"></div>" ~
            "<div class=\"item\"></div></div></div>";
    expected.should.equal(lmlToHtml(input, LmlHtmlFormat.LINE));
    writeln("Test - convertion to XML (single line): Ok.");
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    auto input = "#d(#z, #f(.item, .item, .item, .item, .item))";
    auto expected = "" ~
            "<div id=\"d\">\n" ~
            "    <div id=\"z\"></div>\n" ~
            "    <div id=\"f\">\n" ~
            "        <div class=\"item\"></div>\n" ~
            "        <div class=\"item\"></div>\n" ~
            "        <div class=\"item\"></div>\n" ~
            "        <div class=\"item\"></div>\n" ~
            "        <div class=\"item\"></div>\n" ~
            "    </div>\n" ~
            "</div>\n";
    expected.should.equal(lmlToHtml(input, LmlHtmlFormat.SPACES_4));
    writeln("Test - convertion to XML (indented with 4 spaces): Ok.");
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    LineML("foo").successful.should.equal(true);
    LineML("'foo'").successful.should.equal(false);
    LineML("foo('bar')").successful.should.equal(true);
    LineML("foo(\"bar\")").successful.should.equal(true);
    LineML("foo('ba'r')").successful.should.equal(false);
    LineML("foo(\"ba\"r\")").successful.should.equal(false);
    LineML("foo('ba\"r')").successful.should.equal(true);
    LineML("foo(\"ba'r\")").successful.should.equal(true);
    LineML("foo('b\"a\"r')").successful.should.equal(true);
    LineML("foo(\"b'a'r\")").successful.should.equal(true);
    LineML("foo('\"ba\"r')").successful.should.equal(true);
    LineML("foo(\"'ba'r\")").successful.should.equal(true);
    LineML("foo('\"bar\"')").successful.should.equal(true);
    LineML("foo(\"'bar'\")").successful.should.equal(true);
    LineML("foo('b\"ar\"')").successful.should.equal(true);
    LineML("foo(\"b'ar'\")").successful.should.equal(true);

    LineML("foo(\"valid \\\"text\\\" element\")").successful.should.equal(true);
    LineML("foo(\"invalid \"text\" element\")").successful.should.equal(false);
    LineML("foo('valid \\'text\\' element')").successful.should.equal(true);
    LineML("foo('invalid 'text' element')").successful.should.equal(false);

    LineML("foo(\"\\\"valid\\\" text element\")").successful.should.equal(true);
    LineML("foo(\"\"invalid\" text element\")").successful.should.equal(false);
    LineML("foo('\\'valid\\' text element')").successful.should.equal(true);
    LineML("foo(''invalid' text element')").successful.should.equal(false);

    LineML("foo(\"valid text \\\"element\\\"\")").successful.should.equal(true);
    LineML("foo(\"invalid text \"element\"\")").successful.should.equal(false);
    LineML("foo('valid text \\'element\\'')").successful.should.equal(true);
    LineML("foo('invalid text 'element'')").successful.should.equal(false);

    LineML("#d(#z, #f(.item,.item))").successful.should.equal(true);
    LineML("#d(#z, .f:2(.item,.item))").successful.should.equal(true);
    LineML("#d(#z, #f(.item, .item))").successful.should.equal(true);
    LineML("#d(#z, .f:2(.item, .item))").successful.should.equal(true);
    LineML("#d(#z, #f(.item~.item))").successful.should.equal(true);
    LineML("#d(#z, .f:2(.item~.item))").successful.should.equal(true);
    LineML("#d(#z, #f(.item~ .item))").successful.should.equal(true);
    LineML("#d(#z, .f:2(.item~ .item))").successful.should.equal(true);
    LineML("#d(#z, #f(.item ~ .item))").successful.should.equal(true);
    LineML("#d(#z, .f:2(.item ~ .item))").successful.should.equal(true);
    LineML("#d(#z, #f(.item , .item))").successful.should.equal(false);
    LineML("#d(#z, .f:2(.item , .item))").successful.should.equal(false);

    LineML("#d(#z, #f(     .item,   .item  ))").successful.should.equal(true);
    LineML("#d(#z, .f:2(   .item,    .item   ))").successful.should.equal(true);
    LineML("#d(#z, #f(     .item   ~    .item   ))").successful.should.equal(true);
    LineML("#d(#z, .f:2(   .item    ~   .item   ))").successful.should.equal(true);
    LineML("#d(#z, #f(  \n   .item, \n  .item  \n  ))").successful.should.equal(true);
    LineML("#d(#z, .f:2( \n  .item, \n   .item \n  ))").successful.should.equal(true);
    LineML("#d(#z, #f(  \n   .item  \n   ~  \n  .item \n  ))").successful.should.equal(true);
    LineML("#d(#z, .f:2( \n  .item  \n  ~ \n  .item \n  ))").successful.should.equal(true);

    LineML("#d(#z, #f(!.item, .item))").successful.should.equal(true);
    LineML("#d(#z, .f:2(!.item, .item))").successful.should.equal(true);
    LineML("#d(#z, #f(.item, .item!))").successful.should.equal(true);
    LineML("#d(#z, .f:2(.item, .item!))").successful.should.equal(true);
    LineML("#d(#z, #f(!.item, .item!))").successful.should.equal(true);
    LineML("#d(#z, .f:2(!.item, .item!))").successful.should.equal(true);

    LineML("#d(#z, #f(!    .item,  .item   ))").successful.should.equal(true);
    LineML("#d(#z, .f:2(!  .item,  .item   ))").successful.should.equal(true);
    LineML("#d(#z, #f(     .item,  .item  !))").successful.should.equal(true);
    LineML("#d(#z, .f:2(   .item,  .item  !))").successful.should.equal(true);
    LineML("#d(#z, #f(!    .item,  .item  !))").successful.should.equal(true);
    LineML("#d(#z, .f:2(!  .item,  .item  !))").successful.should.equal(true);

    LineML("#d(#z, #f( !   .item,  .item   ))").successful.should.equal(false);
    LineML("#d(#z, .f:2( ! .item,  .item   ))").successful.should.equal(false);
    LineML("#d(#z, #f(     .item,  .item ! ))").successful.should.equal(false);
    LineML("#d(#z, .f:2(   .item,  .item ! ))").successful.should.equal(false);
    LineML("#d(#z, #f(!    .item,  .item ! ))").successful.should.equal(false);
    LineML("#d(#z, .f:2(!  .item,  .item ! ))").successful.should.equal(false);
    LineML("#d(#z, #f( !   .item,  .item ! ))").successful.should.equal(false);
    LineML("#d(#z, .f:2( ! .item,  .item ! ))").successful.should.equal(false);
    writeln("Test - parsing the text nodes: Ok.");
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    auto input = ".container(.row(.col-lg-12('Привет.', ul(li:2), 'Привееет!')))";
    auto expected = "" ~
            "<div class=\"container\">\n" ~
            "    <div class=\"row\">\n" ~
            "        <div class=\"col-lg-12\">\n" ~
            "            Привет.\n" ~
            "            <ul>\n" ~
            "                <li></li>\n" ~
            "                <li></li>\n" ~
            "            </ul>\n" ~
            "            Привееет!\n" ~
            "        </div>\n" ~
            "    </div>\n" ~
            "</div>\n";
    auto actual = lmlToHtml(input, LmlHtmlFormat.SPACES_4);
    actual.should.equal(expected);
    writeln("Test - hello-ul-hello: Ok.");
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    auto input = ".container(a(span('Привет.'), span('Привееет!')))"; // Single text node is automatically inlined.
    auto expected = "" ~
            "<div class=\"container\">\n" ~
            "    <a>\n" ~
            "        <span>Привет.</span>\n" ~
            "        <span>Привееет!</span>\n" ~
            "    </a>\n" ~
            "</div>\n";
    auto actual = lmlToHtml(input, LmlHtmlFormat.SPACES_4);
    actual.should.equal(expected);
    writeln("Test - the only child text node has no whitespace on its sides (single quote): Ok.");
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    auto input = ".container(a(span(\"Привет.\"), span(\"Привееет!\")))";
    auto expected = "" ~
            "<div class=\"container\">\n" ~
            "    <a>\n" ~
            "        <span>Привет.</span>\n" ~
            "        <span>Привееет!</span>\n" ~
            "    </a>\n" ~
            "</div>\n";
    auto actual = lmlToHtml(input, LmlHtmlFormat.SPACES_4);
    actual.should.equal(expected);
    writeln("Test - the only child text node has no whitespace on its sides: Ok.");
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    auto input = ".container(a(span('Привет.\"), span(\"Привееет!')))"; // Bad quotes.
    auto expected = "" ~
            "<div class=\"container\">\n" ~
            "    <a>\n" ~
            "        <span>Привет.\"), span(\"Привееет!</span>\n" ~
            "    </a>\n" ~
            "</div>\n";
    auto actual = lmlToHtml(input, LmlHtmlFormat.SPACES_4);
    actual.should.equal(expected);
    writeln("Test - bad quotes example #1: Ok.");
}

unittest {
    import std.stdio;
    import fluentasserts.core.base;
    auto input = ".container(a(span(\"Привет.'), span('Привееет!\")))"; // Bad quotes.
    auto expected = "" ~
            "<div class=\"container\">\n" ~
            "    <a>\n" ~
            "        <span>Привет.'), span('Привееет!</span>\n" ~
            "    </a>\n" ~
            "</div>\n";
    auto actual = lmlToHtml(input, LmlHtmlFormat.SPACES_4);
    actual.should.equal(expected);
    writeln("Test - bad quotes example #2: Ok.");
}
