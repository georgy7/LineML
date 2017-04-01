module lineml;

import pegged.grammar;

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


unittest {
    import std.algorithm.searching;
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
    import std.algorithm.searching;
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
    import std.algorithm.searching;
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
    import std.algorithm.searching;
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
    import std.algorithm.searching;
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
    import std.algorithm.searching;

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

/*
unittest {
    import std.stdio;
    //enum p = Stringplate(" #d(#z, #f(.item, .item, .item, .item, .item))");
    enum p = LineML("   #z, #f, .item, .item  ");
    foreach(ref child; p.children) {
        writeln(child);
    }
}
*/
