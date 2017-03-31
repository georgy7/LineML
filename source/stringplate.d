module stringplate;

import pegged.grammar;

mixin(grammar(`
    Stringplate:
        TAGS        <- (SPACES? TAG "," SPACES?)* TAG SPACES?
        TAG         <- SELECTOR BODY?
        BODY        <- "(" TAGS ")"
        SPACES      <- ~(SPACE*)
        SPACE       <- " " / "\t" / "\n" / "\r"
        SELECTOR    <- (TAGNAME ID CLASS*) / (TAGNAME CLASS* ID) / (CLASS* ID) / (CLASS* ID) / CLASS*
        TAGNAME     <- ~([a-z]+)
        ID          <- ~("#" [a-z]+)
        CLASS       <- ~("." [a-z]+)
`));


unittest {
    import std.algorithm.searching;

    enum p = Stringplate("#z, #f, .item,  .item");
    assert(p.children[0].name.endsWith(".TAGS"));
    assert(p.children.length == 1);

    enum tc = p.children[0].children;
    assert(tc.length == 7);

    assert(tc[0].name.endsWith(".TAG"));
    assert(tc[1].name.endsWith(".SPACES"));
    assert(tc[2].name.endsWith(".TAG"));
    assert(tc[3].name.endsWith(".SPACES"));
    assert(tc[4].name.endsWith(".TAG"));
    assert(tc[5].name.endsWith(".SPACES"));
    assert(tc[6].name.endsWith(".TAG"));

    foreach(ref child; tc[0].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            assert(child.children.length == 1);
            assert(child.children[0].name.endsWith(".ID"));
            assert(child.children[0].matches == ["#z"]);
        }
        assert(1 == found);
    }

    foreach(ref child; tc[2].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            assert(child.children.length == 1);
            assert(child.children[0].name.endsWith(".ID"));
            assert(child.children[0].matches == ["#f"]);
        }
        assert(1 == found);
    }

    foreach(ref child; tc[4].children) {
        int found = 0;
        if (child.name.endsWith(".SELECTOR")) {
            found++;
            assert(child.children.length == 1);
            assert(child.children[0].name.endsWith(".CLASS"));
            assert(child.children[0].matches == [".item"]);
        }
        assert(1 == found);
    }

    foreach(ref child; tc[6].children) {
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
    import std.stdio;
    //enum p = Stringplate(" #d(#z, #f(.item, .item, .item, .item, .item))");
    enum p = Stringplate("   #z, #f, .item, .item  ");
    foreach(ref child; p.children) {
        writeln(child);
    }
}

